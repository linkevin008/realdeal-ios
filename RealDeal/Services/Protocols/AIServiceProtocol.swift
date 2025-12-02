import Foundation

/// Base protocol for all AI services in the application
/// Provides common functionality for AI service availability and configuration
protocol AIServiceProtocol {
    /// Indicates whether the AI service is currently available and configured
    var isAvailable: Bool { get }
    
    /// Configure the AI service with necessary credentials or settings
    /// - Parameter apiKey: The API key or configuration string for the service
    func configure(apiKey: String)
    
    /// Optional method to check service health/connectivity
    func checkHealth() async throws -> Bool
}

/// Default implementation for common AI service functionality
extension AIServiceProtocol {
    func checkHealth() async throws -> Bool {
        return isAvailable
    }
}