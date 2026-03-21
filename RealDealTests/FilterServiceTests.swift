import XCTest
@testable import RealDeal

@available(iOS 15.0, macOS 12.0, *)
final class FilterServiceTests: XCTestCase {
    
    var filterService: FilterService!
    var testProperties: [Property]!
    
    override func setUp() {
        super.setUp()
        filterService = FilterService()
        
        // Create test properties with various attributes
        testProperties = [
            Property(
                id: "1",
                address: Address(street: "123 Main St", city: "Toronto", province: "ON", postalCode: "M5H 1J9", country: "Canada"),
                price: 500000,
                currency: "CAD",
                propertyType: .house,
                description: "Nice house",
                specifications: PropertySpecifications(bedrooms: 3, bathrooms: 2.0, squareFeet: 2000),
                location: Coordinate(latitude: 37.7749, longitude: -122.4194),
                source: .userGenerated,
                sellerId: "seller1",
                status: .active
            ),
            Property(
                id: "2",
                address: Address(street: "456 Oak Ave", city: "Toronto", province: "ON", postalCode: "M4Y 1X7", country: "Canada"),
                price: 750000,
                currency: "CAD",
                propertyType: .apartment,
                description: "Modern apartment",
                specifications: PropertySpecifications(bedrooms: 2, bathrooms: 1.5, squareFeet: 1200),
                location: Coordinate(latitude: 37.7849, longitude: -122.4094),
                source: .mls,
                sellerId: "seller2",
                status: .active
            ),
            Property(
                id: "3",
                address: Address(street: "789 Pine St", city: "Mississauga", province: "ON", postalCode: "L5B 3C4", country: "Canada"),
                price: 300000,
                currency: "CAD",
                propertyType: .condo,
                description: "Cozy condo",
                specifications: PropertySpecifications(bedrooms: 1, bathrooms: 1.0, squareFeet: 800),
                location: Coordinate(latitude: 37.8044, longitude: -122.2712),
                source: .userGenerated,
                sellerId: "seller1",
                status: .active
            )
        ]
    }
    
    override func tearDown() {
        filterService = nil
        testProperties = nil
        super.tearDown()
    }
    
    // MARK: - No Filter Tests
    
    func testApplyFiltersWithNilReturnsAllProperties() throws {
        let result = try filterService.applyFilters(testProperties, filters: nil)
        XCTAssertEqual(result.count, 3)
    }
    
    // MARK: - Price Filter Tests
    
