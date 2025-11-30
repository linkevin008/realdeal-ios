import Foundation

/// Mock implementation of PropertyRepositoryProtocol for testing and development
@available(iOS 15.0, macOS 12.0, *)
class MockPropertyRepository: PropertyRepositoryProtocol {
    // MARK: - Storage
    private var properties: [String: Property] = [:]
    
    // MARK: - Configuration
    private let simulateNetworkDelay: Bool
    private let networkDelayRange: ClosedRange<TimeInterval>
    
    init(
        simulateNetworkDelay: Bool = false,
        networkDelayRange: ClosedRange<TimeInterval> = 0.1...0.5
    ) {
        self.simulateNetworkDelay = simulateNetworkDelay
        self.networkDelayRange = networkDelayRange
    }
    
    // MARK: - Private Helpers
    
    private func simulateDelay() async {
        guard simulateNetworkDelay else { return }
        let delay = TimeInterval.random(in: networkDelayRange)
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
    }
    
    // MARK: - PropertyRepositoryProtocol
    
    func fetchProperties(filters: PropertyFilters?) async throws -> [Property] {
        await simulateDelay()
        
        var results = Array(properties.values)
        
        // Apply filters if provided
        if let filters = filters {
            results = applyFilters(to: results, filters: filters)
        }
        
        // Sort by creation date (newest first)
        return results.sorted { $0.createdAt > $1.createdAt }
    }
    
    func createProperty(_ property: Property) async throws -> Property {
        await simulateDelay()
        
        // Store property
        properties[property.id] = property
        
        return property
    }
    
    func updateProperty(_ property: Property) async throws {
        await simulateDelay()
        
        guard properties[property.id] != nil else {
            throw AppError.notFound
        }
        
        properties[property.id] = property
    }
    
    func deleteProperty(id: String) async throws {
        await simulateDelay()
        
        guard properties[id] != nil else {
            throw AppError.notFound
        }
        
        properties.removeValue(forKey: id)
    }
    
    func getProperty(id: String) async throws -> Property? {
        await simulateDelay()
        
        return properties[id]
    }
    
    // MARK: - Filter Application
    
    private func applyFilters(to properties: [Property], filters: PropertyFilters) -> [Property] {
        var filtered = properties
        
        // Price range filter
        if let priceMin = filters.priceMin {
            filtered = filtered.filter { property in
                property.price >= priceMin
            }
        }
        
        if let priceMax = filters.priceMax {
            filtered = filtered.filter { property in
                property.price <= priceMax
            }
        }
        
        // Property type filter
        if let types = filters.propertyTypes, !types.isEmpty {
            filtered = filtered.filter { property in
                types.contains(property.propertyType)
            }
        }
        
        // Location radius filter
        if let locationRadius = filters.locationRadius {
            filtered = filtered.filter { property in
                let distance = calculateDistance(
                    from: locationRadius.center,
                    to: property.location
                )
                return distance <= locationRadius.radiusInMiles
            }
        }
        
        // Bedrooms filter
        if let minBedrooms = filters.minBedrooms {
            filtered = filtered.filter { property in
                guard let bedrooms = property.specifications.bedrooms else { return false }
                return bedrooms >= minBedrooms
            }
        }
        
        // Bathrooms filter
        if let minBathrooms = filters.minBathrooms {
            filtered = filtered.filter { property in
                guard let bathrooms = property.specifications.bathrooms else { return false }
                return bathrooms >= minBathrooms
            }
        }
        
        // Source filter
        if let sources = filters.sources, !sources.isEmpty {
            filtered = filtered.filter { property in
                sources.contains(property.source)
            }
        }
        
        return filtered
    }
    
    private func calculateDistance(from: Coordinate, to: Coordinate) -> Double {
        // Haversine formula for calculating distance between two coordinates
        let earthRadius = 3959.0 // miles
        
        let lat1 = from.latitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let deltaLat = (to.latitude - from.latitude) * .pi / 180
        let deltaLon = (to.longitude - from.longitude) * .pi / 180
        
        let a = sin(deltaLat / 2) * sin(deltaLat / 2) +
                cos(lat1) * cos(lat2) *
                sin(deltaLon / 2) * sin(deltaLon / 2)
        
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        
        return earthRadius * c
    }
    
    // MARK: - Test Helpers
    
    /// Add a property directly (for testing)
    func addProperty(_ property: Property) {
        properties[property.id] = property
    }
    
    /// Get all properties (for testing)
    func getAllProperties() -> [Property] {
        Array(properties.values)
    }
    
    /// Clear all properties
    func clearAll() {
        properties.removeAll()
    }
    
    /// Get count of stored properties (for testing)
    func getPropertyCount() -> Int {
        properties.count
    }
}
