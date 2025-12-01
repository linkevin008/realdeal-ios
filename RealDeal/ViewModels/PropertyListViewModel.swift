import Foundation
import Combine
import CoreLocation

/// ViewModel for browsing and searching property listings with filtering
@MainActor
@available(iOS 15.0, macOS 12.0, *)
class PropertyListViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var properties: [Property] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var filters: PropertyFilters = PropertyFilters()
    @Published var favoritePropertyIds: Set<String> = []
    
    // MARK: - Properties
    
    private let repository: PropertyRepositoryProtocol
    private let filterService: FilterService
    private let favoritesRepository: FavoritesRepositoryProtocol?
    private let currentUserId: String?
    private var currentPage: Int = 0
    private let pageSize: Int = 20
    private var hasMorePages: Bool = true
    
    // MARK: - Initialization
    
    init(
        repository: PropertyRepositoryProtocol,
        filterService: FilterService = FilterService(),
        favoritesRepository: FavoritesRepositoryProtocol? = nil,
        currentUserId: String? = nil
    ) {
        self.repository = repository
        self.filterService = filterService
        self.favoritesRepository = favoritesRepository
        self.currentUserId = currentUserId
    }
    
    // MARK: - Actions
    
    /// Load properties with current filters
    func loadProperties() async {
        isLoading = true
        errorMessage = nil
        currentPage = 0
        hasMorePages = true
        
        do {
            // Fetch all properties (filtering happens client-side for now)
            let allProperties = try await repository.fetchProperties(filters: nil)
            
            // Filter to only show active listings for buyers
            let activeProperties = allProperties.filter { $0.status == .active }
            
            // Apply filters
            let filteredProperties = try filterService.applyFilters(activeProperties, filters: filters)
            
            // Apply pagination
            properties = Array(filteredProperties.prefix(pageSize))
            hasMorePages = filteredProperties.count > pageSize
            
            // Load favorite status
            await loadFavoriteStatus()
            
        } catch let error as AppError {
            errorMessage = error.userMessage
            properties = []
        } catch {
            errorMessage = "Failed to load properties. Please try again."
            properties = []
        }
        
        isLoading = false
    }
    
    /// Load favorite status for current user
    private func loadFavoriteStatus() async {
        guard let favoritesRepository = favoritesRepository,
              let userId = currentUserId else {
            return
        }
        
        do {
            let favorites = try await favoritesRepository.fetchFavorites(userId: userId)
            favoritePropertyIds = Set(favorites.map { $0.propertyId })
        } catch {
            // Silently fail - not critical
            favoritePropertyIds = []
        }
    }
    
    /// Toggle favorite status for a property
    func toggleFavorite(propertyId: String) async {
        guard let favoritesRepository = favoritesRepository,
              let userId = currentUserId else {
            return
        }
        
        do {
            if favoritePropertyIds.contains(propertyId) {
                // Remove from favorites
                let favorites = try await favoritesRepository.fetchFavorites(userId: userId)
                if let favorite = favorites.first(where: { $0.propertyId == propertyId }) {
                    try await favoritesRepository.removeFavorite(id: favorite.id)
                    favoritePropertyIds.remove(propertyId)
                }
            } else {
                // Add to favorites
                let favorite = Favorite(userId: userId, propertyId: propertyId)
                try await favoritesRepository.addFavorite(favorite)
                favoritePropertyIds.insert(propertyId)
            }
        } catch {
            // Silently fail or show error
            errorMessage = "Failed to update favorite status."
        }
    }
    
    /// Check if a property is favorited
    func isFavorite(propertyId: String) -> Bool {
        favoritePropertyIds.contains(propertyId)
    }
    
    /// Refresh properties (pull-to-refresh)
    func refreshProperties() async {
        await loadProperties()
    }
    
    /// Load more properties (pagination)
    func loadMoreProperties() async {
        guard !isLoading && hasMorePages else { return }
        
        isLoading = true
        currentPage += 1
        
        do {
            // Fetch all properties
            let allProperties = try await repository.fetchProperties(filters: nil)
            
            // Filter to only show active listings
            let activeProperties = allProperties.filter { $0.status == .active }
            
            // Apply filters
            let filteredProperties = try filterService.applyFilters(activeProperties, filters: filters)
            
            // Calculate pagination
            let startIndex = currentPage * pageSize
            let endIndex = min(startIndex + pageSize, filteredProperties.count)
            
            if startIndex < filteredProperties.count {
                let newProperties = Array(filteredProperties[startIndex..<endIndex])
                properties.append(contentsOf: newProperties)
                hasMorePages = endIndex < filteredProperties.count
            } else {
                hasMorePages = false
            }
            
        } catch {
            // On error, just stop loading more
            hasMorePages = false
        }
        
        isLoading = false
    }
    
    /// Apply filters and reload properties
    func applyFilters() async {
        await loadProperties()
    }
    
    /// Clear all filters
    func clearFilters() async {
        filters = PropertyFilters()
        await loadProperties()
    }
    
    // MARK: - Filter Helpers
    
    /// Update price range filter
    func updatePriceRange(min: Decimal?, max: Decimal?) {
        filters.priceMin = min
        filters.priceMax = max
    }
    
    /// Update property types filter
    func updatePropertyTypes(_ types: Set<PropertyType>) {
        filters.propertyTypes = types.isEmpty ? nil : types
    }
    
    /// Update location radius filter
    func updateLocationRadius(center: Coordinate?, radiusInMiles: Double?) {
        if let center = center, let radius = radiusInMiles {
            filters.locationRadius = LocationRadius(center: center, radiusInMiles: radius)
        } else {
            filters.locationRadius = nil
        }
    }
    
    /// Check if any filters are active
    var hasActiveFilters: Bool {
        filters.priceMin != nil ||
        filters.priceMax != nil ||
        filters.propertyTypes != nil ||
        filters.locationRadius != nil ||
        filters.minBedrooms != nil ||
        filters.minBathrooms != nil
    }
}