    func testApplyPriceRangeFilter() throws {
        let filters = PropertyFilters(priceMin: 400000, priceMax: 600000)
        let result = try filterService.applyFilters(testProperties, filters: filters)
        
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, "1")
        XCTAssertEqual(result.first?.price, 500000)
    }
    
    func testApplyMinPriceFilter() throws {
        let filters = PropertyFilters(priceMin: 500000)
        let result = try filterService.applyFilters(testProperties, filters: filters)
        
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.allSatisfy { $0.price >= 500000 })
    }
    
    func testApplyMaxPriceFilter() throws {
        let filters = PropertyFilters(priceMax: 500000)
        let result = try filterService.applyFilters(testProperties, filters: filters)
        
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.allSatisfy { $0.price <= 500000 })
    }
    
    // MARK: - Property Type Filter Tests
    
    func testApplyPropertyTypeFilter() throws {
        let filters = PropertyFilters(propertyTypes: [.house, .condo])
        let result = try filterService.applyFilters(testProperties, filters: filters)
        
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.allSatisfy { $0.propertyType == .house || $0.propertyType == .condo })
    }
    
    func testApplySinglePropertyTypeFilter() throws {
        let filters = PropertyFilters(propertyTypes: [.apartment])
        let result = try filterService.applyFilters(testProperties, filters: filters)
        
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.propertyType, .apartment)
    }
    
    // MARK: - Location Radius Filter Tests
    
    func testApplyLocationRadiusFilter() throws {
        // Center on San Francisco, 5 mile radius
        let center = Coordinate(latitude: 37.7749, longitude: -122.4194)
        let locationRadius = LocationRadius(center: center, radiusInMiles: 5.0)
        let filters = PropertyFilters(locationRadius: locationRadius)
        
        let result = try filterService.applyFilters(testProperties, filters: filters)
        
        // Should include properties 1 and 2 (both in SF), but not 3 (Oakland)
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.contains { $0.id == "1" })
        XCTAssertTrue(result.contains { $0.id == "2" })
    }
    
    func testApplyLargeLocationRadiusFilter() throws {
        // Center on San Francisco, 20 mile radius (should include Oakland)
        let center = Coordinate(latitude: 37.7749, longitude: -122.4194)
        let locationRadius = LocationRadius(center: center, radiusInMiles: 20.0)
        let filters = PropertyFilters(locationRadius: locationRadius)
        
        let result = try filterService.applyFilters(testProperties, filters: filters)
        
        // Should include all properties
        XCTAssertEqual(result.count, 3)
    }
    
    // MARK: - Bedrooms Filter Tests
    
    func testApplyMinBedroomsFilter() throws {
        let filters = PropertyFilters(minBedrooms: 2)
        let result = try filterService.applyFilters(testProperties, filters: filters)
        
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.allSatisfy { ($0.specifications.bedrooms ?? 0) >= 2 })
    }
    
    // MARK: - Bathrooms Filter Tests
    
    func testApplyMinBathroomsFilter() throws {
        let filters = PropertyFilters(minBathrooms: 1.5)
        let result = try filterService.applyFilters(testProperties, filters: filters)
        
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.allSatisfy { ($0.specifications.bathrooms ?? 0) >= 1.5 })
    }
    
    // MARK: - Source Filter Tests
    
    func testApplySourceFilter() throws {
        let filters = PropertyFilters(sources: [.userGenerated])
        let result = try filterService.applyFilters(testProperties, filters: filters)
        
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.allSatisfy { $0.source == .userGenerated })
    }
    
    // MARK: - Seller ID Filter Tests
    
    func testApplySellerIdFilter() throws {
        let filters = PropertyFilters(sellerId: "seller1")
        let result = try filterService.applyFilters(testProperties, filters: filters)
        
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.allSatisfy { $0.sellerId == "seller1" })
    }
    
    // MARK: - Multiple Filter Tests (AND Logic)
    
    func testApplyMultipleFilters() throws {
        // Combine price, type, and bedrooms filters
        let filters = PropertyFilters(
            priceMin: 400000,
            priceMax: 600000,
            propertyTypes: [.house],
            minBedrooms: 3
        )
        let result = try filterService.applyFilters(testProperties, filters: filters)
        
        // Should only match property 1
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, "1")
    }
    
    func testApplyMultipleFiltersNoMatch() throws {
        // Filters that don't match any property
        let filters = PropertyFilters(
            priceMin: 1000000,
            propertyTypes: [.commercial]
        )
        let result = try filterService.applyFilters(testProperties, filters: filters)
        
        XCTAssertEqual(result.count, 0)
    }
    
    func testApplyAllFilters() throws {
        // Apply all possible filters
        let center = Coordinate(latitude: 37.7749, longitude: -122.4194)
        let locationRadius = LocationRadius(center: center, radiusInMiles: 5.0)
        
        let filters = PropertyFilters(
            priceMin: 400000,
            priceMax: 600000,
            propertyTypes: [.house],
            locationRadius: locationRadius,
            minBedrooms: 3,
            minBathrooms: 2.0,
            sources: [.userGenerated],
            sellerId: "seller1"
        )
        let result = try filterService.applyFilters(testProperties, filters: filters)
        
        // Should only match property 1
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, "1")
    }
    
    // MARK: - Validation Tests
    
    func testApplyFiltersWithInvalidFiltersThrowsError() {
        let invalidFilters = PropertyFilters(priceMin: 600000, priceMax: 400000)
        
        XCTAssertThrowsError(try filterService.applyFilters(testProperties, filters: invalidFilters))
    }
    
    // MARK: - Edge Cases
    
    func testApplyFiltersToEmptyArray() throws {
        let filters = PropertyFilters(priceMin: 400000)
        let result = try filterService.applyFilters([], filters: filters)
        
        XCTAssertEqual(result.count, 0)
    }
    
    func testPropertiesWithoutSpecificationsAreFilteredOut() throws {
        // Add a property without bedroom/bathroom specs
        let propertyWithoutSpecs = Property(
            id: "4",
            address: Address(street: "999 Test St", city: "Test City", province: "ON", postalCode: "A1A 1A1", country: "Canada"),
            price: 400000,
            currency: "CAD",
            propertyType: .house,
            description: "Test property",
            specifications: PropertySpecifications(), // No bedrooms/bathrooms
            location: Coordinate(latitude: 37.7749, longitude: -122.4194),
            source: .userGenerated,
            status: .active
        )
        
        let propertiesWithMissingSpecs = testProperties + [propertyWithoutSpecs]
        
        // Filter by minimum bedrooms
        let filters = PropertyFilters(minBedrooms: 1)
        let result = try filterService.applyFilters(propertiesWithMissingSpecs, filters: filters)
        
        // Should not include property 4 (no bedroom info)
        XCTAssertEqual(result.count, 3)
        XCTAssertFalse(result.contains { $0.id == "4" })
    }
}
