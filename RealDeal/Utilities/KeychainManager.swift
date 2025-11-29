import Foundation
import Security

/// Manages secure storage of credentials and tokens in the iOS Keychain
class KeychainManager {
    static let shared = KeychainManager()
    
    private init() {}
    
    // MARK: - Keys
    
    private enum Keys {
        static let accessToken = "com.realdeal.accessToken"
        static let refreshToken = "com.realdeal.refreshToken"
        static let tokenExpiry = "com.realdeal.tokenExpiry"
        static let userEmail = "com.realdeal.userEmail"
    }
    
    // MARK: - Public Methods
    
    /// Save authentication token to keychain
    func saveToken(_ token: AuthToken) throws {
        try save(token.accessToken, forKey: Keys.accessToken)
        
        if let refreshToken = token.refreshToken {
            try save(refreshToken, forKey: Keys.refreshToken)
        }
        
        let expiryString = ISO8601DateFormatter().string(from: token.expiresAt)
        try save(expiryString, forKey: Keys.tokenExpiry)
    }
    
    /// Retrieve authentication token from keychain
    func retrieveToken() throws -> AuthToken? {
        guard let accessToken = try retrieve(forKey: Keys.accessToken) else {
            return nil
        }
        
        let refreshToken = try retrieve(forKey: Keys.refreshToken)
        
        guard let expiryString = try retrieve(forKey: Keys.tokenExpiry),
              let expiresAt = ISO8601DateFormatter().date(from: expiryString) else {
            return nil
        }
        
        return AuthToken(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: expiresAt
        )
    }
    
    /// Delete authentication token from keychain
    func deleteToken() throws {
        try delete(forKey: Keys.accessToken)
        try delete(forKey: Keys.refreshToken)
        try delete(forKey: Keys.tokenExpiry)
    }
    
    /// Save user email to keychain
    func saveUserEmail(_ email: String) throws {
        try save(email, forKey: Keys.userEmail)
    }
    
    /// Retrieve user email from keychain
    func retrieveUserEmail() throws -> String? {
        try retrieve(forKey: Keys.userEmail)
    }
    
    /// Delete user email from keychain
    func deleteUserEmail() throws {
        try delete(forKey: Keys.userEmail)
    }
    
    /// Clear all keychain data
    func clearAll() throws {
        try deleteToken()
        try deleteUserEmail()
    }
    
    // MARK: - Private Methods
    
    private func save(_ value: String, forKey key: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }
        
        // Delete any existing item
        try? delete(forKey: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }
    
    private func retrieve(forKey key: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecItemNotFound {
            return nil
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.retrievalFailed(status)
        }
        
        guard let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            throw KeychainError.decodingFailed
        }
        
        return value
    }
    
    private func delete(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        // Success if item was deleted or didn't exist
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deletionFailed(status)
        }
    }
}

// MARK: - Errors

enum KeychainError: Error, LocalizedError {
    case encodingFailed
    case decodingFailed
    case saveFailed(OSStatus)
    case retrievalFailed(OSStatus)
    case deletionFailed(OSStatus)
    
    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode data for keychain storage"
        case .decodingFailed:
            return "Failed to decode data from keychain"
        case .saveFailed(let status):
            return "Failed to save to keychain (status: \(status))"
        case .retrievalFailed(let status):
            return "Failed to retrieve from keychain (status: \(status))"
        case .deletionFailed(let status):
            return "Failed to delete from keychain (status: \(status))"
        }
    }
}
