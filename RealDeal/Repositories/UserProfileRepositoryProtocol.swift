import Foundation

protocol UserProfileRepositoryProtocol {
    func fetchUserProfile(id: String) async throws -> UserProfile
    func createUserProfile(_ profile: UserProfile) async throws -> UserProfile
    func updateUserProfile(_ profile: UserProfile) async throws
    func deleteUserProfile(id: String) async throws
}
