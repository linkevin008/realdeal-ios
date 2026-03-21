import Foundation

/// Concrete implementation of AuthenticationServiceProtocol
/// Coordinates authentication with backend and manages local session state
@available(iOS 15.0, macOS 12.0, *)
class AuthenticationService: AuthenticationServiceProtocol {
    // MARK: - Properties
    
    private let backendAuth: AuthenticationServiceProtocol
    private let keychainManager: KeychainManager
    private let userProfileRepository: UserProfileRepositoryProtocol
    
    private(set) var currentUser: UserProfile?
    private var currentToken: AuthToken?
    
    // MARK: - Initialization
    
    init(
        backendAuth: AuthenticationServiceProtocol,
        keychainManager: KeychainManager = .shared,
        userProfileRepository: UserProfileRepositoryProtocol
    ) {
        self.backendAuth = backendAuth
        self.keychainManager = keychainManager
        self.userProfileRepository = userProfileRepository
        
        // Attempt to restore session on initialization
        Task {
            await restoreSession()
        }
    }
    
    // MARK: - AuthenticationServiceProtocol
    
    func signIn(email: String, password: String) async throws -> AuthToken {
        // Validate input
        guard Validator.isValidEmail(email) else {
            throw AppError.validation(.invalidEmailFormat)
        }
        
        guard !password.isEmpty else {
            throw AppError.validation(.missingRequiredField("Password"))
        }
        
        // Authenticate with backend
        let token = try await backendAuth.signIn(email: email, password: password)
        let profile = backendAuth.currentUser!
        
        // Store token securely
        try keychainManager.saveToken(token)
        try keychainManager.saveUserEmail(email)
        
        // Update current state
        currentToken = token
        currentUser = profile
        
        // Cache user profile locally
        _ = try await userProfileRepository.createUserProfile(profile)
        
        return token
    }
    
    func signUp(email: String, password: String, profile: UserProfile) async throws -> AuthToken {
        // Validate email
        guard Validator.isValidEmail(email) else {
            throw AppError.validation(.invalidEmailFormat)
        }
        
        // Validate password
        if let error = Validator.passwordValidationMessage(password) {
            throw AppError.validation(.weakPassword)
        }
        
        // Validate profile
        guard !profile.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AppError.validation(.missingRequiredField("Name"))
        }
        
        // Register with backend
        let token = try await backendAuth.signUp(email: email, password: password, profile: profile)
        let newProfile = backendAuth.currentUser!
        
        // Store token securely
        try keychainManager.saveToken(token)
        try keychainManager.saveUserEmail(email)
        
        // Update current state
        currentToken = token
        currentUser = newProfile
        
        // Cache user profile locally
        _ = try await userProfileRepository.createUserProfile(newProfile)
        
        return token
    }
    
    func signOut() async throws {
        // Clear keychain
        try keychainManager.clearAll()
        
        // Clear current state
        currentToken = nil
        currentUser = nil
        
        // Notify backend (if needed)
        // In production, you might want to invalidate the token on the server
    }
    
    func refreshToken(_ token: AuthToken) async throws -> AuthToken {
        // Check if token is expired
        guard token.expiresAt <= Date() else {
            // Token is still valid
            return token
        }
        
        // Refresh with backend
        let newToken = try await backendAuth.refreshToken(token)
        
        // Store new token
        try keychainManager.saveToken(newToken)
        currentToken = newToken
        
        return newToken
    }
    
    func signInWithApple(identityToken: String, nonce: String, fullName: String?, email: String?) async throws -> AuthToken {
        let token = try await backendAuth.signInWithApple(
            identityToken: identityToken, nonce: nonce, fullName: fullName, email: email
        )
        let profile = backendAuth.currentUser!
        try keychainManager.saveToken(token)
        currentToken = token
        currentUser = profile
        _ = try await userProfileRepository.createUserProfile(profile)
        return token
    }

    func signInWithGoogle(idToken: String) async throws -> AuthToken {
        let token = try await backendAuth.signInWithGoogle(idToken: idToken)
        let profile = backendAuth.currentUser!
        try keychainManager.saveToken(token)
        currentToken = token
        currentUser = profile
        _ = try await userProfileRepository.createUserProfile(profile)
        return token
    }

    // MARK: - Session Management
    
    /// Attempt to restore session from keychain
    private func restoreSession() async {
        do {
            guard let token = try keychainManager.retrieveToken() else {
                return
            }
            
            // Check if token is expired
            if token.expiresAt <= Date() {
                // Try to refresh
                let newToken = try await refreshToken(token)
                currentToken = newToken
            } else {
                currentToken = token
            }
            
            // Retrieve user email
            guard try keychainManager.retrieveUserEmail() != nil else {
                return
            }
            
            // Try to load user profile from backend
            currentUser = backendAuth.currentUser
        } catch {
            // Failed to restore session, user will need to sign in again
            try? keychainManager.clearAll()
        }
    }
    
    /// Check if current session is valid
    func isSessionValid() -> Bool {
        guard let token = currentToken else {
            return false
        }
        return token.expiresAt > Date()
    }
}

// MARK: - Validator

/// Email and password validation utilities
enum Validator {
    /// Validate email format
    static func isValidEmail(_ email: String) -> Bool {
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
    
    /// Validate password strength
    /// Requirements: At least 8 characters with letters and numbers
    static func isValidPassword(_ password: String) -> Bool {
        guard password.count >= 8 else {
            return false
        }
        
        let hasLetter = password.rangeOfCharacter(from: .letters) != nil
        let hasNumber = password.rangeOfCharacter(from: .decimalDigits) != nil
        
        return hasLetter && hasNumber
    }
    
    /// Get password validation error message
    static func passwordValidationMessage(_ password: String) -> String? {
        if password.isEmpty {
            return "Password is required"
        }
        if password.count < 8 {
            return "Password must be at least 8 characters"
        }
        if password.rangeOfCharacter(from: .letters) == nil {
            return "Password must contain at least one letter"
        }
        if password.rangeOfCharacter(from: .decimalDigits) == nil {
            return "Password must contain at least one number"
        }
        return nil
    }
    
    /// Validate phone number format
    static func isValidPhoneNumber(_ phoneNumber: String) -> Bool {
        guard !phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return true // Empty is valid (optional field)
        }
        
        let phonePattern = "^[+]?[(]?[0-9]{1,4}[)]?[-\\s\\.]?[(]?[0-9]{1,4}[)]?[-\\s\\.]?[0-9]{1,9}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phonePattern)
        return phonePredicate.evaluate(with: phoneNumber)
    }
}
