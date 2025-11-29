import Foundation

/// Mock implementation of RemoteDataSourceProtocol for testing and development
/// Stores data in memory and simulates network delays
@available(iOS 15.0, macOS 12.0, *)
class MockRemoteDataSource: RemoteDataSourceProtocol {
    // MARK: - Storage
    private var properties: [String: Property] = [:]
    private var userProfiles: [String: UserProfile] = [:]
    private var favorites: [String: Favorite] = [:]
    private var images: [URL: Data] = [:]
    
    // MARK: - Configuration
    private let simulateNetworkDelay: Bool
    private let networkDelayRange: ClosedRange<TimeInterval>
    
    init(
        simulateNetworkDelay: Bool = true,
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
    
    // MARK: - Properties
    
    func fetchProperties(filters: PropertyFilters?) async throws -> [Property] {
        await simulateDelay()
        
        var results = Array(properties.values)
        
        // Apply filters if provided
        if let filters = filters {
            results = results.filter { property in
                // Price filter
                if let minPrice = filters.priceMin, property.price < minPrice {
                    return false
                }
                if let maxPrice = filters.priceMax, property.price > maxPrice {
                    return false
                }
                
                // Property type filter
                if let types = filters.propertyTypes, !types.isEmpty {
                    if !types.contains(property.propertyType) {
                        return false
                    }
                }
                
                // Location radius filter
                if let locationRadius = filters.locationRadius {
                    let distance = calculateDistance(
                        from: property.location,
                        to: locationRadius.center
                    )
                    if distance > locationRadius.radiusInMiles {
                        return false
                    }
                }
                
                // Bedrooms filter
                if let minBedrooms = filters.minBedrooms {
                    if let bedrooms = property.specifications.bedrooms {
                        if bedrooms < minBedrooms {
                            return false
                        }
                    } else {
                        return false
                    }
                }
                
                // Bathrooms filter
                if let minBathrooms = filters.minBathrooms {
                    if let bathrooms = property.specifications.bathrooms {
                        if bathrooms < minBathrooms {
                            return false
                        }
                    } else {
                        return false
                    }
                }
                
                // Source filter
                if let sources = filters.sources, !sources.isEmpty {
                    if !sources.contains(property.source) {
                        return false
                    }
                }
                
                return true
            }
        }
        
        // Only return active properties
        return results.filter { $0.status == .active }
    }
    
    func createProperty(_ property: Property) async throws -> Property {
        await simulateDelay()
        
        var newProperty = property
        if newProperty.id.isEmpty {
            newProperty = Property(
                id: UUID().uuidString,
                address: property.address,
                price: property.price,
                propertyType: property.propertyType,
                description: property.description,
                specifications: property.specifications,
                images: property.images,
                location: property.location,
                source: property.source,
                sellerId: property.sellerId,
                status: property.status,
                createdAt: property.createdAt,
                updatedAt: property.updatedAt
            )
        }
        
        properties[newProperty.id] = newProperty
        return newProperty
    }
    
    func updateProperty(_ property: Property) async throws {
        await simulateDelay()
        
        guard properties[property.id] != nil else {
            throw MockDataSourceError.notFound
        }
        
        var updatedProperty = property
        updatedProperty.updatedAt = Date()
        properties[property.id] = updatedProperty
    }
    
    func deleteProperty(id: String) async throws {
        await simulateDelay()
        
        guard properties[id] != nil else {
            throw MockDataSourceError.notFound
        }
        
        properties.removeValue(forKey: id)
        
        // Remove associated favorites
        let favoritesToRemove = favorites.values.filter { $0.propertyId == id }
        for favorite in favoritesToRemove {
            favorites.removeValue(forKey: favorite.id)
        }
    }
    
    // MARK: - Users
    
    func fetchUserProfile(id: String) async throws -> UserProfile {
        await simulateDelay()
        
        guard let profile = userProfiles[id] else {
            throw MockDataSourceError.notFound
        }
        
        return profile
    }
    
    func updateUserProfile(_ profile: UserProfile) async throws {
        await simulateDelay()
        userProfiles[profile.id] = profile
    }
    
    // MARK: - Favorites
    
    func fetchFavorites(userId: String) async throws -> [Favorite] {
        await simulateDelay()
        return favorites.values.filter { $0.userId == userId }
    }
    
    func addFavorite(_ favorite: Favorite) async throws {
        await simulateDelay()
        
        // Check if property exists
        guard properties[favorite.propertyId] != nil else {
            throw MockDataSourceError.propertyNotFound
        }
        
        favorites[favorite.id] = favorite
    }
    
    func removeFavorite(id: String) async throws {
        await simulateDelay()
        
        guard favorites[id] != nil else {
            throw MockDataSourceError.notFound
        }
        
        favorites.removeValue(forKey: id)
    }
    
    // MARK: - Images
    
    func uploadImage(_ imageData: Data, path: String) async throws -> URL {
        await simulateDelay()
        
        // Generate a mock URL
        let url = URL(string: "https://mock-storage.example.com/\(path)")!
        images[url] = imageData
        return url
    }
    
    func deleteImage(url: URL) async throws {
        await simulateDelay()
        
        guard images[url] != nil else {
            throw MockDataSourceError.notFound
        }
        
        images.removeValue(forKey: url)
    }
    
    // MARK: - Helper Methods
    
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
    
    /// Seed the mock data source with test data
    func seedData(
        properties: [Property] = [],
        userProfiles: [UserProfile] = [],
        favorites: [Favorite] = []
    ) {
        for property in properties {
            self.properties[property.id] = property
        }
        for profile in userProfiles {
            self.userProfiles[profile.id] = profile
        }
        for favorite in favorites {
            self.favorites[favorite.id] = favorite
        }
    }
    
    /// Clear all data from the mock data source
    func clearAll() {
        properties.removeAll()
        userProfiles.removeAll()
        favorites.removeAll()
        images.removeAll()
    }
    
    /// Get all stored properties (for testing)
    func getAllProperties() -> [Property] {
        Array(properties.values)
    }
    
    /// Get all stored user profiles (for testing)
    func getAllUserProfiles() -> [UserProfile] {
        Array(userProfiles.values)
    }
    
    /// Get all stored favorites (for testing)
    func getAllFavorites() -> [Favorite] {
        Array(favorites.values)
    }
}

// MARK: - Errors

enum MockDataSourceError: Error, LocalizedError {
    case notFound
    case propertyNotFound
    case userNotFound
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Resource not found"
        case .propertyNotFound:
            return "Property not found"
        case .userNotFound:
            return "User not found"
        case .invalidData:
            return "Invalid data provided"
        }
    }
}
