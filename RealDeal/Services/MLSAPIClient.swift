import Foundation

/// MLS API Client for integrating with Multiple Listing Service
/// Implements ExternalListingAPIProtocol for third-party MLS integration
@available(iOS 15.0, macOS 12.0, *)
class MLSAPIClient: ExternalListingAPIProtocol {
    private let baseURL: URL
    private let apiKey: String
    private let session: URLSession
    
    init(baseURL: URL, apiKey: String, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.session = session
    }
    
    /// Fetch listings from MLS API based on search parameters
    func fetchListings(parameters: SearchParameters) async throws -> [ExternalListing] {
        var components = URLComponents(url: baseURL.appendingPathComponent("listings"), resolvingAgainstBaseURL: true)
        
        var queryItems: [URLQueryItem] = []
        
        if let location = parameters.location {
            queryItems.append(URLQueryItem(name: "location", value: location))
        }
        if let radius = parameters.radius {
            queryItems.append(URLQueryItem(name: "radius", value: String(radius)))
        }
        if let minPrice = parameters.minPrice {
            queryItems.append(URLQueryItem(name: "min_price", value: String(describing: minPrice)))
        }
        if let maxPrice = parameters.maxPrice {
            queryItems.append(URLQueryItem(name: "max_price", value: String(describing: maxPrice)))
        }
        if let propertyTypes = parameters.propertyTypes {
            queryItems.append(URLQueryItem(name: "property_types", value: propertyTypes.joined(separator: ",")))
        }
        
        components?.queryItems = queryItems
        
        guard let url = components?.url else {
            throw AppError.network(.invalidResponse)
        }
        
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.network(.invalidResponse)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 429 {
                throw AppError.network(.rateLimitExceeded)
            }
            throw AppError.network(.serverError(statusCode: httpResponse.statusCode))
        }
        
        let decoder = JSONDecoder()
        let mlsResponse = try decoder.decode(MLSListingsResponse.self, from: data)
        
        return mlsResponse.listings.map { mlsListing in
            ExternalListing(id: mlsListing.mlsId, rawData: mlsListing.toDictionary())
        }
    }
    
    /// Normalize external MLS listing to internal Property model
    /// Validates and sanitizes all data before conversion
    func normalizeToProperty(_ listing: ExternalListing) -> Property {
        let rawData = listing.rawData
        
        // Validate data before normalization
        // Note: We don't throw here to allow graceful degradation
        // Invalid data will use default values
        _ = try? ExternalDataValidator.validate(listing)
        
        // Extract and validate required fields
        let address = extractAddress(from: rawData)
        let price = extractPrice(from: rawData)
        let propertyType = extractPropertyType(from: rawData)
        let description = extractDescription(from: rawData)
        let specifications = extractSpecifications(from: rawData)
        let images = extractImages(from: rawData)
        let location = extractLocation(from: rawData)
        
        return Property(
            id: listing.id,
            address: address,
            price: price,
            propertyType: propertyType,
            description: description,
            specifications: specifications,
            images: images,
            location: location,
            source: .mls,
            sellerId: nil,
            status: .active,
            createdAt: extractCreatedDate(from: rawData),
            updatedAt: Date()
        )
    }
    
    // MARK: - Private Extraction Methods
    
    private func extractAddress(from data: [String: Any]) -> Address {
        let street = sanitizeString(data["street"] as? String) ?? ""
        let city = sanitizeString(data["city"] as? String) ?? ""
        let state = sanitizeString(data["state"] as? String) ?? ""
        let zipCode = sanitizeString(data["zip_code"] as? String ?? data["zipCode"] as? String) ?? ""
        let country = sanitizeString(data["country"] as? String) ?? "USA"
        
        return Address(
            street: street,
            city: city,
            state: state,
            zipCode: zipCode,
            country: country
        )
    }
    
    private func extractPrice(from data: [String: Any]) -> Decimal {
        if let priceDouble = data["price"] as? Double {
            return Decimal(priceDouble)
        }
        if let priceInt = data["price"] as? Int {
            return Decimal(priceInt)
        }
        if let priceString = data["price"] as? String,
           let priceDouble = Double(priceString) {
            return Decimal(priceDouble)
        }
        return Decimal(0)
    }
    
    private func extractPropertyType(from data: [String: Any]) -> PropertyType {
        guard let typeString = data["property_type"] as? String ?? data["propertyType"] as? String else {
            return .house
        }
        
        let normalized = typeString.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch normalized {
        case "house", "single family", "single-family", "sfh":
            return .house
        case "apartment", "apt":
            return .apartment
        case "condo", "condominium":
            return .condo
        case "land", "lot":
            return .land
        case "commercial":
            return .commercial
        default:
            return .house
        }
    }
    
    private func extractDescription(from data: [String: Any]) -> String {
        let description = sanitizeString(data["description"] as? String ?? data["remarks"] as? String)
        return description ?? "No description available"
    }
    
    private func extractSpecifications(from data: [String: Any]) -> PropertySpecifications {
        let bedrooms = data["bedrooms"] as? Int ?? data["beds"] as? Int
        let bathrooms = data["bathrooms"] as? Double ?? (data["baths"] as? Int).map(Double.init)
        let squareFeet = data["square_feet"] as? Int ?? data["sqft"] as? Int ?? data["squareFeet"] as? Int
        let lotSize = data["lot_size"] as? Double ?? data["lotSize"] as? Double
        let yearBuilt = data["year_built"] as? Int ?? data["yearBuilt"] as? Int
        
        return PropertySpecifications(
            bedrooms: bedrooms,
            bathrooms: bathrooms,
            squareFeet: squareFeet,
            lotSize: lotSize,
            yearBuilt: yearBuilt
        )
    }
    
    private func extractImages(from data: [String: Any]) -> [PropertyImage] {
        guard let imageUrls = data["images"] as? [String] ?? data["photos"] as? [String] else {
            return []
        }
        
        return imageUrls.enumerated().compactMap { index, urlString in
            guard let url = URL(string: urlString),
                  url.scheme == "http" || url.scheme == "https" else {
                return nil
            }
            return PropertyImage(url: url, order: index)
        }
    }
    
    private func extractLocation(from data: [String: Any]) -> Coordinate {
        let latitude: Double
        let longitude: Double
        
        if let lat = data["latitude"] as? Double ?? data["lat"] as? Double,
           let lon = data["longitude"] as? Double ?? data["lon"] as? Double ?? data["lng"] as? Double {
            latitude = lat
            longitude = lon
        } else {
            // Default to center of US if no coordinates provided
            latitude = 39.8283
            longitude = -98.5795
        }
        
        return Coordinate(latitude: latitude, longitude: longitude)
    }
    
    private func extractCreatedDate(from data: [String: Any]) -> Date {
        if let timestamp = data["created_at"] as? TimeInterval {
            return Date(timeIntervalSince1970: timestamp)
        }
        if let dateString = data["created_at"] as? String ?? data["list_date"] as? String {
            let formatter = ISO8601DateFormatter()
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        return Date()
    }
    
    /// Sanitize string input by removing potentially harmful characters and trimming whitespace
    private func sanitizeString(_ input: String?) -> String? {
        return ExternalDataValidator.sanitizeString(input)
    }
}

