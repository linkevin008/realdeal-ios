import XCTest
@testable import RealDeal

final class ModelValidationTests: XCTestCase {
    
    // MARK: - Property Validation Tests
    
    func testValidPropertyPassesValidation() throws {
        let property = Property(
            address: Address(
                street: "123 Main St",
                city: "San Francisco",
                province: "ON",
                postalCode: "M5H 1J9",
                country: "Canada"
            ),
            price: 500000,
            currency: "CAD",
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
                province: "ON",
                postalCode: "M5H 1J9",
                country: "Canada"
            ),
            price: -100,
            currency: "CAD",
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
                province: "ON",
                postalCode: "M5H 1J9",
                country: "Canada"
            ),
            price: 500000,
            currency: "CAD",
            propertyType: .house,
            description: "   ",
            location: Coordinate(latitude: 37.7749, longitude: -122.4194)
        )
        
        XCTAssertThrowsError(try property.validate())
    }
    
    func testPropertyWithInvalidPostalCodeThrowsError() throws {
        let property = Property(
            address: Address(
                street: "123 Main St",
                city: "San Francisco",
                province: "ON",
                postalCode: "invalid",
                country: "USA"
            ),
            price: 500000,
            currency: "CAD",
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
                province: "ON",
                postalCode: "M5H 1J9",
                country: "Canada"
            ),
            price: 500000,
            currency: "CAD",
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

    // MARK: - Address / Province Tests

    func testAddressWithValidCanadianPostalCodePassesValidation() throws {
        // Given: a standard Canadian postal code (e.g. Toronto downtown)
        let address = Address(
            street: "123 King Street West",
            city: "Toronto",
            province: "ON",
            postalCode: "M5V 3A8",
            country: "Canada"
        )

        // Then: validation passes
        XCTAssertNoThrow(try address.validate(), "A valid Canadian postal code should pass validation")
    }

    func testAddressWithUKPostalCodePassesValidation() throws {
        // Given: a UK-format postal code (international listing)
        let address = Address(
            street: "10 Downing Street",
            city: "London",
            province: "England",
            postalCode: "SW1A 2AA",
            country: "UK"
        )

        // Then: validation passes (international format is supported)
        XCTAssertNoThrow(try address.validate(), "A valid UK postal code should pass validation in international mode")
    }

    func testAddressWithEmptyProvinceThrowsValidationError() throws {
        // Given: an address missing a province
        let address = Address(
            street: "55 Water Street",
            city: "Vancouver",
            province: "   ",
            postalCode: "V6B 1A1",
            country: "Canada"
        )

        // Then: validation throws an error about the missing province
        XCTAssertThrowsError(try address.validate()) { error in
            if let validationError = error as? ValidationError {
                switch validationError {
                case .missingRequiredField(let field):
                    XCTAssertTrue(field.contains("province"),
                        "Error should identify 'province' as the missing field, got: \(field)")
                default:
                    XCTFail("Expected missingRequiredField error, got: \(validationError)")
                }
            } else {
                XCTFail("Expected a ValidationError, got: \(error)")
            }
        }
    }

    func testAddressUsesProvinceFieldNotStateField() throws {
        // Given: addresses from the mock CREA data all use `province`, not `state`
        let onAddress = Address(
            street: "88 Scott Street",
            city: "Toronto",
            province: "ON",
            postalCode: "M5E 0A9",
            country: "Canada"
        )
        let bcAddress = Address(
            street: "1480 Howe Street",
            city: "Vancouver",
            province: "BC",
            postalCode: "V6Z 1R8",
            country: "Canada"
        )

        // Then: the `province` property correctly stores and returns the value
        XCTAssertEqual(onAddress.province, "ON", "Address.province should hold the Canadian province code")
        XCTAssertEqual(bcAddress.province, "BC")

        // And both addresses pass validation (confirming province is used, not state)
        XCTAssertNoThrow(try onAddress.validate())
        XCTAssertNoThrow(try bcAddress.validate())
    }

    func testAddressWithInvalidPostalCodeThrowsError() throws {
        // Given: a postal code that does not match the allowed pattern
        let address = Address(
            street: "1 Test Lane",
            city: "Calgary",
            province: "AB",
            postalCode: "!!!",
            country: "Canada"
        )

        // Then: validation throws an error
        XCTAssertThrowsError(try address.validate(), "An invalid postal code should fail validation")
    }
}
