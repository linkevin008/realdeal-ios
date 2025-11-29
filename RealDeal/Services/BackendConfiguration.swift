import Foundation

/// Configuration for backend services
/// Supports multiple backend implementations (Firebase, Supabase, custom API, etc.)
struct BackendConfiguration {
    let baseURL: URL?
    let apiKey: String?
    let authEndpoint: String?
    let storageEndpoint: String?
    let timeout: TimeInterval
    let enableLogging: Bool
    
    init(
        baseURL: URL? = nil,
        apiKey: String? = nil,
        authEndpoint: String? = nil,
        storageEndpoint: String? = nil,
        timeout: TimeInterval = 30.0,
        enableLogging: Bool = false
    ) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.authEndpoint = authEndpoint
        self.storageEndpoint = storageEndpoint
        self.timeout = timeout
        self.enableLogging = enableLogging
    }
    
    // MARK: - Predefined Configurations
    
    /// Firebase backend configuration
    static func firebase(
        projectId: String,
        apiKey: String,
        storageBucket: String
    ) -> BackendConfiguration {
        BackendConfiguration(
            baseURL: URL(string: "https://firestore.googleapis.com/v1/projects/\(projectId)/databases/(default)/documents"),
            apiKey: apiKey,
            authEndpoint: "https://identitytoolkit.googleapis.com/v1/accounts",
            storageEndpoint: "https://firebasestorage.googleapis.com/v0/b/\(storageBucket)/o",
            enableLogging: true
        )
    }
    
    /// Supabase backend configuration
    static func supabase(
        projectURL: URL,
        apiKey: String
    ) -> BackendConfiguration {
        BackendConfiguration(
            baseURL: projectURL.appendingPathComponent("rest/v1"),
            apiKey: apiKey,
            authEndpoint: projectURL.appendingPathComponent("auth/v1").absoluteString,
            storageEndpoint: projectURL.appendingPathComponent("storage/v1").absoluteString,
            enableLogging: true
        )
    }
    
    /// Custom REST API backend configuration
    static func custom(
        baseURL: URL,
        apiKey: String? = nil,
        authEndpoint: String? = nil,
        storageEndpoint: String? = nil
    ) -> BackendConfiguration {
        BackendConfiguration(
            baseURL: baseURL,
            apiKey: apiKey,
            authEndpoint: authEndpoint,
            storageEndpoint: storageEndpoint,
            enableLogging: true
        )
    }
    
    /// Mock configuration for testing and development
    static let mock = BackendConfiguration(
        baseURL: URL(string: "http://localhost:8080"),
        apiKey: "mock-api-key",
        authEndpoint: "http://localhost:8080/auth",
        storageEndpoint: "http://localhost:8080/storage",
        timeout: 5.0,
        enableLogging: true
    )
}
