import Foundation

/// A first-level administrative division (US state, Canadian province).
struct CountrySubdivision: Codable, Equatable, Hashable {
    let code: String
    let name: String
}

/// A country listings can be created in, with its valid state/province codes.
/// An empty subdivision list means the field is free text.
struct SupportedCountry: Codable, Equatable {
    let code: String
    let subdivisions: [CountrySubdivision]
}

protocol RemoteDataSourceProtocol {
    // Config
    /// Countries listings can be created in, with their subdivisions.
    /// Single source of truth is the backend (GET /api/v1/config/countries).
    func fetchSupportedCountries() async throws -> [SupportedCountry]

    // Properties
    func fetchProperties(filters: PropertyFilters?) async throws -> [Property]
    func getProperty(id: String) async throws -> Property?
    func createProperty(_ property: Property) async throws -> Property
    func updateProperty(_ property: Property) async throws
    func deleteProperty(id: String) async throws
    
    // Users
    func fetchUserProfile(id: String) async throws -> UserProfile
    func updateUserProfile(_ profile: UserProfile) async throws
    
    // Favorites
    func fetchFavorites(userId: String) async throws -> [Favorite]
    func addFavorite(_ favorite: Favorite) async throws
    func removeFavorite(id: String) async throws
    
    // Images
    func uploadImage(_ imageData: Data, path: String) async throws -> URL
    func deleteImage(url: URL) async throws

    // Offers
    func submitOffer(propertyId: String, amount: Double, message: String?) async throws -> Offer
    func fetchOffersForProperty(propertyId: String) async throws -> [Offer]
    func acceptOffer(propertyId: String, offerId: String) async throws -> Offer
    func rejectOffer(propertyId: String, offerId: String) async throws -> Offer
    func withdrawOffer(propertyId: String, offerId: String) async throws
    func fetchMyOffers() async throws -> [Offer]
}

extension RemoteDataSourceProtocol {
    /// Default mirrors the backend's launch countries (subdivisions empty —
    /// the form falls back to free text) so mocks and offline paths keep
    /// working; APIRemoteDataSource overrides with the live endpoint.
    func fetchSupportedCountries() async throws -> [SupportedCountry] {
        [SupportedCountry(code: "US", subdivisions: []),
         SupportedCountry(code: "CA", subdivisions: [])]
    }
}
