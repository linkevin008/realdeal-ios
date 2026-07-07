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
    private var offers: [String: Offer] = [:]
    private var viewingSlots: [String: ViewingSlot] = [:]
    private var viewingRequests: [String: ViewingRequest] = [:]
    /// Buyer ID stamped on mock-submitted viewing requests, mirroring how
    /// submitOffer stamps "mock-buyer" — dev/preview flows only.
    var mockCurrentBuyerId: String = "mock-buyer"
    
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
                    let distance = GeoUtils.distance(
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
    
    func getProperty(id: String) async throws -> Property? {
        await simulateDelay()
        return properties[id]
    }

    func createProperty(_ property: Property) async throws -> Property {
        await simulateDelay()
        
        var newProperty = property
        if newProperty.id.isEmpty {
            newProperty = Property(
                id: UUID().uuidString,
                address: property.address,
                price: property.price,
                currency: property.currency,
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

    // MARK: - Offers

    func submitOffer(propertyId: String, amount: Double, message: String?) async throws -> Offer {
        await simulateDelay()
        let offer = Offer(
            id: UUID().uuidString,
            propertyId: propertyId,
            buyerId: "mock-buyer",
            amount: amount,
            message: message,
            status: .pending,
            createdAt: Date(),
            updatedAt: Date(),
            property: properties[propertyId],
            buyer: nil
        )
        offers[offer.id] = offer
        return offer
    }

    func fetchOffersForProperty(propertyId: String) async throws -> [Offer] {
        await simulateDelay()
        return offers.values.filter { $0.propertyId == propertyId }
    }

    func acceptOffer(propertyId: String, offerId: String) async throws -> Offer {
        await simulateDelay()
        guard var offer = offers[offerId] else { throw MockDataSourceError.notFound }
        offer = Offer(id: offer.id, propertyId: offer.propertyId, buyerId: offer.buyerId,
                      amount: offer.amount, message: offer.message, status: .accepted,
                      createdAt: offer.createdAt, updatedAt: Date(), property: offer.property, buyer: offer.buyer)
        offers[offerId] = offer
        return offer
    }

    func rejectOffer(propertyId: String, offerId: String) async throws -> Offer {
        await simulateDelay()
        guard var offer = offers[offerId] else { throw MockDataSourceError.notFound }
        offer = Offer(id: offer.id, propertyId: offer.propertyId, buyerId: offer.buyerId,
                      amount: offer.amount, message: offer.message, status: .rejected,
                      createdAt: offer.createdAt, updatedAt: Date(), property: offer.property, buyer: offer.buyer)
        offers[offerId] = offer
        return offer
    }

    func withdrawOffer(propertyId: String, offerId: String) async throws {
        await simulateDelay()
        guard offers[offerId] != nil else { throw MockDataSourceError.notFound }
        offers.removeValue(forKey: offerId)
    }

    func fetchMyOffers() async throws -> [Offer] {
        await simulateDelay()
        return Array(offers.values)
    }

    // MARK: - Viewings

    func createViewingSlot(propertyId: String, startTime: Date, endTime: Date) async throws -> ViewingSlot {
        await simulateDelay()
        let slot = ViewingSlot(id: UUID().uuidString, propertyId: propertyId, startTime: startTime, endTime: endTime, booked: false)
        viewingSlots[slot.id] = slot
        return slot
    }

    func fetchViewingSlots(propertyId: String) async throws -> [ViewingSlot] {
        await simulateDelay()
        return viewingSlots.values
            .filter { $0.propertyId == propertyId }
            .sorted { $0.startTime < $1.startTime }
    }

    func deleteViewingSlot(propertyId: String, slotId: String) async throws {
        await simulateDelay()
        guard viewingSlots[slotId] != nil else { throw MockDataSourceError.notFound }
        viewingSlots.removeValue(forKey: slotId)
    }

    func requestViewing(propertyId: String, slotId: String, message: String?) async throws -> ViewingRequest {
        await simulateDelay()
        guard let slot = viewingSlots[slotId] else { throw MockDataSourceError.notFound }
        let request = ViewingRequest(
            id: UUID().uuidString,
            slotId: slotId,
            propertyId: propertyId,
            buyerId: mockCurrentBuyerId,
            message: message,
            status: .pending,
            createdAt: Date(),
            slot: slot,
            buyer: nil,
            property: properties[propertyId]
        )
        viewingRequests[request.id] = request
        return request
    }

    func fetchViewingRequests(propertyId: String) async throws -> [ViewingRequest] {
        await simulateDelay()
        return viewingRequests.values
            .filter { $0.propertyId == propertyId }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func acceptViewingRequest(propertyId: String, requestId: String) async throws -> ViewingRequest {
        await simulateDelay()
        guard let request = viewingRequests[requestId] else { throw MockDataSourceError.notFound }
        let updated = ViewingRequest(
            id: request.id, slotId: request.slotId, propertyId: request.propertyId, buyerId: request.buyerId,
            message: request.message, status: .accepted, createdAt: request.createdAt,
            slot: request.slot, buyer: request.buyer, property: request.property
        )
        viewingRequests[requestId] = updated

        // Mirror the API: accepting one request declines other pending
        // requests for the same slot, and the slot becomes booked.
        for (id, other) in viewingRequests where other.slotId == request.slotId && id != requestId && other.status == .pending {
            viewingRequests[id] = ViewingRequest(
                id: other.id, slotId: other.slotId, propertyId: other.propertyId, buyerId: other.buyerId,
                message: other.message, status: .declined, createdAt: other.createdAt,
                slot: other.slot, buyer: other.buyer, property: other.property
            )
        }
        if let slot = viewingSlots[request.slotId] {
            viewingSlots[request.slotId] = ViewingSlot(
                id: slot.id, propertyId: slot.propertyId, startTime: slot.startTime, endTime: slot.endTime, booked: true
            )
        }
        return updated
    }

    func declineViewingRequest(propertyId: String, requestId: String) async throws -> ViewingRequest {
        await simulateDelay()
        guard let request = viewingRequests[requestId] else { throw MockDataSourceError.notFound }
        let updated = ViewingRequest(
            id: request.id, slotId: request.slotId, propertyId: request.propertyId, buyerId: request.buyerId,
            message: request.message, status: .declined, createdAt: request.createdAt,
            slot: request.slot, buyer: request.buyer, property: request.property
        )
        viewingRequests[requestId] = updated
        return updated
    }

    func cancelViewingRequest(requestId: String) async throws {
        await simulateDelay()
        guard let request = viewingRequests[requestId] else { throw MockDataSourceError.notFound }
        viewingRequests[requestId] = ViewingRequest(
            id: request.id, slotId: request.slotId, propertyId: request.propertyId, buyerId: request.buyerId,
            message: request.message, status: .cancelled, createdAt: request.createdAt,
            slot: request.slot, buyer: request.buyer, property: request.property
        )
    }

    func fetchMyViewingRequests() async throws -> [ViewingRequest] {
        await simulateDelay()
        return viewingRequests.values
            .filter { $0.buyerId == mockCurrentBuyerId }
            .sorted { $0.createdAt > $1.createdAt }
    }

    // MARK: - Test Helpers
    
    /// Seed the mock data source with test data
    func seedData(
        properties: [Property] = [],
        userProfiles: [UserProfile] = [],
        favorites: [Favorite] = [],
        viewingSlots: [ViewingSlot] = [],
        viewingRequests: [ViewingRequest] = []
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
        for slot in viewingSlots {
            self.viewingSlots[slot.id] = slot
        }
        for request in viewingRequests {
            self.viewingRequests[request.id] = request
        }
    }

    /// Clear all data from the mock data source
    func clearAll() {
        properties.removeAll()
        userProfiles.removeAll()
        favorites.removeAll()
        images.removeAll()
        viewingSlots.removeAll()
        viewingRequests.removeAll()
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
