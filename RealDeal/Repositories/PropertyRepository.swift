import Foundation

@available(iOS 15.0, macOS 12.0, *)
class PropertyRepository: PropertyRepositoryProtocol {
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
    
    func fetchProperties(filters: PropertyFilters?) async throws -> [Property] {
        // Offline-first: Try remote first if connected, fall back to cache
        if networkMonitor.isConnected {
            do {
                let properties = try await remoteDataSource.fetchProperties(filters: filters)
                // Cache the results locally
                try await localDataSource.saveProperties(properties)
                return properties
            } catch {
                // If remote fails, fall back to cache
                return try await localDataSource.fetchProperties(filters: filters)
            }
        } else {
            // Offline: use cache
            return try await localDataSource.fetchProperties(filters: filters)
        }
    }
    
    func createProperty(_ property: Property) async throws -> Property {
        // Save locally first for offline support
        try await localDataSource.saveProperty(property)
        
        // Try to sync with remote if connected
        if networkMonitor.isConnected {
            do {
                let remoteProperty = try await remoteDataSource.createProperty(property)
                // Update local cache with remote version
                try await localDataSource.saveProperty(remoteProperty)
                return remoteProperty
            } catch {
                // If remote fails, return local version
                // In a production app, you'd queue this for later sync
                return property
            }
        }
        
        return property
    }
    
    func updateProperty(_ property: Property) async throws {
        // Update locally first
        try await localDataSource.saveProperty(property)
        
        // Try to sync with remote if connected
        if networkMonitor.isConnected {
            do {
                try await remoteDataSource.updateProperty(property)
            } catch {
                // If remote fails, local update is still saved
                // In a production app, you'd queue this for later sync
            }
        }
    }
    
    func deleteProperty(id: String) async throws {
        // Delete associated favorites first (cascading delete)
        try await localDataSource.deleteFavoritesByPropertyId(propertyId: id)
        
        // Delete the property locally
        try await localDataSource.deleteProperty(id: id)
        
        // Try to sync with remote if connected
        if networkMonitor.isConnected {
            do {
                try await remoteDataSource.deleteProperty(id: id)
            } catch {
                // If remote fails, local deletion is still done
                // In a production app, you'd queue this for later sync
            }
        }
    }
    
    func getProperty(id: String) async throws -> Property? {
        // Try cache first for speed
        if let cachedProperty = try await localDataSource.getProperty(id: id) {
            return cachedProperty
        }
        
        // If not in cache and connected, try remote
        if networkMonitor.isConnected {
            // Note: RemoteDataSourceProtocol doesn't have getProperty method
            // So we'll just return nil if not in cache
            // In a production app, you might want to add this method to the protocol
            return nil
        }
        
        return nil
    }
}
