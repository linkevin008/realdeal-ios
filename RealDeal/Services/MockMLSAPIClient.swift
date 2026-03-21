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
            province: rawData["province"] as? String ?? "",
            postalCode: rawData["postal_code"] as? String ?? "",
            country: rawData["country"] as? String ?? "Canada"
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
                street: "123 King Street West",
                city: "Toronto",
                province: "ON",
                postalCode: "M5H 1J9",
                price: 1350000,
                propertyType: "condo",
                description: "Modern condo in the heart of downtown Toronto with stunning city views",
                bedrooms: 2,
                bathrooms: 2.0,
                squareFeet: 950,
                latitude: 43.6483,
                longitude: -79.3831
            ),
            createListing(
                id: "MLS-002",
                street: "456 Yonge Street",
                city: "Toronto",
                province: "ON",
                postalCode: "M4Y 1X7",
                price: 899000,
                propertyType: "condo",
                description: "Stylish condo steps from the subway with modern finishes",
                bedrooms: 1,
                bathrooms: 1.0,
                squareFeet: 650,
                latitude: 43.6659,
                longitude: -79.3832
            ),
            createListing(
                id: "MLS-003",
                street: "789 Bayview Avenue",
                city: "Toronto",
                province: "ON",
                postalCode: "M4G 3B3",
                price: 2150000,
                propertyType: "house",
                description: "Spacious detached family home in Leaside with renovated kitchen",
                bedrooms: 4,
                bathrooms: 3.0,
                squareFeet: 2800,
                latitude: 43.7034,
                longitude: -79.3625
            ),
            createListing(
                id: "MLS-004",
                street: "321 Kerrisdale Boulevard",
                city: "Vancouver",
                province: "BC",
                postalCode: "V6M 3R1",
                price: 2950000,
                propertyType: "house",
                description: "Elegant family home in prestigious Kerrisdale neighbourhood",
                bedrooms: 5,
                bathrooms: 4.0,
                squareFeet: 3600,
                latitude: 49.2331,
                longitude: -123.1594
            ),
            createListing(
                id: "MLS-005",
                street: "555 Robson Street",
                city: "Vancouver",
                province: "BC",
                postalCode: "V6B 2B5",
                price: 1100000,
                propertyType: "apartment",
                description: "Luxury apartment steps from Robson Street shopping and dining",
                bedrooms: 2,
                bathrooms: 2.0,
                squareFeet: 1100,
                latitude: 49.2812,
                longitude: -123.1213
            )
        ]
    }
    
    private func createListing(
        id: String,
        street: String,
        city: String,
        province: String,
        postalCode: String,
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
            "province": province,
            "postal_code": postalCode,
            "country": "Canada",
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
