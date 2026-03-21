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

    /// Sign in with an Apple identity token.
    /// - Parameters:
    ///   - identityToken: JWT from Apple's authorization credential
    ///   - nonce: SHA-256 nonce used in the request
    ///   - fullName: Name components provided by Apple (only on first sign-in)
    ///   - email: Email provided by Apple (only on first sign-in)
    func signInWithApple(identityToken: String, nonce: String, fullName: String?, email: String?) async throws -> AuthToken

    /// Sign in with a Google ID token.
    /// - Parameter idToken: ID token from Google Sign-In
    func signInWithGoogle(idToken: String) async throws -> AuthToken

    var currentUser: UserProfile? { get }
}
