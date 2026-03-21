import Foundation
import MapKit
import Combine

/// ViewModel managing map state and property annotations
@available(iOS 15.0, macOS 12.0, *)
@MainActor
class MapViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var annotations: [PropertyAnnotation] = []
    @Published var selectedProperty: Property?
    @Published var region: MKCoordinateRegion
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var filters: PropertyFilters = PropertyFilters()
    
    // MARK: - Properties
    
    let repository: PropertyRepositoryProtocol
    private let filterService: FilterService
    private let locationManager: LocationManager
    private var cancellables = Set<AnyCancellable>()
    
    // Default region (Vancouver, BC)
    private static let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 49.2827, longitude: -123.1207),
        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
    )
    
    // MARK: - Initialization
    
    init(
        repository: PropertyRepositoryProtocol,
        filterService: FilterService = FilterService(),
        locationManager: LocationManager
    ) {
        self.repository = repository
        self.filterService = filterService
        self.locationManager = locationManager
        self.region = Self.defaultRegion
        
        setupLocationObserver()
    }
    
    // MARK: - Setup
    
    private func setupLocationObserver() {
        // Observe location changes and center map on user location
        locationManager.$currentLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                self?.centerOnUserLocation(location)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Load properties and create annotations
    func loadProperties() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch all properties
            let allProperties = try await repository.fetchProperties(filters: nil)
            
            // Filter to only show active listings
            let activeProperties = allProperties.filter { $0.status == .active }
            
            // Apply filters
            let filteredProperties = try filterService.applyFilters(activeProperties, filters: filters)
            
            // Create annotations
            annotations = filteredProperties.map { PropertyAnnotation(property: $0) }
            
        } catch let error as AppError {
            errorMessage = error.userMessage
            annotations = []
        } catch {
            errorMessage = "Failed to load properties. Please try again."
            annotations = []
        }
        
        isLoading = false
    }
    
    /// Update annotations based on visible map region
    func updateVisibleAnnotations(for visibleRegion: MKCoordinateRegion) async {
        // For now, we load all properties and let MapKit handle clustering
        // In a production app, you'd fetch only properties in the visible region
        if annotations.isEmpty {
            await loadProperties()
        }
    }
    
    /// Center map on user's current location
    func centerOnUserLocation() {
        guard let location = locationManager.currentLocation else {
            // Request location if not available
            locationManager.requestLocationPermission()
            return
        }
        
        centerOnUserLocation(location)
    }
    
    private func centerOnUserLocation(_ location: CLLocation) {
        region = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    }
    
    /// Select a property annotation
    func selectProperty(_ property: Property) {
        selectedProperty = property
    }
    
    /// Deselect the current property
    func deselectProperty() {
        selectedProperty = nil
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
    
    /// Get clustering identifier for annotations
    static let clusteringIdentifier = "propertyCluster"
}
