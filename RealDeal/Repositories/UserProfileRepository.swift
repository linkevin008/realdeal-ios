import Foundation

@available(iOS 15.0, macOS 12.0, *)
class UserProfileRepository: UserProfileRepositoryProtocol {
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
    
    func fetchUserProfile(id: String) async throws -> UserProfile {
        // Cache-first strategy: Check cache first
        if let cachedProfile = try await localDataSource.getUserProfile(id: id) {
            // If connected, refresh in background
            if networkMonitor.isConnected {
                Task {
                    do {
                        let remoteProfile = try await remoteDataSource.fetchUserProfile(id: id)
                        try await localDataSource.saveUserProfile(remoteProfile)
                    } catch {
                        // Silently fail background refresh
                    }
                }
            }
            return cachedProfile
        }
        
        // Not in cache, fetch from remote if connected
        if networkMonitor.isConnected {
            let remoteProfile = try await remoteDataSource.fetchUserProfile(id: id)
            // Cache the result
            try await localDataSource.saveUserProfile(remoteProfile)
            return remoteProfile
        }
        
        // Not in cache and offline
        throw AppError.notFound
    }
    
    func createUserProfile(_ profile: UserProfile) async throws -> UserProfile {
        // Save locally first
        try await localDataSource.saveUserProfile(profile)
        
        // Try to sync with remote if connected
        if networkMonitor.isConnected {
            do {
                // Note: RemoteDataSourceProtocol doesn't have createUserProfile
                // It only has updateUserProfile, so we'll use that
                try await remoteDataSource.updateUserProfile(profile)
            } catch {
                // If remote fails, return local version
            }
        }
        
        return profile
    }
    
    func updateUserProfile(_ profile: UserProfile) async throws {
        // Update locally first
        try await localDataSource.saveUserProfile(profile)
        
        // Try to sync with remote if connected
        if networkMonitor.isConnected {
            do {
                try await remoteDataSource.updateUserProfile(profile)
            } catch {
                // If remote fails, local update is still saved
            }
        }
    }
    
    func deleteUserProfile(id: String) async throws {
        // Delete locally first
        try await localDataSource.deleteUserProfile(id: id)
        
        // Note: RemoteDataSourceProtocol doesn't have deleteUserProfile
        // In a production app, you'd add this method to the protocol
    }
}
