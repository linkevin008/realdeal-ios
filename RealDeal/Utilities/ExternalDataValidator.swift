import Foundation

/// Validates and sanitizes external listing data before normalization
struct ExternalDataValidator {
    
    /// Validates that external listing data contains required fields
    static func validate(_ listing: ExternalListing) throws {
        let rawData = listing.rawData
        
        // Validate address components
        try validateAddress(rawData)
        
        // Validate price
        try validatePrice(rawData)
        
        // Validate location coordinates
        try validateLocation(rawData)
        
        // Validate property type
        try validatePropertyType(rawData)
    }
    
    /// Validates address data
    private static func validateAddress(_ data: [String: Any]) throws {
        let street = data["street"] as? String
        let city = data["city"] as? String
        let province = data["province"] as? String

        if street?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true {
            throw AppError.validation(.missingRequiredField("street"))
        }

        if city?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true {
            throw AppError.validation(.missingRequiredField("city"))
        }

        if province?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true {
            throw AppError.validation(.missingRequiredField("province"))
        }
    }
    
    /// Validates price data
    private static func validatePrice(_ data: [String: Any]) throws {
        let price: Double?
        
        if let priceDouble = data["price"] as? Double {
            price = priceDouble
        } else if let priceInt = data["price"] as? Int {
            price = Double(priceInt)
        } else if let priceString = data["price"] as? String {
            price = Double(priceString)
        } else {
            throw AppError.validation(.missingRequiredField("price"))
        }
        
        guard let validPrice = price, validPrice > 0 else {
            throw AppError.validation(.invalidFormat("price"))
        }
    }
    
    /// Validates location coordinates
    private static func validateLocation(_ data: [String: Any]) throws {
        let latitude = data["latitude"] as? Double ?? data["lat"] as? Double
        let longitude = data["longitude"] as? Double ?? data["lon"] as? Double ?? data["lng"] as? Double
        
        guard let lat = latitude, let lon = longitude else {
            throw AppError.validation(.invalidLocation)
        }
        
        // Validate coordinate ranges
        guard lat >= -90 && lat <= 90 else {
            throw AppError.validation(.invalidFormat("latitude"))
        }
        
        guard lon >= -180 && lon <= 180 else {
            throw AppError.validation(.invalidFormat("longitude"))
        }
    }
    
    /// Validates property type
    private static func validatePropertyType(_ data: [String: Any]) throws {
        guard let typeString = data["property_type"] as? String ?? data["propertyType"] as? String,
              !typeString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AppError.validation(.missingRequiredField("property_type"))
        }
    }
    
    /// Sanitizes string input by removing potentially harmful characters
    static func sanitizeString(_ input: String?) -> String? {
        guard let input = input else { return nil }
        
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove control characters
        let sanitized = trimmed.components(separatedBy: .controlCharacters).joined()
        
        // Remove any null bytes
        let cleaned = sanitized.replacingOccurrences(of: "\0", with: "")
        
        return cleaned.isEmpty ? nil : cleaned
    }
    
    /// Sanitizes and validates image URLs
    static func sanitizeImageURLs(_ urls: [String]) -> [URL] {
        return urls.compactMap { urlString in
            guard let url = URL(string: urlString),
                  url.scheme == "http" || url.scheme == "https" else {
                return nil
            }
            return url
        }
    }
    
    /// Validates numeric specifications
    static func validateSpecifications(_ data: [String: Any]) -> Bool {
        // Validate bedrooms if present
        if let bedrooms = data["bedrooms"] as? Int ?? data["beds"] as? Int {
            guard bedrooms >= 0 && bedrooms <= 50 else { return false }
        }
        
        // Validate bathrooms if present
        if let bathrooms = data["bathrooms"] as? Double ?? (data["baths"] as? Int).map(Double.init) {
            guard bathrooms >= 0 && bathrooms <= 50 else { return false }
        }
        
        // Validate square feet if present
        if let sqft = data["square_feet"] as? Int ?? data["sqft"] as? Int {
            guard sqft > 0 && sqft <= 1_000_000 else { return false }
        }
        
        // Validate lot size if present
        if let lotSize = data["lot_size"] as? Double ?? data["lotSize"] as? Double {
            guard lotSize > 0 && lotSize <= 10_000 else { return false }
        }
        
        // Validate year built if present
        if let yearBuilt = data["year_built"] as? Int ?? data["yearBuilt"] as? Int {
            let currentYear = Calendar.current.component(.year, from: Date())
            guard yearBuilt >= 1800 && yearBuilt <= currentYear + 5 else { return false }
        }
        
        return true
    }
}
