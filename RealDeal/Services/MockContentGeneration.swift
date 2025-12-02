import Foundation

/// Mock implementation of ContentGenerationProtocol for testing and development
/// Provides realistic AI-generated content simulation
class MockContentGeneration: ContentGenerationProtocol {
    private var configured = false
    
    var isAvailable: Bool {
        return configured
    }
    
    func configure(apiKey: String) {
        configured = !apiKey.isEmpty
    }
    
    func generateDescription(for property: Property) async throws -> String {
        guard isAvailable else {
            throw AIServiceError.serviceUnavailable
        }
        
        // Simulate API delay
        try await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds
        
        return generatePropertyDescription(property)
    }
    
    func generateTitle(for property: Property) async throws -> String {
        guard isAvailable else {
            throw AIServiceError.serviceUnavailable
        }
        
        // Simulate API delay
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        return generatePropertyTitle(property)
    }
    
    func generateMarketingCopy(for property: Property, style: MarketingStyle) async throws -> String {
        guard isAvailable else {
            throw AIServiceError.serviceUnavailable
        }
        
        // Simulate API delay
        try await Task.sleep(nanoseconds: 600_000_000) // 0.6 seconds
        
        return generateMarketingContent(property, style: style)
    }
    
    func generateNeighborhoodInsights(for location: Coordinate) async throws -> NeighborhoodInsights {
        guard isAvailable else {
            throw AIServiceError.serviceUnavailable
        }
        
        // Simulate API delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1.0 seconds
        
        return generateNeighborhoodInfo(for: location)
    }
    
    func generateComparison(for properties: [Property]) async throws -> String {
        guard isAvailable else {
            throw AIServiceError.serviceUnavailable
        }
        
        // Simulate API delay
        try await Task.sleep(nanoseconds: 700_000_000) // 0.7 seconds
        
        return generatePropertyComparison(properties)
    }
    
    func generateInvestmentAnalysis(for property: Property) async throws -> InvestmentAnalysis {
        guard isAvailable else {
            throw AIServiceError.serviceUnavailable
        }
        
        // Simulate API delay
        try await Task.sleep(nanoseconds: 1_200_000_000) // 1.2 seconds
        
        return generateInvestmentInfo(for: property)
    }
    
    func improveDescription(_ description: String) async throws -> ContentImprovement {
        guard isAvailable else {
            throw AIServiceError.serviceUnavailable
        }
        
        // Simulate API delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        return generateContentImprovement(for: description)
    }
    
    // MARK: - Private Helper Methods
    
    private func generatePropertyDescription(_ property: Property) -> String {
        let typeDescriptor = getTypeDescriptor(for: property.propertyType)
        let sizeInfo = getSizeDescription(for: property.specifications)
        let locationInfo = getLocationDescription(for: property.address)
        let priceInfo = getPriceDescription(for: property.price)
        
        let templates = [
            "Discover this \(typeDescriptor) featuring \(sizeInfo). Located in \(locationInfo), this property offers excellent value at \(priceInfo). Perfect for those seeking comfort and convenience in a desirable area.",
            
            "Welcome to this charming \(typeDescriptor) with \(sizeInfo). Situated in the heart of \(locationInfo), this home combines modern living with classic appeal. Priced at \(priceInfo), it represents an outstanding opportunity.",
            
            "This exceptional \(typeDescriptor) boasts \(sizeInfo) and is ideally positioned in \(locationInfo). At \(priceInfo), it offers the perfect blend of style, comfort, and location for discerning buyers.",
            
            "Experience the best of \(locationInfo) living in this beautiful \(typeDescriptor). With \(sizeInfo), this property provides ample space for comfortable living. Competitively priced at \(priceInfo)."
        ]
        
        return templates.randomElement() ?? templates[0]
    }
    
