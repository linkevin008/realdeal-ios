import Foundation

@available(iOS 15.0, macOS 12.0, *)
class FavoritesRepository: FavoritesRepositoryProtocol {
    private let localDataSource: LocalDataSourceProtocol
    private let remoteDataSource: RemoteDataSourceProtocol
    private let networkMonitor: NetworkMonitor
    
    init(
        localDataSource: LocalDataSourceProtocol,
        remoteDataSource: RemoteDataSourceProtocol,
        networkMonitor: NetworkMonitor = .shared
    ) {
        self.localDataSource = localDataSource
        self.remoteDataSource = remoteDataSource
        self.networkMonitor = networkMonitor
    }
    
    func fetchFavorites(userId: String) async throws -> [Favorite] {
        // Try remote first if connected to get latest data
        if networkMonitor.isConnected {
            do {
                let remoteFavorites = try await remoteDataSource.fetchFavorites(userId: userId)
                // Sync with local cache
                // First, clear existing favorites for this user
                let localFavorites = try await localDataSource.getFavorites(userId: userId)
                for favorite in localFavorites {
                    try await localDataSource.deleteFavorite(id: favorite.id)
                }
                // Then save the remote favorites
                for favorite in remoteFavorites {
                    try await localDataSource.saveFavorite(favorite)
                }
                return remoteFavorites
            } catch {
                // If remote fails, fall back to cache
                return try await localDataSource.getFavorites(userId: userId)
            }
        } else {
            // Offline: use cache
            return try await localDataSource.getFavorites(userId: userId)
        }
    }
    
    func addFavorite(_ favorite: Favorite) async throws {
        // Save locally first for immediate feedback
        try await localDataSource.saveFavorite(favorite)
        
        // Try to sync with remote if connected
        if networkMonitor.isConnected {
            do {
                try await remoteDataSource.addFavorite(favorite)
            } catch {
                // If remote fails, local save is still done
                // In a production app, you'd queue this for later sync
            }
        }
    }
    
    func removeFavorite(id: String) async throws {
        // Remove locally first for immediate feedback
        try await localDataSource.deleteFavorite(id: id)
        
        // Try to sync with remote if connected
        if networkMonitor.isConnected {
            do {
                try await remoteDataSource.removeFavorite(id: id)
            } catch {
                // If remote fails, local deletion is still done
                // In a production app, you'd queue this for later sync
            }
        }
    }
    
    func isFavorite(propertyId: String, userId: String) async throws -> Bool {
        // Check local cache first for speed
        return try await localDataSource.isFavorite(propertyId: propertyId, userId: userId)
    }
}
