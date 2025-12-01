import Foundation

protocol LocalDataSourceProtocol {
    // Properties
    func fetchProperties(filters: PropertyFilters?) async throws -> [Property]
    func saveProperty(_ property: Property) async throws
    func saveProperties(_ properties: [Property]) async throws
    func deleteProperty(id: String) async throws
    func getProperty(id: String) async throws -> Property?
    
    // User Profiles
    func saveUserProfile(_ profile: UserProfile) async throws
    func getUserProfile(id: String) async throws -> UserProfile?
    func deleteUserProfile(id: String) async throws
    
    // Favorites
    func saveFavorite(_ favorite: Favorite) async throws
    func getFavorites(userId: String) async throws -> [Favorite]
    func deleteFavorite(id: String) async throws
    func deleteFavoritesByPropertyId(propertyId: String) async throws
    func isFavorite(propertyId: String, userId: String) async throws -> Bool
}