    private func generatePropertyTitle(_ property: Property) -> String {
        let typeDescriptor = getTypeDescriptor(for: property.propertyType)
        let bedroomInfo = property.specifications.bedrooms.map { "\($0)-Bedroom" } ?? ""
        let locationInfo = property.address.city
        
        let templates = [
            "Stunning \(bedroomInfo) \(typeDescriptor) in \(locationInfo)",
            "Beautiful \(typeDescriptor) - \(locationInfo)",
            "Modern \(bedroomInfo) \(typeDescriptor) - Prime \(locationInfo) Location",
            "Charming \(typeDescriptor) in Desirable \(locationInfo)",
            "Exceptional \(bedroomInfo) \(typeDescriptor) - \(locationInfo)"
        ]
        
        return templates.randomElement() ?? templates[0]
    }
    
    private func generateMarketingContent(_ property: Property, style: MarketingStyle) -> String {
        switch style {
        case .professional:
            return generateProfessionalCopy(property)
        case .casual:
            return generateCasualCopy(property)
        case .luxury:
            return generateLuxuryCopy(property)
        case .familyFriendly:
            return generateFamilyCopy(property)
        case .investor:
            return generateInvestorCopy(property)
        case .firstTimeBuyer:
            return generateFirstTimeBuyerCopy(property)
        }
    }
    
    private func generateProfessionalCopy(_ property: Property) -> String {
        return "This meticulously maintained property represents an exceptional opportunity in today's market. The residence features quality construction, thoughtful design, and premium finishes throughout. Located in a sought-after neighborhood with excellent amenities and transportation access."
    }
    
    private func generateCasualCopy(_ property: Property) -> String {
        return "You're going to love this place! It's got everything you need and more. Great location, awesome features, and it's move-in ready. Perfect for anyone looking to settle into a fantastic neighborhood with lots to offer."
    }
    
    private func generateLuxuryCopy(_ property: Property) -> String {
        return "Indulge in the epitome of sophisticated living with this extraordinary residence. Every detail has been carefully curated to create an atmosphere of refined elegance. From the premium materials to the impeccable craftsmanship, this property sets a new standard for luxury living."
    }
    
    private func generateFamilyCopy(_ property: Property) -> String {
        return "Create lasting memories in this wonderful family home! With plenty of space for everyone to grow and play, this property is perfect for busy families. Great schools nearby, safe neighborhood, and room for all your family activities."
    }
    
    private func generateInvestorCopy(_ property: Property) -> String {
        return "Excellent investment opportunity with strong rental potential and appreciation prospects. The property is well-positioned in a growing market with solid fundamentals. Low maintenance requirements and attractive cash flow projections make this an ideal addition to any portfolio."
    }
    
    private func generateFirstTimeBuyerCopy(_ property: Property) -> String {
        return "Perfect starter home for first-time buyers! This property offers great value and is move-in ready. No need for major renovations or repairs - just bring your belongings and start enjoying homeownership. Great community and convenient location."
    }
    
    private func generateNeighborhoodInfo(for location: Coordinate) -> NeighborhoodInsights {
        let neighborhoods = [
            "Downtown District", "Riverside Heights", "Oak Grove", "Sunset Hills", "Garden Valley"
        ]
        
        let selectedNeighborhood = neighborhoods.randomElement() ?? "Local Area"
        
        return NeighborhoodInsights(
            description: "\(selectedNeighborhood) is a vibrant community known for its tree-lined streets, friendly atmosphere, and convenient access to urban amenities. The area has experienced steady growth while maintaining its neighborhood charm.",
            highlights: [
                "Walking distance to parks and recreation",
                "Excellent public transportation",
                "Growing arts and culture scene",
                "Family-friendly community events"
            ],
            schools: [
                "Maplewood Elementary (Rating: 9/10)",
                "Central Middle School (Rating: 8/10)",
                "Riverside High School (Rating: 9/10)"
            ],
            transportation: [
                "Bus routes 15, 22, and 45",
                "Metro station 0.8 miles",
                "Major highways within 10 minutes",
                "Bike-friendly streets"
            ],
            amenities: [
                "Whole Foods Market",
                "Local coffee shops and cafes",
                "Community recreation center",
                "Farmers market (Saturdays)"
            ],
            community: "The neighborhood is known for its active community association, regular neighborhood watch programs, and low crime rates. Residents often describe it as a place where neighbors know each other and children can play safely."
        )
    }
    
