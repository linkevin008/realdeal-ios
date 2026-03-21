import Foundation

/// Mock implementation of `CREADataSourceProtocol` for development and testing.
///
/// Contains realistic Canadian property listings across Toronto, Vancouver,
/// Calgary, Montreal, and Ottawa. No network access is required.
@available(iOS 15.0, macOS 12.0, *)
class MockCREADataSource: CREADataSourceProtocol {

    // MARK: - Configuration

    private let simulateNetworkDelay: Bool
    private let networkDelayRange: ClosedRange<TimeInterval>

    init(
        simulateNetworkDelay: Bool = true,
        networkDelayRange: ClosedRange<TimeInterval> = 0.1...0.5
    ) {
        self.simulateNetworkDelay = simulateNetworkDelay
        self.networkDelayRange = networkDelayRange
    }

    // MARK: - CREADataSourceProtocol

    func fetchListings(filters: PropertyFilters?) async throws -> [Property] {
        await simulateDelay()

        var results = Self.sampleListings

        if let filters = filters {
            results = results.filter { property in
                if let minPrice = filters.priceMin, property.price < minPrice {
                    return false
                }
                if let maxPrice = filters.priceMax, property.price > maxPrice {
                    return false
                }
                if let types = filters.propertyTypes, !types.isEmpty {
                    if !types.contains(property.propertyType) {
                        return false
                    }
                }
                if let locationRadius = filters.locationRadius {
                    let distance = GeoUtils.distance(
                        from: property.location,
                        to: locationRadius.center
                    )
                    if distance > locationRadius.radiusInMiles {
                        return false
                    }
                }
                if let minBedrooms = filters.minBedrooms {
                    guard let bedrooms = property.specifications.bedrooms,
                          bedrooms >= minBedrooms else { return false }
                }
                if let minBathrooms = filters.minBathrooms {
                    guard let bathrooms = property.specifications.bathrooms,
                          bathrooms >= minBathrooms else { return false }
                }
                if let sources = filters.sources, !sources.isEmpty {
                    if !sources.contains(property.source) {
                        return false
                    }
                }
                return true
            }
        }

        return results.filter { $0.status == .active }
    }

    func fetchListing(ddfListingKey: String) async throws -> Property? {
        await simulateDelay()
        return Self.sampleListings.first { $0.id == ddfListingKey }
    }

    func fetchUpdatedListings(since date: Date) async throws -> [Property] {
        await simulateDelay()
        return Self.sampleListings.filter { $0.updatedAt >= date }
    }

    // MARK: - Private Helpers

    private func simulateDelay() async {
        guard simulateNetworkDelay else { return }
        let delay = TimeInterval.random(in: networkDelayRange)
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
    }

    // MARK: - Sample Data

