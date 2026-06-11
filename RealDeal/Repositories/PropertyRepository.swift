import Foundation

@available(iOS 15.0, macOS 12.0, *)
class PropertyRepository: PropertyRepositoryProtocol {
    private let localDataSource: LocalDataSourceProtocol
    private let remoteDataSource: RemoteDataSourceProtocol
    private let networkMonitor: NetworkMonitor
    /// Optional CREA DDF data source. When non-nil and the device is online,
    /// listings are fetched from CREA and the results are cached locally.
    /// Set to a `MockCREADataSource` during development or a live implementation
    /// once `CREAConfiguration.isConfigured` is true.
    private let creaDataSource: CREADataSourceProtocol?

    init(
        localDataSource: LocalDataSourceProtocol,
        remoteDataSource: RemoteDataSourceProtocol,
        networkMonitor: NetworkMonitor = .shared,
        creaDataSource: CREADataSourceProtocol? = nil
    ) {
        self.localDataSource = localDataSource
        self.remoteDataSource = remoteDataSource
        self.networkMonitor = networkMonitor
        self.creaDataSource = creaDataSource
    }

    func fetchProperties(filters: PropertyFilters?) async throws -> [Property] {
        // CREA path: use when a CREA data source is wired up and the device is online.
        if let crea = creaDataSource, networkMonitor.isConnected {
            do {
                let properties = try await crea.fetchListings(filters: filters)
                try await localDataSource.saveProperties(properties)
                return properties
            } catch {
                // CREA fetch failed — fall through to the standard remote/cache path.
            }
        }

        // Standard path: remote first if connected, fall back to cache
        if networkMonitor.isConnected {
            do {
                // Use retry logic for network requests
                let properties = try await remoteDataSource.fetchProperties(filters: filters)

                // Cache the results locally
                try await localDataSource.saveProperties(properties)
                return properties
            } catch let error as AppError {
                // If remote fails, fall back to cache
                do {
                    return try await localDataSource.fetchProperties(filters: filters)
                } catch {
                    // If cache also fails, throw the original network error
                    throw error
                }
            } catch {
                // For unknown errors, try cache
                return try await localDataSource.fetchProperties(filters: filters)
            }
        } else {
            // Offline: use cache
            return try await localDataSource.fetchProperties(filters: filters)
        }
    }
    
    func fetchSupportedCountries() async throws -> [SupportedCountry] {
        try await remoteDataSource.fetchSupportedCountries()
    }

    func createProperty(_ property: Property) async throws -> Property {
        // Save locally first for offline support
        try await localDataSource.saveProperty(property)
        
        // Try to sync with remote if connected
        if networkMonitor.isConnected {
            do {
                // Use retry logic with timeout for create operations
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
                // Use retry logic for update operations
                try await remoteDataSource.updateProperty(property)
            } catch {
                // If remote fails, local update is still saved
                // In a production app, you'd queue this for later sync
                throw error
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
                // Use retry logic for delete operations
                try await remoteDataSource.deleteProperty(id: id)
            } catch {
                // If remote fails, local deletion is still done
                // In a production app, you'd queue this for later sync
                throw error
            }
        }
    }
    
    func getProperty(id: String) async throws -> Property? {
        // Try cache first for speed
        if let cachedProperty = try await localDataSource.getProperty(id: id) {
            return cachedProperty
        }

        // If not in cache and connected, fetch from remote
        if networkMonitor.isConnected {
            let remoteProperty = try await remoteDataSource.getProperty(id: id)

            // Cache the result locally if found
            if let property = remoteProperty {
                try await localDataSource.saveProperty(property)
            }

            return remoteProperty
        }

        return nil
    }
}
