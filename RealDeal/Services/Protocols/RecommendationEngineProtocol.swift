import Foundation

/// Protocol for AI-powered property recommendation services
/// Provides personalized property recommendations based on user behavior and preferences
protocol RecommendationEngineProtocol: AIServiceProtocol {
    /// Get personalized property recommendations for a user
    /// - Parameters:
    ///   - user: The user profile to generate recommendations for
    ///   - limit: Maximum number of recommendations to return
    /// - Returns: Array of recommended properties
    func getRecommendations(for user: UserProfile, limit: Int) async throws -> [Property]
    
    /// Get recommendations based on a specific property (similar properties)
    /// - Parameters:
    ///   - property: The reference property to find similar properties for
    ///   - limit: Maximum number of recommendations to return
    /// - Returns: Array of similar properties
    func getSimilarProperties(to property: Property, limit: Int) async throws -> [Property]
    
    /// Record user interaction with a property for future recommendations
    /// - Parameters:
    ///   - userId: The user who interacted with the property
    ///   - propertyId: The property that was interacted with
    ///   - interaction: The type of interaction (view, favorite, contact, etc.)
    func recordInteraction(userId: String, propertyId: String, interaction: UserInteraction) async throws
    
    /// Get trending properties in a specific area
    /// - Parameters:
    ///   - location: The center point for the search
    ///   - radiusInMiles: The search radius
    ///   - limit: Maximum number of properties to return
    /// - Returns: Array of trending properties
    func getTrendingProperties(near location: Coordinate, radiusInMiles: Double, limit: Int) async throws -> [Property]
}

/// Types of user interactions that can be recorded for recommendation learning
enum UserInteraction: String, Codable {
    case view = "view"
    case favorite = "favorite"
    case unfavorite = "unfavorite"
    case contact = "contact"
    case share = "share"
    case search = "search"
}