    private func generatePropertyComparison(_ properties: [Property]) -> String {
        guard properties.count >= 2 else {
            return "At least two properties are needed for comparison."
        }
        
        let property1 = properties[0]
        let property2 = properties[1]
        
        return """
        Property Comparison Analysis:
        
        Property A (\(property1.address.street)):
        • Price: \(formatPrice(property1.price))
        • Type: \(property1.propertyType.rawValue.capitalized)
        • Bedrooms: \(property1.specifications.bedrooms ?? 0)
        • Bathrooms: \(property1.specifications.bathrooms ?? 0)
        
        Property B (\(property2.address.street)):
        • Price: \(formatPrice(property2.price))
        • Type: \(property2.propertyType.rawValue.capitalized)
        • Bedrooms: \(property2.specifications.bedrooms ?? 0)
        • Bathrooms: \(property2.specifications.bathrooms ?? 0)
        
        Key Differences:
        Property A offers better value per square foot, while Property B provides more modern amenities. Both properties are well-positioned in desirable neighborhoods with good growth potential.
        """
    }
    
    private func generateInvestmentInfo(for property: Property) -> InvestmentAnalysis {
        let priceDouble = Double(truncating: property.price as NSDecimalNumber)
        let estimatedRent = priceDouble * 0.008 // 0.8% of property value
        let yieldPercentage = (estimatedRent * 12) / priceDouble * 100
        
        return InvestmentAnalysis(
            summary: "This property presents a solid investment opportunity with balanced risk and return potential. The location shows strong fundamentals with consistent demand and moderate appreciation trends.",
            estimatedRentalYield: String(format: "%.1f%% annual yield (Est. $%.0f/month)", yieldPercentage, estimatedRent),
            appreciationPotential: "Moderate to strong appreciation expected based on neighborhood trends and planned developments in the area.",
            pros: [
                "Strong rental demand in the area",
                "Low maintenance property type",
                "Good transportation access",
                "Stable neighborhood demographics"
            ],
            considerations: [
                "Market conditions may affect short-term returns",
                "Property taxes trending upward",
                "Consider renovation costs for optimal rental rates"
            ],
            comparables: "Recent comparable sales in the area range from \(formatPrice(property.price * 0.9)) to \(formatPrice(property.price * 1.1)), indicating fair market pricing."
        )
    }
    
    private func generateContentImprovement(for description: String) -> ContentImprovement {
        let improvements = [
            "Added more descriptive adjectives",
            "Emphasized key selling points",
            "Improved flow and readability",
            "Included neighborhood benefits"
        ]
        
        let keywords = ["spacious", "modern", "convenient", "desirable", "quality"]
        
        let improvedDescription = description + " This property also features excellent natural light, quality finishes, and is situated in a highly desirable neighborhood with convenient access to shopping and dining."
        
        return ContentImprovement(
            improvedContent: improvedDescription,
            suggestions: improvements,
            confidence: 0.85,
            addedKeywords: keywords
        )
    }
    
    // MARK: - Utility Methods
    
    private func getTypeDescriptor(for type: PropertyType) -> String {
        switch type {
        case .house: return "single-family home"
        case .apartment: return "apartment"
        case .condo: return "condominium"
        case .land: return "land parcel"
        case .commercial: return "commercial property"
        }
    }
    
    private func getSizeDescription(for specs: PropertySpecifications) -> String {
        var parts: [String] = []
        
        if let bedrooms = specs.bedrooms {
            parts.append("\(bedrooms) bedroom\(bedrooms == 1 ? "" : "s")")
        }
        
        if let bathrooms = specs.bathrooms {
            parts.append("\(bathrooms) bathroom\(bathrooms == 1 ? "" : "s")")
        }
        
        if let sqft = specs.squareFeet {
            parts.append("\(sqft) sq ft")
        }
        
        return parts.isEmpty ? "well-appointed living space" : parts.joined(separator: ", ")
    }
    
    private func getLocationDescription(for address: Address) -> String {
        return "\(address.city), \(address.state)"
    }
    
    private func getPriceDescription(for price: Decimal) -> String {
        return formatPrice(price)
    }
    
    private func formatPrice(_ price: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: price as NSDecimalNumber) ?? "$\(price)"
    }
}