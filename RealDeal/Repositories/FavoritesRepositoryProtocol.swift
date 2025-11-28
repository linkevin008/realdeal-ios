import Foundation

protocol FavoritesRepositoryProtocol {
    func fetchFavorites(userId: String) async throws -> [Favorite]
    func addFavorite(_ favorite: Favorite) async throws
    func removeFavorite(id: String) async throws
    func isFavorite(propertyId: String, userId: String) async throws -> Bool
}
