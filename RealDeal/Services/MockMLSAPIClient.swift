import Foundation

/// Mock MLS API Client for testing and development
/// Provides sample MLS listings without requiring actual API access
@available(iOS 15.0, macOS 12.0, *)
class MockMLSAPIClient: ExternalListingAPIProtocol {
    var shouldFail: Bool = false
    var mockListings: [ExternalListing] = []
    
    init() {
        // Initialize with some sample MLS listings
        mockListings = createSampleListings()
    }
    
    func fetchListings(parameters: SearchParameters) async throws -> [ExternalListing] {
        if shouldFail {
            throw AppError.network(.serverError(statusCode: 500))
        }
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Filter mock listings based on parameters
        var filtered = mockListings
        
        if let minPrice = parameters.minPrice {
            filtered = filtered.filter { listing in
                if let price = listing.rawData["price"] as? Double {
                    return Decimal(price) >= minPrice
                }
                return false
            }
        }
        
        if let maxPrice = parameters.maxPrice {
            filtered = filtered.filter { listing in
                if let price = listing.rawData["price"] as? Double {
                    return Decimal(price) <= maxPrice
                }
                return false
            }
        }
        
        if let propertyTypes = parameters.propertyTypes, !propertyTypes.isEmpty {
            filtered = filtered.filter { listing in
                if let type = listing.rawData["property_type"] as? String {
                    return propertyTypes.contains(type.lowercased())
                }
                return false
            }
        }
        
        return filtered
    }
    
    func normalizeToProperty(_ listing: ExternalListing) -> Property {
        let rawData = listing.rawData
        
        let address = Address(
            street: rawData["street"] as? String ?? "",
            city: rawData["city"] as? String ?? "",
            state: rawData["state"] as? String ?? "",
            zipCode: rawData["zip_code"] as? String ?? "",
            country: rawData["country"] as? String ?? "USA"
        )
        
        let price = Decimal(rawData["price"] as? Double ?? 0)
        
        let propertyTypeString = rawData["property_type"] as? String ?? "house"
        let propertyType = PropertyType(rawValue: propertyTypeString.lowercased()) ?? .house
        
        let description = rawData["description"] as? String ?? "No description available"
        
        let specifications = PropertySpecifications(
            bedrooms: rawData["bedrooms"] as? Int,
            bathrooms: rawData["bathrooms"] as? Double,
            squareFeet: rawData["square_feet"] as? Int,
            lotSize: rawData["lot_size"] as? Double,
            yearBuilt: rawData["year_built"] as? Int
        )
        
        let imageUrls = (rawData["images"] as? [String] ?? []).compactMap { URL(string: $0) }
        let images = imageUrls.enumerated().map { index, url in
            PropertyImage(url: url, order: index)
        }
        
        let location = Coordinate(
            latitude: rawData["latitude"] as? Double ?? 0,
            longitude: rawData["longitude"] as? Double ?? 0
        )
        
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
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    // MARK: - Sample Data Generation
    
    private func createSampleListings() -> [ExternalListing] {
        return [
            createListing(
                id: "MLS-001",
                street: "123 Oak Street",
                city: "San Francisco",
                state: "CA",
                zipCode: "94102",
                price: 1250000,
                propertyType: "house",
                description: "Beautiful Victorian home in the heart of SF",
                bedrooms: 3,
                bathrooms: 2.5,
                squareFeet: 2100,
                latitude: 37.7749,
                longitude: -122.4194
            ),
            createListing(
                id: "MLS-002",
                street: "456 Pine Avenue",
                city: "Los Angeles",
                state: "CA",
                zipCode: "90001",
                price: 850000,
                propertyType: "condo",
                description: "Modern condo with city views",
                bedrooms: 2,
                bathrooms: 2.0,
                squareFeet: 1400,
                latitude: 34.0522,
                longitude: -118.2437
            ),
            createListing(
                id: "MLS-003",
                street: "789 Maple Drive",
                city: "Austin",
                state: "TX",
                zipCode: "78701",
                price: 625000,
                propertyType: "house",
                description: "Spacious family home near downtown",
                bedrooms: 4,
                bathrooms: 3.0,
                squareFeet: 2800,
                latitude: 30.2672,
                longitude: -97.7431
            ),
            createListing(
                id: "MLS-004",
                street: "321 Elm Street",
                city: "Seattle",
                state: "WA",
                zipCode: "98101",
                price: 975000,
                propertyType: "apartment",
                description: "Luxury apartment in downtown Seattle",
                bedrooms: 2,
                bathrooms: 2.0,
                squareFeet: 1600,
                latitude: 47.6062,
                longitude: -122.3321
            ),
            createListing(
                id: "MLS-005",
                street: "555 Cedar Lane",
                city: "Denver",
                state: "CO",
                zipCode: "80202",
                price: 450000,
                propertyType: "land",
                description: "Prime development land with mountain views",
                bedrooms: nil,
                bathrooms: nil,
                squareFeet: nil,
                latitude: 39.7392,
                longitude: -104.9903
            )
        ]
    }
    
    private func createListing(
        id: String,
        street: String,
        city: String,
        state: String,
        zipCode: String,
        price: Double,
        propertyType: String,
        description: String,
        bedrooms: Int?,
        bathrooms: Double?,
        squareFeet: Int?,
        latitude: Double,
        longitude: Double
    ) -> ExternalListing {
        var rawData: [String: Any] = [
            "mls_id": id,
            "street": street,
            "city": city,
            "state": state,
            "zip_code": zipCode,
            "country": "USA",
            "price": price,
            "property_type": propertyType,
            "description": description,
            "latitude": latitude,
            "longitude": longitude,
            "images": [
                "https://example.com/images/\(id)-1.jpg",
                "https://example.com/images/\(id)-2.jpg"
            ]
        ]
        
        if let bedrooms = bedrooms {
            rawData["bedrooms"] = bedrooms
        }
        if let bathrooms = bathrooms {
            rawData["bathrooms"] = bathrooms
        }
        if let squareFeet = squareFeet {
            rawData["square_feet"] = squareFeet
        }
        
        return ExternalListing(id: id, rawData: rawData)
    }
}
