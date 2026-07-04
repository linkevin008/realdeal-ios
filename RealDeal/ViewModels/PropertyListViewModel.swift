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
    @Published var error: AppError?
    @Published var successMessage: String?
    
    // Loading state management
    @Published var loadingStateManager = LoadingStateManager()
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
        await loadingStateManager.withLoading(
            operation: LoadingStateManager.Operation.fetchProperties,
            message: "Loading properties..."
        ) {
            isLoading = true
            errorMessage = nil
            error = nil
            successMessage = nil
            currentPage = 0
            hasMorePages = true
            
            do {
                // Filters (including search text) go to the backend — the
                // lookup service queries server-side; FilterService re-applies
                // locally for the cache/mock paths
                let allProperties = try await repository.fetchProperties(filters: filters)
                
                // Filter to only show active listings for buyers
                let activeProperties = allProperties.filter { $0.status == .active }
                
                // Apply filters
                let filteredProperties = try filterService.applyFilters(activeProperties, filters: filters)
                
                // Apply pagination
                properties = Array(filteredProperties.prefix(pageSize))
                hasMorePages = filteredProperties.count > pageSize
                
                // Load favorite status
                await loadFavoriteStatus()
                
            } catch let appError as AppError {
                self.error = appError
                errorMessage = appError.userMessage
                properties = []
            } catch let caughtError {
                let appError = AppError.unknown(caughtError.localizedDescription)
                self.error = appError
                errorMessage = appError.userMessage
                properties = []
            }
            
            isLoading = false
        }
    }
    
    /// Retry loading properties
    func retryLoadProperties() async {
        await loadProperties()
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
        
        await loadingStateManager.withLoading(
            operation: favoritePropertyIds.contains(propertyId) ? 
                LoadingStateManager.Operation.removeFavorite : 
                LoadingStateManager.Operation.addFavorite,
            message: favoritePropertyIds.contains(propertyId) ? 
                "Removing from favorites..." : 
                "Adding to favorites..."
        ) {
            do {
                if favoritePropertyIds.contains(propertyId) {
                    // Remove from favorites
                    let favorites = try await favoritesRepository.fetchFavorites(userId: userId)
                    if let favorite = favorites.first(where: { $0.propertyId == propertyId }) {
                        try await favoritesRepository.removeFavorite(id: favorite.id)
                        favoritePropertyIds.remove(propertyId)
                        successMessage = "Removed from favorites"
                    }
                } else {
                    // Add to favorites
                    let favorite = Favorite(userId: userId, propertyId: propertyId)
                    try await favoritesRepository.addFavorite(favorite)
                    favoritePropertyIds.insert(propertyId)
                    successMessage = "Added to favorites"
                }
            } catch {
                errorMessage = "Failed to update favorite status."
            }
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
            // Same server-side filtering as loadProperties
            let allProperties = try await repository.fetchProperties(filters: filters)

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

    // MARK: - Search

    /// True when a text search is currently applied.
    var hasActiveSearch: Bool {
        filters.searchText?.isEmpty == false
    }

    /// Applies a free-text search (queried server-side by the lookup service)
    /// and reloads. An empty query clears the search.
    func applySearch(_ query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        filters.searchText = trimmed.isEmpty ? nil : trimmed
        await loadProperties()
    }

    /// Clears the text search and reloads.
    func clearSearch() async {
        await applySearch("")
    }
}