    /// Ten realistic Canadian listings sourced from DDF.
    static let sampleListings: [Property] = [

        // Toronto — condos
        Property(
            id: "DDF_100000001",
            address: Address(
                street: "88 Scott Street, Unit 3201",
                city: "Toronto",
                province: "ON",
                postalCode: "M5E 0A9",
                country: "Canada"
            ),
            price: 899_000,
            propertyType: .condo,
            description: "Stunning 2-bedroom corner unit on the 32nd floor of 88 Scott. Floor-to-ceiling windows with panoramic views of Lake Ontario and the Financial District. Modern kitchen with integrated appliances, spa-inspired ensuite, and private balcony.",
            specifications: PropertySpecifications(
                bedrooms: 2,
                bathrooms: 2.0,
                squareFeet: 890,
                lotSize: nil,
                yearBuilt: 2018
            ),
            images: [],
            location: Coordinate(latitude: 43.6479, longitude: -79.3733),
            source: .crea,
            sellerId: nil,
            status: .active,
            createdAt: Date(),
            updatedAt: Date()
        ),

        Property(
            id: "DDF_100000002",
            address: Address(
                street: "155 Yorkville Avenue, Suite 1802",
                city: "Toronto",
                province: "ON",
                postalCode: "M5R 1C4",
                country: "Canada"
            ),
            price: 1_249_000,
            propertyType: .condo,
            description: "Luxurious 2-bedroom + den condo in the heart of Yorkville. Designer finishes throughout, chef's kitchen with quartz countertops, and a wraparound terrace offering unobstructed city views. Steps to world-class dining and boutiques.",
            specifications: PropertySpecifications(
                bedrooms: 2,
                bathrooms: 2.5,
                squareFeet: 1_180,
                lotSize: nil,
                yearBuilt: 2020
            ),
            images: [],
            location: Coordinate(latitude: 43.6716, longitude: -79.3932),
            source: .crea,
            sellerId: nil,
            status: .active,
            createdAt: Date(),
            updatedAt: Date()
        ),

        // Toronto — detached house
        Property(
            id: "DDF_100000003",
            address: Address(
                street: "47 Oriole Road",
                city: "Toronto",
                province: "ON",
                postalCode: "M4V 1S3",
                country: "Canada"
            ),
            price: 2_595_000,
            propertyType: .house,
            description: "Elegant four-bedroom detached home on a coveted street in Forest Hill. Fully renovated top-to-bottom with a gourmet kitchen, primary suite with spa bath, professionally landscaped gardens, and a legal lower suite.",
            specifications: PropertySpecifications(
                bedrooms: 4,
                bathrooms: 4.0,
                squareFeet: 3_100,
                lotSize: 6_000,
                yearBuilt: 1948
            ),
            images: [],
            location: Coordinate(latitude: 43.6888, longitude: -79.4031),
            source: .crea,
            sellerId: nil,
            status: .active,
            createdAt: Date(),
            updatedAt: Date()
        ),

        // Vancouver — condos
        Property(
            id: "DDF_100000004",
            address: Address(
                street: "1480 Howe Street, Unit 1204",
                city: "Vancouver",
                province: "BC",
                postalCode: "V6Z 1R8",
                country: "Canada"
            ),
            price: 1_098_000,
            propertyType: .condo,
            description: "Sophisticated 2-bedroom residence in Yaletown's Executive on the Park. Open-concept living with hardwood floors, gourmet kitchen, in-suite laundry, and a generous balcony overlooking Marinaside Crescent. Steps to seawall.",
            specifications: PropertySpecifications(
                bedrooms: 2,
                bathrooms: 2.0,
                squareFeet: 970,
                lotSize: nil,
                yearBuilt: 2007
            ),
            images: [],
            location: Coordinate(latitude: 49.2731, longitude: -123.1269),
            source: .crea,
            sellerId: nil,
            status: .active,
            createdAt: Date(),
            updatedAt: Date()
        ),

        // Vancouver — detached house
        Property(
            id: "DDF_100000005",
            address: Address(
                street: "3312 West 38th Avenue",
                city: "Vancouver",
                province: "BC",
                postalCode: "V6N 2X1",
                country: "Canada"
            ),
            price: 2_888_000,
            propertyType: .house,
            description: "Custom-built craftsman home in Dunbar. Five bedrooms, four bathrooms, open-plan main floor with high ceilings, south-facing yard, double garage, and a fully finished basement suite. Top-ranked school catchment.",
            specifications: PropertySpecifications(
                bedrooms: 5,
                bathrooms: 4.0,
                squareFeet: 3_450,
                lotSize: 5_938,
                yearBuilt: 2015
            ),
            images: [],
            location: Coordinate(latitude: 49.2398, longitude: -123.1738),
            source: .crea,
            sellerId: nil,
            status: .active,
            createdAt: Date(),
            updatedAt: Date()
        ),

        // Calgary — detached house
        Property(
            id: "DDF_100000006",
            address: Address(
                street: "214 Pump Hill Crescent SW",
                city: "Calgary",
                province: "AB",
                postalCode: "T2V 4M7",
                country: "Canada"
            ),
            price: 899_000,
            propertyType: .house,
            description: "Beautifully updated 4-bedroom family home in the established community of Pump Hill. Vaulted ceilings, quartz kitchen, hardwood throughout, heated triple garage, and a private south-facing backyard with in-ground pool.",
            specifications: PropertySpecifications(
                bedrooms: 4,
                bathrooms: 3.0,
                squareFeet: 2_650,
                lotSize: 8_200,
                yearBuilt: 1983
            ),
            images: [],
            location: Coordinate(latitude: 50.9722, longitude: -114.1038),
            source: .crea,
            sellerId: nil,
            status: .active,
            createdAt: Date(),
            updatedAt: Date()
        ),

        Property(
            id: "DDF_100000007",
            address: Address(
                street: "1108 Meredith Road NE, Unit 405",
                city: "Calgary",
                province: "AB",
                postalCode: "T2E 5A8",
                country: "Canada"
            ),
            price: 529_000,
            propertyType: .condo,
            description: "Contemporary 2-bedroom, 2-bathroom condo in Bridgeland with river valley views. Polished concrete floors, custom millwork, stainless appliances, two underground parking stalls, and a large private patio.",
            specifications: PropertySpecifications(
                bedrooms: 2,
                bathrooms: 2.0,
                squareFeet: 1_020,
                lotSize: nil,
                yearBuilt: 2019
            ),
            images: [],
            location: Coordinate(latitude: 51.0596, longitude: -114.0421),
            source: .crea,
            sellerId: nil,
            status: .active,
            createdAt: Date(),
            updatedAt: Date()
        ),

        // Montreal — properties
        Property(
            id: "DDF_100000008",
            address: Address(
                street: "4256 Rue Sainte-Catherine Ouest, App. 8",
                city: "Montréal",
                province: "QC",
                postalCode: "H3Z 1P7",
                country: "Canada"
            ),
            price: 749_000,
            propertyType: .condo,
            description: "Chic loft-style condo in Westmount, steps from Sherbrooke Street galleries and boutiques. Exposed brick, 11-foot ceilings, industrial kitchen, private rooftop terrace, and one indoor garage space.",
            specifications: PropertySpecifications(
                bedrooms: 2,
                bathrooms: 1.5,
                squareFeet: 1_050,
                lotSize: nil,
                yearBuilt: 1928
            ),
            images: [],
            location: Coordinate(latitude: 45.4831, longitude: -73.5933),
            source: .crea,
            sellerId: nil,
            status: .active,
            createdAt: Date(),
            updatedAt: Date()
        ),

        Property(
            id: "DDF_100000009",
            address: Address(
                street: "350 Rue Saint-Paul Est",
                city: "Montréal",
                province: "QC",
                postalCode: "H2Y 1H2",
                country: "Canada"
            ),
            price: 1_175_000,
            propertyType: .condo,
            description: "Magnificent Old Montreal loft in a heritage building dating to 1871. Three bedrooms, two full baths, original stone walls, 14-foot brick-arched ceilings, chef's kitchen, and private courtyard access. Rare offering.",
            specifications: PropertySpecifications(
                bedrooms: 3,
                bathrooms: 2.0,
                squareFeet: 1_700,
                lotSize: nil,
                yearBuilt: 1871
            ),
            images: [],
            location: Coordinate(latitude: 45.5084, longitude: -73.5531),
            source: .crea,
            sellerId: nil,
            status: .active,
            createdAt: Date(),
            updatedAt: Date()
        ),

        // Ottawa — house
        Property(
            id: "DDF_100000010",
            address: Address(
                street: "118 Glebe Avenue",
                city: "Ottawa",
                province: "ON",
                postalCode: "K1S 2C8",
                country: "Canada"
            ),
            price: 1_050_000,
            propertyType: .house,
            description: "Charming Victorian semi-detached in the Glebe, one of Ottawa's most walkable neighbourhoods. Three bedrooms, updated kitchen and baths, private fenced backyard with deck, original hardwood floors throughout, and an attached garage.",
            specifications: PropertySpecifications(
                bedrooms: 3,
                bathrooms: 2.0,
                squareFeet: 1_900,
                lotSize: 3_200,
                yearBuilt: 1910
            ),
            images: [],
            location: Coordinate(latitude: 45.4089, longitude: -75.6892),
            source: .crea,
            sellerId: nil,
            status: .active,
            createdAt: Date(),
            updatedAt: Date()
        ),

        Property(
            id: "DDF_100000011",
            address: Address(
                street: "43 Lisgar Street, Unit 602",
                city: "Ottawa",
                province: "ON",
                postalCode: "K2P 0C3",
                country: "Canada"
            ),
            price: 579_000,
            propertyType: .condo,
            description: "Modern 2-bedroom condo in Centretown within walking distance of Parliament Hill and the Byward Market. Floor-to-ceiling windows, open kitchen with island, in-suite laundry, and a south-facing balcony.",
            specifications: PropertySpecifications(
                bedrooms: 2,
                bathrooms: 1.0,
                squareFeet: 820,
                lotSize: nil,
                yearBuilt: 2016
            ),
            images: [],
            location: Coordinate(latitude: 45.4157, longitude: -75.6934),
            source: .crea,
            sellerId: nil,
            status: .active,
            createdAt: Date(),
            updatedAt: Date()
        )
    ]
}
