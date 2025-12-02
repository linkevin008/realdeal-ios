import Foundation

/// Helper for generating and handling deep link URLs
@available(iOS 15.0, macOS 12.0, *)
struct DeepLinkHelper {
    
    // MARK: - URL Scheme
    
    private static let scheme = "realdeal"
    
    // MARK: - URL Generation
    
    /// Generate a deep link URL for a property detail view
    /// - Parameter propertyId: The ID of the property
    /// - Returns: A URL that can be used to deep link to the property detail
    static func propertyDetailURL(propertyId: String) -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.path = "/property/\(propertyId)"
        return components.url
    }
    
    /// Generate a deep link URL for a user profile view
    /// - Parameters:
    ///   - userId: The ID of the user
    ///   - isOwnProfile: Whether this is the current user's own profile
    /// - Returns: A URL that can be used to deep link to the profile
    static func profileURL(userId: String, isOwnProfile: Bool = false) -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.path = "/profile/\(userId)"
        if isOwnProfile {
            components.queryItems = [URLQueryItem(name: "own", value: "true")]
        }
        return components.url
    }
    
    /// Generate a deep link URL for property creation
    /// - Returns: A URL that can be used to deep link to property creation
    static func propertyCreationURL() -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.path = "/create-property"
        return components.url
    }
    
    // MARK: - URL Parsing
    
    /// Parse a deep link URL to extract the destination type and parameters
    /// - Parameter url: The deep link URL to parse
    /// - Returns: A tuple containing the destination type and associated parameters
    static func parseDeepLink(_ url: URL) -> (type: String, id: String?, parameters: [String: String])? {
        guard url.scheme == scheme else {
            return nil
        }
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return nil
        }
        
        let pathComponents = components.path.split(separator: "/").map(String.init)
        
        guard !pathComponents.isEmpty else {
            return nil
        }
        
        let type = pathComponents[0]
        let id = pathComponents.count > 1 ? pathComponents[1] : nil
        
        var parameters: [String: String] = [:]
        if let queryItems = components.queryItems {
            for item in queryItems {
                if let value = item.value {
                    parameters[item.name] = value
                }
            }
        }
        
        return (type: type, id: id, parameters: parameters)
    }
    
    // MARK: - Sharing
    
    /// Generate a shareable text with deep link for a property
    /// - Parameters:
    ///   - property: The property to share
    ///   - includeURL: Whether to include the deep link URL
    /// - Returns: A formatted string for sharing
    static func shareableText(for property: Property, includeURL: Bool = true) -> String {
        var text = """
        Check out this property:
        \(property.address.street)
        \(property.address.city), \(property.address.state) \(property.address.zipCode)
        
        Price: \(formatPrice(property.price))
        """
        
        if includeURL, let url = propertyDetailURL(propertyId: property.id) {
            text += "\n\nView details: \(url.absoluteString)"
        }
        
        return text
    }
    
    // MARK: - Private Helpers
    
    private static func formatPrice(_ price: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: price as NSDecimalNumber) ?? "$0"
    }
}
