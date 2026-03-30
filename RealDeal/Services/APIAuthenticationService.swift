import Foundation

@available(iOS 15.0, macOS 12.0, *)
final class APIAuthenticationService: AuthenticationServiceProtocol {
    private let client: APIClient
    private(set) var currentUser: UserProfile?

    init(client: APIClient) {
        self.client = client
    }

    // MARK: - AuthenticationServiceProtocol

    func signIn(email: String, password: String) async throws -> AuthToken {
        struct Body: Encodable { let email: String; let password: String }
        do {
            let envelope: Envelope<AuthData> = try await client.post(
                "api/v1/auth/signin",
                body: Body(email: email, password: password)
            )
            currentUser = envelope.data.user.map(UserProfile.init(apiUser:))
            return envelope.data.asAuthToken()
        } catch let error as APIError {
            throw error.asAppError
        }
    }

    func signUp(email: String, password: String, profile: UserProfile) async throws -> AuthToken {
        struct Body: Encodable { let name: String; let email: String; let password: String; let role: String }
        let body = Body(
            name: profile.name,
            email: email,
            password: password,
            role: profile.role.apiValue
        )
        do {
            let envelope: Envelope<AuthData> = try await client.post("api/v1/auth/signup", body: body)
            currentUser = envelope.data.user.map(UserProfile.init(apiUser:))
            return envelope.data.asAuthToken()
        } catch let error as APIError {
            throw error.asAppError
        }
    }

    func signOut() async throws {
        try await client.postVoid("api/v1/auth/signout", requiresAuth: true)
        currentUser = nil
    }

    func refreshToken(_ token: AuthToken) async throws -> AuthToken {
        guard let refreshToken = token.refreshToken else {
            throw AppError.authentication(.tokenRefreshFailed)
        }
        struct Body: Encodable { let refreshToken: String }
        do {
            let envelope: Envelope<AuthData> = try await client.post(
                "api/v1/auth/refresh",
                body: Body(refreshToken: refreshToken)
            )
            return envelope.data.asAuthToken()
        } catch let error as APIError {
            throw error.asAppError
        }
    }

    func signInWithApple(identityToken: String, nonce: String, fullName: String?, email: String?) async throws -> AuthToken {
        throw APIError.notSupported
    }

    func signInWithGoogle(idToken: String) async throws -> AuthToken {
        throw APIError.notSupported
    }
}

// MARK: - Private DTOs

private struct Envelope<T: Decodable>: Decodable {
    let data: T
}

private struct AuthData: Decodable {
    let accessToken: String
    let refreshToken: String?
    let expiresAt: Date
    let user: APIUser?

    func asAuthToken() -> AuthToken {
        AuthToken(accessToken: accessToken, refreshToken: refreshToken, expiresAt: expiresAt)
    }
}

private struct APIUser: Decodable {
    let id: String
    let name: String
    let email: String
    let phoneNumber: String?
    let profilePhotoUrl: String?
    let role: String
    let showEmail: Bool
    let showPhone: Bool
    let showListings: Bool
    let createdAt: Date
}

// MARK: - Model Mapping

private extension UserProfile {
    init(apiUser: APIUser) {
        self.init(
            id: apiUser.id,
            name: apiUser.name,
            email: apiUser.email,
            phoneNumber: apiUser.phoneNumber,
            profilePhotoURL: apiUser.profilePhotoUrl.flatMap(URL.init(string:)),
            role: UserRole(apiRole: apiUser.role),
            visibilitySettings: ProfileVisibility(
                showEmail: apiUser.showEmail,
                showPhone: apiUser.showPhone,
                showListings: apiUser.showListings
            ),
            createdAt: apiUser.createdAt
        )
    }
}

private extension UserRole {
    var apiValue: String {
        switch self {
        case .buyer: return "buyer"
        case .agent, .homeowner: return "seller"
        }
    }

    init(apiRole: String) {
        switch apiRole {
        case "buyer": self = .buyer
        default: self = .homeowner
        }
    }
}
