import Foundation

/// Mock implementation of RecommendationEngineProtocol for testing and development
/// Provides realistic but simulated recommendation behavior
class MockRecommendationEngine: RecommendationEngineProtocol {
    private var configured = false
    private var interactions: [String: [UserInteraction]] = [:]
    
    var isAvailable: Bool {
        return configured
    }
    
    func configure(apiKey: String) {
        configured = !apiKey.isEmpty
    }
    
    func getRecommendations(for user: UserProfile, limit: Int) async throws -> [Property] {
        guard isAvailable else {
            throw AIServiceError.serviceUnavailable
        }
        
        // Simulate API delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Generate mock recommendations based on user role and interactions
        let mockProperties = generateMockProperties(for: user, count: min(limit, 10))
        
        return Array(mockProperties.prefix(limit))
    }
    
    func getSimilarProperties(to property: Property, limit: Int) async throws -> [Property] {
        guard isAvailable else {
            throw AIServiceError.serviceUnavailable
        }
        
        // Simulate API delay
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        // Generate similar properties based on the reference property
        let similarProperties = generateSimilarProperties(to: property, count: min(limit, 5))
        
        return Array(similarProperties.prefix(limit))
    }
    
    func recordInteraction(userId: String, propertyId: String, interaction: UserInteraction) async throws {
        guard isAvailable else {
            throw AIServiceError.serviceUnavailable
        }
        
        // Store interaction for future recommendation improvements
        if interactions[userId] == nil {
            interactions[userId] = []
        }
        interactions[userId]?.append(interaction)
    }
    
    func getTrendingProperties(near location: Coordinate, radiusInMiles: Double, limit: Int) async throws -> [Property] {
        guard isAvailable else {
            throw AIServiceError.serviceUnavailable
        }
        
        // Simulate API delay
        try await Task.sleep(nanoseconds: 400_000_000) // 0.4 seconds
        
        // Generate trending properties near the location
        let trendingProperties = generateTrendingProperties(near: location, count: min(limit, 8))
        
        return Array(trendingProperties.prefix(limit))
    }
    
    // MARK: - Private Helper Methods
    
    private func generateMockProperties(for user: UserProfile, count: Int) -> [Property] {
        var properties: [Property] = []
        
        for i in 0..<count {
            let property = Property(
                id: "mock-rec-\(i)",
                address: Address(
                    street: "\(100 + i * 10) Mock Street",
                    city: "Recommendation City",
                    state: "CA",
                    zipCode: "90210",
                    country: "US"
                ),
                price: Decimal(300000 + i * 50000),
                propertyType: PropertyType.allCases.randomElement() ?? .house,
                description: "AI-recommended property based on your preferences and viewing history.",
                specifications: PropertySpecifications(
                    bedrooms: Int.random(in: 2...5),
                    bathrooms: Double.random(in: 1.5...3.5),
                    squareFeet: Int.random(in: 1200...3000),
                    lotSize: Double.random(in: 0.1...0.5),
                    yearBuilt: Int.random(in: 1990...2020)
                ),
                location: Coordinate(
                    latitude: 34.0522 + Double.random(in: -0.1...0.1),
                    longitude: -118.2437 + Double.random(in: -0.1...0.1)
                ),
                source: .other
            )
            properties.append(property)
        }
        
        return properties
    }
    
    private func generateSimilarProperties(to property: Property, count: Int) -> [Property] {
        var properties: [Property] = []
        
        for i in 0..<count {
            // Create similar properties with slight variations
            let priceVariation = Double.random(in: 0.8...1.2)
            let newPrice = property.price * Decimal(priceVariation)
            
            let similarProperty = Property(
                id: "mock-similar-\(i)",
                address: Address(
                    street: "\(200 + i * 15) Similar Lane",
                    city: property.address.city,
                    state: property.address.state,
                    zipCode: property.address.zipCode,
                    country: property.address.country
                ),
                price: newPrice,
                propertyType: property.propertyType,
                description: "Similar property with comparable features and location.",
                specifications: PropertySpecifications(
                    bedrooms: property.specifications.bedrooms,
                    bathrooms: property.specifications.bathrooms,
                    squareFeet: property.specifications.squareFeet.map { Int(Double($0) * Double.random(in: 0.9...1.1)) },
                    lotSize: property.specifications.lotSize.map { $0 * Double.random(in: 0.8...1.2) },
                    yearBuilt: property.specifications.yearBuilt.map { $0 + Int.random(in: -5...5) }
                ),
                location: Coordinate(
                    latitude: property.location.latitude + Double.random(in: -0.01...0.01),
                    longitude: property.location.longitude + Double.random(in: -0.01...0.01)
                ),
                source: .other
            )
            properties.append(similarProperty)
        }
        
        return properties
    }
    
    private func generateTrendingProperties(near location: Coordinate, count: Int) -> [Property] {
        var properties: [Property] = []
        
        for i in 0..<count {
            let property = Property(
                id: "mock-trending-\(i)",
                address: Address(
                    street: "\(300 + i * 20) Trending Avenue",
                    city: "Trending City",
                    state: "CA",
                    zipCode: "90211",
                    country: "US"
                ),
                price: Decimal(400000 + i * 75000),
                propertyType: PropertyType.allCases.randomElement() ?? .house,
                description: "Trending property in high-demand area with recent market activity.",
                specifications: PropertySpecifications(
                    bedrooms: Int.random(in: 3...6),
                    bathrooms: Double.random(in: 2.0...4.5),
                    squareFeet: Int.random(in: 1500...4000),
                    lotSize: Double.random(in: 0.15...0.8),
                    yearBuilt: Int.random(in: 2000...2023)
                ),
                location: Coordinate(
                    latitude: location.latitude + Double.random(in: -0.05...0.05),
                    longitude: location.longitude + Double.random(in: -0.05...0.05)
                ),
                source: .other
            )
            properties.append(property)
        }
        
        return properties
    }
}

/// Errors that can occur with AI services
enum AIServiceError: Error, LocalizedError {
    case serviceUnavailable
    case invalidConfiguration
    case apiKeyMissing
    case requestFailed(String)
    case invalidResponse
    case rateLimitExceeded
    
    var errorDescription: String? {
        switch self {
        case .serviceUnavailable:
            return "AI service is not available or not configured"
        case .invalidConfiguration:
            return "AI service configuration is invalid"
        case .apiKeyMissing:
            return "API key is required but not provided"
        case .requestFailed(let message):
            return "AI service request failed: \(message)"
        case .invalidResponse:
            return "AI service returned an invalid response"
        case .rateLimitExceeded:
            return "AI service rate limit exceeded"
        }
    }
}