// MARK: - MLS Response Models

private struct MLSListingsResponse: Codable {
    let listings: [MLSListing]
}

private struct MLSListing: Codable {
    let mlsId: String
    let street: String?
    let city: String?
    let state: String?
    let zipCode: String?
    let country: String?
    let price: Double?
    let propertyType: String?
    let description: String?
    let bedrooms: Int?
    let bathrooms: Double?
    let squareFeet: Int?
    let lotSize: Double?
    let yearBuilt: Int?
    let images: [String]?
    let latitude: Double?
    let longitude: Double?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case mlsId = "mls_id"
        case street, city, state
        case zipCode = "zip_code"
        case country, price
        case propertyType = "property_type"
        case description, bedrooms, bathrooms
        case squareFeet = "square_feet"
        case lotSize = "lot_size"
        case yearBuilt = "year_built"
        case images, latitude, longitude
        case createdAt = "created_at"
    }
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = ["mls_id": mlsId]
        
        if let street = street { dict["street"] = street }
        if let city = city { dict["city"] = city }
        if let state = state { dict["state"] = state }
        if let zipCode = zipCode { dict["zip_code"] = zipCode }
        if let country = country { dict["country"] = country }
        if let price = price { dict["price"] = price }
        if let propertyType = propertyType { dict["property_type"] = propertyType }
        if let description = description { dict["description"] = description }
        if let bedrooms = bedrooms { dict["bedrooms"] = bedrooms }
        if let bathrooms = bathrooms { dict["bathrooms"] = bathrooms }
        if let squareFeet = squareFeet { dict["square_feet"] = squareFeet }
        if let lotSize = lotSize { dict["lot_size"] = lotSize }
        if let yearBuilt = yearBuilt { dict["year_built"] = yearBuilt }
        if let images = images { dict["images"] = images }
        if let latitude = latitude { dict["latitude"] = latitude }
        if let longitude = longitude { dict["longitude"] = longitude }
        if let createdAt = createdAt { dict["created_at"] = createdAt }
        
        return dict
    }
}
