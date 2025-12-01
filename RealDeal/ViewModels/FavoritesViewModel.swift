import Foundation
import Combine

/// ViewModel for managing favorites functionality
@MainActor
@available(iOS 15.0, macOS 12.0, *)
class FavoritesViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var favorites: [Favorite] = []
    @Published var favoriteProperties: [Property] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var favoritePropertyIds: Set<String> = []
    
    // MARK: - Properties
    
    private let favoritesRepository: FavoritesRepositoryProtocol
    private let propertyRepository: PropertyRepositoryProtocol
    private let currentUserId: String
    
    // MARK: - Initialization
    
    init(
        favoritesRepository: FavoritesRepositoryProtocol,
        propertyRepository: PropertyRepositoryProtocol,
        currentUserId: String
    ) {
        self.favoritesRepository = favoritesRepository
        self.propertyRepository = propertyRepository
        self.currentUserId = currentUserId
    }
    
    // MARK: - Actions
    
    /// Load all favorites for the current user
    func loadFavorites() async {
        isLoading = true
        errorMessage = nil
        
        do {
            favorites = try await favoritesRepository.fetchFavorites(userId: currentUserId)
            
            // Update the set of favorite property IDs for quick lookup
            favoritePropertyIds = Set(favorites.map { $0.propertyId })
            
            // Load the actual property details for each favorite
            await loadFavoriteProperties()
            
        } catch let error as AppError {
            errorMessage = error.userMessage
            favorites = []
            favoriteProperties = []
            favoritePropertyIds = []
        } catch {
            errorMessage = "Failed to load favorites. Please try again."
            favorites = []
            favoriteProperties = []
            favoritePropertyIds = []
        }
        
        isLoading = false
    }
    
    /// Load property details for all favorites
    private func loadFavoriteProperties() async {
        var properties: [Property] = []
        
        for favorite in favorites {
            do {
                if let property = try await propertyRepository.getProperty(id: favorite.propertyId) {
                    // Only include active properties (exclude deleted/sold)
                    if property.status == .active {
                        properties.append(property)
                    }
                }
            } catch {
                // Skip properties that can't be loaded
                continue
            }
        }
        
        // Sort by saved date (most recent first)
        favoriteProperties = properties.sorted { property1, property2 in
            guard let favorite1 = favorites.first(where: { $0.propertyId == property1.id }),
                  let favorite2 = favorites.first(where: { $0.propertyId == property2.id }) else {
                return false
            }
            return favorite1.savedAt > favorite2.savedAt
        }
    }
    
    /// Add a property to favorites
    func addFavorite(propertyId: String) async {
        do {
            let favorite = Favorite(
                userId: currentUserId,
                propertyId: propertyId
            )
            
            try await favoritesRepository.addFavorite(favorite)
            
            // Update local state
            favorites.append(favorite)
            favoritePropertyIds.insert(propertyId)
            
            // Reload to get the property details
            await loadFavorites()
            
        } catch let error as AppError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = "Failed to add favorite. Please try again."
        }
    }
    
    /// Remove a property from favorites
    func removeFavorite(propertyId: String) async {
        guard let favorite = favorites.first(where: { $0.propertyId == propertyId }) else {
            return
        }
        
        do {
            try await favoritesRepository.removeFavorite(id: favorite.id)
            
            // Update local state
            favorites.removeAll { $0.id == favorite.id }
            favoritePropertyIds.remove(propertyId)
            favoriteProperties.removeAll { $0.id == propertyId }
            
        } catch let error as AppError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = "Failed to remove favorite. Please try again."
        }
    }
    
    /// Toggle favorite status for a property
    func toggleFavorite(propertyId: String) async {
        if isFavorite(propertyId: propertyId) {
            await removeFavorite(propertyId: propertyId)
        } else {
            await addFavorite(propertyId: propertyId)
        }
    }
    
    /// Check if a property is favorited
    func isFavorite(propertyId: String) -> Bool {
        favoritePropertyIds.contains(propertyId)
    }
    
    /// Refresh favorites list
    func refreshFavorites() async {
        await loadFavorites()
    }
}
