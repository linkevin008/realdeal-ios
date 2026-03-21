import Foundation

/// Mock implementation of AuthenticationServiceProtocol for testing and development
@available(iOS 15.0, macOS 12.0, *)
class MockAuthenticationService: AuthenticationServiceProtocol {
    // MARK: - Storage
    private var users: [String: (email: String, password: String, profile: UserProfile)] = [:]
    private var tokens: [String: AuthToken] = [:]
    private(set) var currentUser: UserProfile?
    
    // MARK: - Configuration
    private let simulateNetworkDelay: Bool
    private let networkDelayRange: ClosedRange<TimeInterval>
    
    init(
        simulateNetworkDelay: Bool = true,
        networkDelayRange: ClosedRange<TimeInterval> = 0.1...0.5
    ) {
        self.simulateNetworkDelay = simulateNetworkDelay
        self.networkDelayRange = networkDelayRange
    }
    
    // MARK: - Private Helpers
    
    private func simulateDelay() async {
        guard simulateNetworkDelay else { return }
        let delay = TimeInterval.random(in: networkDelayRange)
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
    }
    
    private func generateToken(for userId: String) -> AuthToken {
        let accessToken = "mock_access_token_\(userId)_\(UUID().uuidString)"
        let refreshToken = "mock_refresh_token_\(userId)_\(UUID().uuidString)"
        let expiresAt = Date().addingTimeInterval(3600) // 1 hour
        
        return AuthToken(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: expiresAt
        )
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        // More strict email validation:
        // - Must not start or end with dot
        // - Must not have consecutive dots
        // - Must have valid characters before and after @
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        guard emailPredicate.evaluate(with: email) else {
            return false
        }
        
        // Additional checks for edge cases
        let components = email.components(separatedBy: "@")
        guard components.count == 2 else {
            return false
        }
        
        let localPart = components[0]
        let domainPart = components[1]
        
        // Local part should not start or end with dot
        guard !localPart.hasPrefix("."), !localPart.hasSuffix(".") else {
            return false
        }
        
        // Domain part should not start or end with dot
        guard !domainPart.hasPrefix("."), !domainPart.hasSuffix(".") else {
            return false
        }
        
        // Should not have consecutive dots
        guard !email.contains("..") else {
            return false
        }
        
        return true
    }
    
    private func isValidPassword(_ password: String) -> Bool {
        // Password must be at least 8 characters
        return password.count >= 8
    }
    
    // MARK: - AuthenticationServiceProtocol
    
    func signIn(email: String, password: String) async throws -> AuthToken {
        await simulateDelay()
        
        // Find user by email
        guard let user = users.values.first(where: { $0.email == email }) else {
            throw MockAuthError.invalidCredentials
        }
        
        // Verify password
        guard user.password == password else {
            throw MockAuthError.invalidCredentials
        }
        
        // Generate token
        let token = generateToken(for: user.profile.id)
        tokens[token.accessToken] = token
        currentUser = user.profile
        
        return token
    }
    
    func signUp(email: String, password: String, profile: UserProfile) async throws -> AuthToken {
        await simulateDelay()
        
        // Validate email format
        guard isValidEmail(email) else {
            throw MockAuthError.invalidEmail
        }
        
        // Validate password strength
        guard isValidPassword(password) else {
            throw MockAuthError.weakPassword
        }
        
        // Check if user already exists
        if users.values.contains(where: { $0.email == email }) {
            throw MockAuthError.emailAlreadyInUse
        }
        
        // Create user
        var newProfile = profile
        if newProfile.id.isEmpty {
            newProfile = UserProfile(
                id: UUID().uuidString,
                name: profile.name,
                email: email,
                phoneNumber: profile.phoneNumber,
                profilePhotoURL: profile.profilePhotoURL,
                role: profile.role,
                visibilitySettings: profile.visibilitySettings,
                createdAt: Date()
            )
        }
        
        users[newProfile.id] = (email: email, password: password, profile: newProfile)
        
        // Generate token
        let token = generateToken(for: newProfile.id)
        tokens[token.accessToken] = token
        currentUser = newProfile
        
        return token
    }
    
    func signOut() async throws {
        await simulateDelay()
        currentUser = nil
    }
    
    func refreshToken(_ token: AuthToken) async throws -> AuthToken {
        await simulateDelay()
        
        guard let refreshToken = token.refreshToken else {
            throw MockAuthError.invalidToken
        }
        
        // Find user by refresh token
        guard let userId = users.keys.first(where: { userId in
            tokens.values.contains { $0.refreshToken == refreshToken }
        }) else {
            throw MockAuthError.invalidToken
        }
        
        // Generate new token
        let newToken = generateToken(for: userId)
        tokens[newToken.accessToken] = newToken
        
        return newToken
    }
    
    func signInWithApple(identityToken: String, nonce: String, fullName: String?, email: String?) async throws -> AuthToken {
        await simulateDelay()
        // In production: validate identityToken with Apple's public key via backend.
        // Here we create/retrieve a mock user keyed on the token.
        let userId = "apple_\(identityToken.prefix(16))"
        if let existing = users[userId] {
            currentUser = existing.profile
            let token = generateToken(for: userId)
            tokens[token.accessToken] = token
            return token
        }
        let profile = UserProfile(
            id: userId,
            name: fullName ?? "Apple User",
            email: email ?? "\(userId)@privaterelay.appleid.com",
            role: .buyer
        )
        users[userId] = (email: profile.email, password: "", profile: profile)
        currentUser = profile
        let token = generateToken(for: userId)
        tokens[token.accessToken] = token
        return token
    }

    func signInWithGoogle(idToken: String) async throws -> AuthToken {
        await simulateDelay()
        // In production: validate idToken with Google's public key via backend.
        let userId = "google_\(idToken.prefix(16))"
        if let existing = users[userId] {
            currentUser = existing.profile
            let token = generateToken(for: userId)
            tokens[token.accessToken] = token
            return token
        }
        let profile = UserProfile(
            id: userId,
            name: "Google User",
            email: "\(userId)@gmail.com",
            role: .buyer
        )
        users[userId] = (email: profile.email, password: "", profile: profile)
        currentUser = profile
        let token = generateToken(for: userId)
        tokens[token.accessToken] = token
        return token
    }

    // MARK: - Test Helpers
    
    /// Seed the mock authentication service with test users
    func seedUsers(_ users: [(email: String, password: String, profile: UserProfile)]) {
        for user in users {
            self.users[user.profile.id] = user
        }
    }
    
    /// Clear all users and tokens
    func clearAll() {
        users.removeAll()
        tokens.removeAll()
        currentUser = nil
    }
    
    /// Get all registered users (for testing)
    func getAllUsers() -> [UserProfile] {
        users.values.map { $0.profile }
    }
    
    /// Manually set current user (for testing)
    func setCurrentUser(_ profile: UserProfile?) {
        currentUser = profile
    }
}

// MARK: - Errors

enum MockAuthError: Error, LocalizedError {
    case invalidCredentials
    case invalidEmail
    case weakPassword
    case emailAlreadyInUse
    case invalidToken
    case userNotFound
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .invalidEmail:
            return "Invalid email format"
        case .weakPassword:
            return "Password must be at least 8 characters"
        case .emailAlreadyInUse:
            return "Email is already registered"
        case .invalidToken:
            return "Invalid or expired token"
        case .userNotFound:
            return "User not found"
        }
    }
}
