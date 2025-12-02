import Foundation

/// Protocol for AI-powered natural language search parsing
/// Converts natural language queries into structured property filters
protocol NaturalLanguageSearchProtocol: AIServiceProtocol {
    /// Parse a natural language query into structured property filters
    /// - Parameter query: The natural language search query (e.g., "3 bedroom house under $500k near downtown")
    /// - Returns: Structured PropertyFilters object
    func parseQuery(_ query: String) async throws -> PropertyFilters
    
    /// Parse a natural language query and return both filters and search intent
    /// - Parameter query: The natural language search query
    /// - Returns: Tuple containing filters and additional search context
    func parseQueryWithIntent(_ query: String) async throws -> (filters: PropertyFilters, intent: SearchIntent)
    
    /// Get suggested search queries based on current market trends
    /// - Parameter location: Optional location to get location-specific suggestions
    /// - Returns: Array of suggested search queries
    func getSuggestedQueries(for location: Coordinate?) async throws -> [String]
    
    /// Expand a simple query with related terms and synonyms
    /// - Parameter query: The original query to expand
    /// - Returns: Expanded query with additional relevant terms
    func expandQuery(_ query: String) async throws -> String
    
    /// Validate if a query can be processed by the natural language parser
    /// - Parameter query: The query to validate
    /// - Returns: True if the query can be processed, false otherwise
    func canProcessQuery(_ query: String) async -> Bool
}

/// Represents the intent and context extracted from a natural language search
struct SearchIntent: Codable {
    /// The primary intent of the search (buy, rent, invest, etc.)
    let primaryIntent: Intent
    
    /// Confidence level of the parsing (0.0 to 1.0)
    let confidence: Double
    
    /// Additional context or keywords extracted from the query
    let extractedKeywords: [String]
    
    /// Suggested refinements to improve the search
    let suggestedRefinements: [String]
    
    enum Intent: String, Codable {
        case buy = "buy"
        case rent = "rent"
        case invest = "invest"
        case browse = "browse"
        case compare = "compare"
        case unknown = "unknown"
    }
}