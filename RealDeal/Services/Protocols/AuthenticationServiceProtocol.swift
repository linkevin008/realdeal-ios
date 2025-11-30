import Foundation

struct AuthToken: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresAt: Date
}

protocol AuthenticationServiceProtocol {
    func signIn(email: String, password: String) async throws -> AuthToken
    func signUp(email: String, password: String, profile: UserProfile) async throws -> AuthToken
    func signOut() async throws
    func refreshToken(_ token: AuthToken) async throws -> AuthToken
    var currentUser: UserProfile? { get }
}
