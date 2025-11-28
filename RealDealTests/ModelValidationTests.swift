import XCTest
@testable import RealDeal

final class ModelValidationTests: XCTestCase {
    
    // MARK: - Property Validation Tests
    
    func testValidPropertyPassesValidation() throws {
        let property = Property(
            address: Address(
                street: "123 Main St",
                city: "San Francisco",
                state: "CA",
                zipCode: "94102",
                country: "USA"
            ),
            price: 500000,
            propertyType: .house,
            description: "Beautiful home",
            location: Coordinate(latitude: 37.7749, longitude: -122.4194)
        )
        
        XCTAssertNoThrow(try property.validate())
    }
    
    func testPropertyWithInvalidPriceThrowsError() throws {
        let property = Property(
            address: Address(
                street: "123 Main St",
                city: "San Francisco",
                state: "CA",
                zipCode: "94102",
                country: "USA"
            ),
            price: -100,
            propertyType: .house,
            description: "Beautiful home",
            location: Coordinate(latitude: 37.7749, longitude: -122.4194)
        )
        
        XCTAssertThrowsError(try property.validate())
    }
    
    func testPropertyWithEmptyDescriptionThrowsError() throws {
        let property = Property(
            address: Address(
                street: "123 Main St",
                city: "San Francisco",
                state: "CA",
                zipCode: "94102",
                country: "USA"
            ),
            price: 500000,
            propertyType: .house,
            description: "   ",
            location: Coordinate(latitude: 37.7749, longitude: -122.4194)
        )
        
        XCTAssertThrowsError(try property.validate())
    }
    
    func testPropertyWithInvalidZipCodeThrowsError() throws {
        let property = Property(
            address: Address(
                street: "123 Main St",
                city: "San Francisco",
                state: "CA",
                zipCode: "invalid",
                country: "USA"
            ),
            price: 500000,
            propertyType: .house,
            description: "Beautiful home",
            location: Coordinate(latitude: 37.7749, longitude: -122.4194)
        )
        
        XCTAssertThrowsError(try property.validate())
    }
    
    func testPropertyWithInvalidCoordinatesThrowsError() throws {
        let property = Property(
            address: Address(
                street: "123 Main St",
                city: "San Francisco",
                state: "CA",
                zipCode: "94102",
                country: "USA"
            ),
            price: 500000,
            propertyType: .house,
            description: "Beautiful home",
            location: Coordinate(latitude: 200, longitude: -122.4194)
        )
        
        XCTAssertThrowsError(try property.validate())
    }
    
    // MARK: - UserProfile Validation Tests
    
    func testValidUserProfilePassesValidation() throws {
        let profile = UserProfile(
            name: "John Doe",
            email: "john@example.com",
            phoneNumber: "555-1234"
        )
        
        XCTAssertNoThrow(try profile.validate())
    }
    
    func testUserProfileWithInvalidEmailThrowsError() throws {
        let profile = UserProfile(
            name: "John Doe",
            email: "invalid-email",
            phoneNumber: "555-1234"
        )
        
        XCTAssertThrowsError(try profile.validate())
    }
    
    func testUserProfileWithEmptyNameThrowsError() throws {
        let profile = UserProfile(
            name: "   ",
            email: "john@example.com"
        )
        
        XCTAssertThrowsError(try profile.validate())
    }
    
    // MARK: - Password Validation Tests
    
    func testValidPasswordPassesValidation() throws {
        XCTAssertNoThrow(try PasswordValidator.validate("Password123"))
    }
    
    func testWeakPasswordThrowsError() throws {
        XCTAssertThrowsError(try PasswordValidator.validate("weak"))
    }
    
    func testPasswordWithoutUppercaseThrowsError() throws {
        XCTAssertThrowsError(try PasswordValidator.validate("password123"))
    }
    
    func testPasswordWithoutDigitThrowsError() throws {
        XCTAssertThrowsError(try PasswordValidator.validate("Password"))
    }
    
    // MARK: - PropertyFilters Validation Tests
    
    func testValidPropertyFiltersPassValidation() throws {
        let filters = PropertyFilters(
            priceMin: 100000,
            priceMax: 500000,
            minBedrooms: 2
        )
        
        XCTAssertNoThrow(try filters.validate())
    }
    
    func testPropertyFiltersWithInvalidPriceRangeThrowsError() throws {
        let filters = PropertyFilters(
            priceMin: 500000,
            priceMax: 100000
        )
        
        XCTAssertThrowsError(try filters.validate())
    }
    
    func testPropertyFiltersWithNegativePriceThrowsError() throws {
        let filters = PropertyFilters(
            priceMin: -100
        )
        
        XCTAssertThrowsError(try filters.validate())
    }
    
    // MARK: - Favorite Validation Tests
    
    func testValidFavoritePassesValidation() throws {
        let favorite = Favorite(
            userId: "user123",
            propertyId: "prop456"
        )
        
        XCTAssertNoThrow(try favorite.validate())
    }
    
    func testFavoriteWithEmptyUserIdThrowsError() throws {
        let favorite = Favorite(
            userId: "   ",
            propertyId: "prop456"
        )
        
        XCTAssertThrowsError(try favorite.validate())
    }
    
    func testFavoriteWithEmptyPropertyIdThrowsError() throws {
        let favorite = Favorite(
            userId: "user123",
            propertyId: "   "
        )
        
        XCTAssertThrowsError(try favorite.validate())
    }
}
