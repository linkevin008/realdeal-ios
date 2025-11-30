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
    
    // MARK: - Properties
    
    private let repository: PropertyRepositoryProtocol
    private let filterService: FilterService
    private var currentPage: Int = 0
    private let pageSize: Int = 20
    private var hasMorePages: Bool = true
    
    // MARK: - Initialization
    
    init(
        repository: PropertyRepositoryProtocol,
        filterService: FilterService = FilterService()
    ) {
        self.repository = repository
        self.filterService = filterService
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
            
        } catch let error as AppError {
            errorMessage = error.userMessage
            properties = []
        } catch {
            errorMessage = "Failed to load properties. Please try again."
            properties = []
        }
        
        isLoading = false
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
