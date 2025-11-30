import Foundation

protocol RemoteDataSourceProtocol {
    // Properties
    func fetchProperties(filters: PropertyFilters?) async throws -> [Property]
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
}
