import Foundation

/// Mock implementation of NaturalLanguageSearchProtocol for testing and development
/// Provides realistic natural language query parsing simulation
class MockNaturalLanguageSearch: NaturalLanguageSearchProtocol {
    private var configured = false
    
    var isAvailable: Bool {
        return configured
    }
    
    func configure(apiKey: String) {
        configured = !apiKey.isEmpty
    }
    
    func parseQuery(_ query: String) async throws -> PropertyFilters {
        guard isAvailable else {
            throw AIServiceError.serviceUnavailable
        }
        
        // Simulate API delay
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        return parseQueryInternal(query).filters
    }
    
    func parseQueryWithIntent(_ query: String) async throws -> (filters: PropertyFilters, intent: SearchIntent) {
        guard isAvailable else {
            throw AIServiceError.serviceUnavailable
        }
        
        // Simulate API delay
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        return parseQueryInternal(query)
    }
    
    func getSuggestedQueries(for location: Coordinate?) async throws -> [String] {
        guard isAvailable else {
            throw AIServiceError.serviceUnavailable
        }
        
        // Simulate API delay
        try await Task.sleep(nanoseconds: 150_000_000) // 0.15 seconds
        
        var suggestions = [
            "3 bedroom house under $500k",
            "Modern apartment with parking",
            "Family home near good schools",
            "Investment property with high rental yield",
            "Luxury condo with city views"
        ]
        
        if location != nil {
            suggestions.append(contentsOf: [
                "Properties within 10 miles",
                "Walkable neighborhood with amenities",
                "Quiet residential area"
            ])
        }
        
        return suggestions.shuffled().prefix(5).map { String($0) }
    }
    
    func expandQuery(_ query: String) async throws -> String {
        guard isAvailable else {
            throw AIServiceError.serviceUnavailable
        }
        
        // Simulate API delay
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Simple query expansion simulation
        let expansions: [String: [String]] = [
            "house": ["single family home", "detached house", "residential property"],
            "apartment": ["condo", "unit", "flat"],
            "cheap": ["affordable", "budget-friendly", "under market value"],
            "expensive": ["luxury", "premium", "high-end"],
            "big": ["spacious", "large", "oversized"],
            "small": ["compact", "cozy", "efficient"]
        ]
        
        var expandedQuery = query.lowercased()
        
        for (term, synonyms) in expansions {
            if expandedQuery.contains(term) {
                let randomSynonym = synonyms.randomElement() ?? term
                expandedQuery = expandedQuery.replacingOccurrences(of: term, with: "\(term) OR \(randomSynonym)")
            }
        }
        
        return expandedQuery
    }
    
    func canProcessQuery(_ query: String) async -> Bool {
        // Simple validation - check if query contains property-related keywords
        let propertyKeywords = [
            "house", "apartment", "condo", "home", "property", "bedroom", "bathroom",
            "price", "cost", "buy", "rent", "sale", "location", "area", "neighborhood"
        ]
        
        let lowercaseQuery = query.lowercased()
        return propertyKeywords.contains { lowercaseQuery.contains($0) }
    }
    
    // MARK: - Private Helper Methods
    
    private func parseQueryInternal(_ query: String) -> (filters: PropertyFilters, intent: SearchIntent) {
        let lowercaseQuery = query.lowercased()
        var filters = PropertyFilters()
        var extractedKeywords: [String] = []
        var confidence: Double = 0.8
        var primaryIntent: SearchIntent.Intent = .browse
        
        // Parse price information
        if let priceRange = extractPriceRange(from: lowercaseQuery) {
            filters.priceMin = priceRange.min
            filters.priceMax = priceRange.max
            extractedKeywords.append("price")
        }
        
        // Parse property types
        let propertyTypes = extractPropertyTypes(from: lowercaseQuery)
        if !propertyTypes.isEmpty {
            filters.propertyTypes = Set(propertyTypes)
            extractedKeywords.append(contentsOf: propertyTypes.map { $0.rawValue })
        }
        
        // Parse bedroom/bathroom requirements
        if let bedrooms = extractNumber(from: lowercaseQuery, keyword: "bedroom") {
            filters.minBedrooms = bedrooms
            extractedKeywords.append("bedrooms")
        }
        
        if let bathrooms = extractNumber(from: lowercaseQuery, keyword: "bathroom") {
            filters.minBathrooms = Double(bathrooms)
            extractedKeywords.append("bathrooms")
        }
        
        // Determine intent
        if lowercaseQuery.contains("buy") || lowercaseQuery.contains("purchase") {
            primaryIntent = .buy
        } else if lowercaseQuery.contains("rent") || lowercaseQuery.contains("rental") {
            primaryIntent = .rent
        } else if lowercaseQuery.contains("invest") || lowercaseQuery.contains("investment") {
            primaryIntent = .invest
        } else if lowercaseQuery.contains("compare") {
            primaryIntent = .compare
        }
        
        // Adjust confidence based on how much we could parse
        if extractedKeywords.count >= 3 {
            confidence = 0.9
        } else if extractedKeywords.count >= 2 {
            confidence = 0.8
        } else if extractedKeywords.count >= 1 {
            confidence = 0.6
        } else {
            confidence = 0.3
        }
        
        let intent = SearchIntent(
            primaryIntent: primaryIntent,
            confidence: confidence,
            extractedKeywords: extractedKeywords,
            suggestedRefinements: generateRefinements(for: filters)
        )
        
        return (filters: filters, intent: intent)
    }
    
    private func extractPriceRange(from query: String) -> (min: Decimal?, max: Decimal?) {
        // Look for patterns like "under $500k", "$300k to $500k", "between $400k and $600k"
        let patterns = [
            #"under \$?(\d+)k"#,
            #"below \$?(\d+)k"#,
            #"\$?(\d+)k to \$?(\d+)k"#,
            #"between \$?(\d+)k and \$?(\d+)k"#,
            #"\$?(\d+),?(\d{3})"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(location: 0, length: query.utf16.count)
                if let match = regex.firstMatch(in: query, options: [], range: range) {
                    if pattern.contains("under") || pattern.contains("below") {
                        if let value = extractNumberFromMatch(match, in: query, at: 1) {
                            return (min: nil, max: Decimal(value * 1000))
                        }
                    } else if pattern.contains("to") || pattern.contains("and") {
                        if let min = extractNumberFromMatch(match, in: query, at: 1),
                           let max = extractNumberFromMatch(match, in: query, at: 2) {
                            return (min: Decimal(min * 1000), max: Decimal(max * 1000))
                        }
                    }
                }
            }
        }
        
        return (min: nil, max: nil)
    }
    
    private func extractPropertyTypes(from query: String) -> [PropertyType] {
        var types: [PropertyType] = []
        
        if query.contains("house") || query.contains("home") {
            types.append(.house)
        }
        if query.contains("apartment") || query.contains("apt") {
            types.append(.apartment)
        }
        if query.contains("condo") || query.contains("condominium") {
            types.append(.condo)
        }
        if query.contains("land") || query.contains("lot") {
            types.append(.land)
        }
        if query.contains("commercial") || query.contains("office") {
            types.append(.commercial)
        }
        
        return types
    }
    
    private func extractNumber(from query: String, keyword: String) -> Int? {
        let pattern = #"(\d+)\s*\#(keyword)"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
            let range = NSRange(location: 0, length: query.utf16.count)
            if let match = regex.firstMatch(in: query, options: [], range: range) {
                return extractNumberFromMatch(match, in: query, at: 1)
            }
        }
        return nil
    }
    
    private func extractNumberFromMatch(_ match: NSTextCheckingResult, in string: String, at index: Int) -> Int? {
        if match.numberOfRanges > index {
            let range = match.range(at: index)
            if range.location != NSNotFound {
                let substring = (string as NSString).substring(with: range)
                return Int(substring)
            }
        }
        return nil
    }
    
    private func generateRefinements(for filters: PropertyFilters) -> [String] {
        var refinements: [String] = []
        
        if filters.priceMin == nil && filters.priceMax == nil {
            refinements.append("Add price range")
        }
        
        if filters.propertyTypes == nil {
            refinements.append("Specify property type")
        }
        
        if filters.minBedrooms == nil {
            refinements.append("Add bedroom requirement")
        }
        
        if filters.locationRadius == nil {
            refinements.append("Specify location or area")
        }
        
        return refinements
    }
}