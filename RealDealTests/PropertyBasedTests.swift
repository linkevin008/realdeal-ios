import XCTest
import SwiftCheck
#if canImport(UIKit)
import UIKit
#endif
@testable import RealDeal

final class PropertyBasedTests: XCTestCase {
    
    // MARK: - Property-Based Test for Property Creation Validation
    
    /// Feature: real-estate-listings, Property 3: Invalid property data is rejected
    /// Validates: Requirements 1.3, 1.5
    func testInvalidPropertyDataIsRejected() {
        // Test that properties with invalid data are rejected during validation
        property("Invalid property data should be rejected") <- forAll { (seed: Int) in
            let invalidProperty = invalidPropertyGen().resize(seed).generate
            do {
                try invalidProperty.validate()
                return false // Should have thrown an error
            } catch {
                return true // Correctly rejected invalid data
            }
        }
    }
    
    // MARK: - Property-Based Test for Property Persistence Round-Trip
    
    /// Feature: real-estate-listings, Property 4: Property listing persistence round-trip
    /// Validates: Requirements 1.4
    func testPropertyPersistenceRoundTrip() {
        // Test that saving a property and retrieving it returns equivalent data
        property("Property persistence round-trip preserves all data") <- forAll { (seed: Int) in
            let testProperty = validPropertyGen().resize(seed).generate
            let expectation = XCTestExpectation(description: "Property persistence round-trip")
            var result = false
            
            Task {
                do {
                    // Use in-memory persistence controller for testing
                    let testPersistence = PersistenceController(inMemory: true)
                    let localDataSource = LocalDataSource(persistenceController: testPersistence)
                    
                    // Save the property
                    try await localDataSource.saveProperty(testProperty)
                    
                    // Retrieve the property
                    guard let retrievedProperty = try await localDataSource.getProperty(id: testProperty.id) else {
                        result = false
                        expectation.fulfill()
                        return
                    }
                    
                    // Verify all fields match
                    result = self.propertiesAreEquivalent(testProperty, retrievedProperty)
                    expectation.fulfill()
                } catch {
                    result = false
                    expectation.fulfill()
                }
            }
            
            self.wait(for: [expectation], timeout: 5.0)
            return result
        }
    }
    
    // MARK: - Property-Based Test for Profile Persistence Round-Trip
    
    /// Feature: real-estate-listings, Property 22: Profile creation persistence round-trip
    /// Validates: Requirements 7.1
    func testProfilePersistenceRoundTrip() {
        // Test that saving a profile and retrieving it returns equivalent data
        property("Profile persistence round-trip preserves all data") <- forAll { (seed: Int) in
            let testProfile = validUserProfileGen().resize(seed).generate
            let expectation = XCTestExpectation(description: "Profile persistence round-trip")
            var result = false
            
            Task {
                do {
                    // Use in-memory persistence controller for testing
                    let testPersistence = PersistenceController(inMemory: true)
                    let localDataSource = LocalDataSource(persistenceController: testPersistence)
                    
                    // Save the profile
                    try await localDataSource.saveUserProfile(testProfile)
                    
                    // Retrieve the profile
                    guard let retrievedProfile = try await localDataSource.getUserProfile(id: testProfile.id) else {
                        result = false
                        expectation.fulfill()
                        return
                    }
                    
                    // Verify all fields match
                    result = self.profilesAreEquivalent(testProfile, retrievedProfile)
                    expectation.fulfill()
                } catch {
                    result = false
                    expectation.fulfill()
                }
            }
            
            self.wait(for: [expectation], timeout: 5.0)
            return result
        }
    }
    
    // MARK: - Property-Based Test for Property Update Persistence Round-Trip
    
    /// Feature: real-estate-listings, Property 6: Property update persistence round-trip
    /// Validates: Requirements 2.3
    func testPropertyUpdatePersistenceRoundTrip() {
        // Test that updating a property and retrieving it reflects all changes
        property("Property update persistence round-trip preserves all changes") <- forAll(Gen.fromElements(in: 0...100)) { (seed: Int) in
            let originalProperty = validPropertyGen().resize(seed).generate
            let updatedProperty = self.createUpdatedProperty(from: originalProperty, seed: seed)
            let expectation = XCTestExpectation(description: "Property update persistence round-trip")
            var result = false
            
            Task {
                do {
                    // Use in-memory persistence controller for testing
                    let testPersistence = PersistenceController(inMemory: true)
                    let localDataSource = LocalDataSource(persistenceController: testPersistence)
                    
                    // Save the original property
                    try await localDataSource.saveProperty(originalProperty)
                    
                    // Update the property with new values
                    try await localDataSource.saveProperty(updatedProperty)
                    
                    // Retrieve the property
                    guard let retrievedProperty = try await localDataSource.getProperty(id: originalProperty.id) else {
                        result = false
                        expectation.fulfill()
                        return
                    }
                    
                    // Verify the retrieved property matches the updated version, not the original
                    result = self.propertiesAreEquivalent(updatedProperty, retrievedProperty)
                    expectation.fulfill()
                } catch {
                    result = false
                    expectation.fulfill()
                }
            }
            
            self.wait(for: [expectation], timeout: 5.0)
            return result
        }
    }
    
    // MARK: - Property-Based Test for Profile Update Persistence Round-Trip
    
    /// Feature: real-estate-listings, Property 23: Profile update persistence round-trip
    /// Validates: Requirements 7.2
    func testProfileUpdatePersistenceRoundTrip() {
        // Test that updating a profile and retrieving it reflects all changes
        property("Profile update persistence round-trip preserves all changes") <- forAll(Gen.fromElements(in: 0...100)) { (seed: Int) in
            let originalProfile = validUserProfileGen().resize(seed).generate
            let updatedProfile = self.createUpdatedProfile(from: originalProfile, seed: seed)
            let expectation = XCTestExpectation(description: "Profile update persistence round-trip")
            var result = false
            
            Task {
                do {
                    // Use in-memory persistence controller for testing
                    let testPersistence = PersistenceController(inMemory: true)
                    let localDataSource = LocalDataSource(persistenceController: testPersistence)
                    
                    // Save the original profile
                    try await localDataSource.saveUserProfile(originalProfile)
                    
                    // Update the profile with new values
                    try await localDataSource.saveUserProfile(updatedProfile)
                    
                    // Retrieve the profile
                    guard let retrievedProfile = try await localDataSource.getUserProfile(id: originalProfile.id) else {
                        result = false
                        expectation.fulfill()
                        return
                    }
                    
                    // Verify the retrieved profile matches the updated version, not the original
                    result = self.profilesAreEquivalent(updatedProfile, retrievedProfile)
                    expectation.fulfill()
                } catch {
                    result = false
                    expectation.fulfill()
                }
            }
            
            self.wait(for: [expectation], timeout: 5.0)
            return result
        }
    }
    
    // MARK: - Property-Based Test for Profile Photo Validation
    
    /// Feature: real-estate-listings, Property 25: Profile photo validation
    /// Validates: Requirements 7.4
    func testProfilePhotoValidation() {
        // Test that invalid profile photos are rejected during validation
        property("Invalid profile photos should be rejected") <- forAll { (seed: Int) in
            let invalidImageData = invalidImageDataGen().resize(seed).generate
            do {
                try ProfilePhotoValidator.validate(invalidImageData)
                return false // Should have thrown an error
            } catch {
                return true // Correctly rejected invalid image
            }
        }
        
        // Test that valid profile photos are accepted
        property("Valid profile photos should be accepted") <- forAll { (seed: Int) in
            let validImageData = validImageDataGen().resize(seed).generate
            do {
                try ProfilePhotoValidator.validate(validImageData)
                return true // Correctly accepted valid image
            } catch {
                return false // Should not have thrown an error
            }
        }
    }
    
    // MARK: - Property-Based Test for Offline Cache Accessibility
    
    /// Feature: real-estate-listings, Property 33: Offline cache accessibility
    /// Validates: Requirements 10.3
    func testOfflineCacheAccessibility() {
        // Test that previously loaded properties remain accessible from cache when offline
        // This tests the core cache functionality that enables offline access
        property("Previously loaded properties should be accessible from cache when offline") <- forAll(Gen.fromElements(in: 1...10)) { (propertyCount: Int) in
            let testProperties = (0..<propertyCount).map { _ in validPropertyGen().generate }
            let expectation = XCTestExpectation(description: "Offline cache accessibility")
            var result = false
            
            Task {
                do {
                    // Use in-memory persistence controller for testing
                    let testPersistence = PersistenceController(inMemory: true)
                    let localDataSource = LocalDataSource(persistenceController: testPersistence)
                    
                    // Step 1: Save properties to cache (simulating what happens when online)
                    try await localDataSource.saveProperties(testProperties)
                    
                    // Step 2: Retrieve properties from cache (simulating offline access)
                    // This is what the repository does when offline - it falls back to local cache
                    let cachedProperties = try await localDataSource.fetchProperties(filters: nil)
                    
                    // Step 3: Verify all previously loaded properties are still accessible
                    guard cachedProperties.count == propertyCount else {
                        result = false
                        expectation.fulfill()
                        return
                    }
                    
                    // Step 4: Verify each property is equivalent to what was saved
                    let sortedOriginal = testProperties.sorted(by: { $0.id < $1.id })
                    let sortedCached = cachedProperties.sorted(by: { $0.id < $1.id })
                    
                    result = zip(sortedOriginal, sortedCached).allSatisfy { original, cached in
                        self.propertiesAreEquivalent(original, cached)
                    }
                    
                    expectation.fulfill()
                } catch {
                    result = false
                    expectation.fulfill()
                }
            }
            
            self.wait(for: [expectation], timeout: 10.0)
            return result
        }
    }
}

// MARK: - Helper Methods

extension PropertyBasedTests {
    /// Create an updated version of a profile with modified fields
    func createUpdatedProfile(from original: UserProfile, seed: Int) -> UserProfile {
        // Generate new values for various fields
        let gen = Gen.compose { c in
            // Update name
            let newName = c.generate(using: Gen.fromElements(of: [
                "Updated Name", "New User", "Modified Profile", "Changed Name", "Test User Updated"
            ]))
            
            // Update phone number
            let newPhoneNumber = c.generate(using: Gen.fromElements(of: [
                nil, "555-9999", "555-8888", "(555) 777-6666", "+1-555-111-2222"
            ]))
            
            // Update profile photo URL
            let newPhotoURL = c.generate(using: Gen.fromElements(of: [
                nil,
                URL(string: "https://example.com/updated-photo.jpg"),
                URL(string: "https://example.com/new-avatar.png"),
                URL(string: "https://example.com/profile-pic.jpeg")
            ]))
            
            // Update role
            let newRole = c.generate(using: Gen.fromElements(of: [UserRole.buyer, .seller, .both]))
            
            // Update visibility settings
            let newVisibility = c.generate(using: validProfileVisibilityGen())
            
            // Create updated profile with same ID but new values
            return UserProfile(
                id: original.id, // Keep same ID
                name: newName,
                email: original.email, // Keep email same (typically immutable)
                phoneNumber: newPhoneNumber,
                profilePhotoURL: newPhotoURL,
                role: newRole,
                visibilitySettings: newVisibility,
                createdAt: original.createdAt // Keep original creation date
            )
        }
        
        return gen.resize(seed).generate
    }
    
    /// Create an updated version of a property with modified fields
    func createUpdatedProperty(from original: RealDeal.Property, seed: Int) -> RealDeal.Property {
        // Generate new values for various fields
        let gen = Gen.compose { c in
            // Update price
            let newPrice = Decimal(c.generate(using: Gen.fromElements(in: 50000...5000000)))
            
            // Update description
            let newDescription = c.generate(using: validDescriptionGen())
            
            // Update status
            let newStatus = c.generate(using: Gen.fromElements(of: [PropertyStatus.active, .pending, .sold]))
            
            // Update specifications
            let newSpecs = c.generate(using: validSpecificationsGen())
            
            // Update images
            let newImages = c.generate(using: validImagesGen())
            
            // Create updated property with same ID but new values
            return RealDeal.Property(
                id: original.id, // Keep same ID
                address: original.address, // Keep address same for simplicity
                price: newPrice,
                propertyType: original.propertyType, // Keep type same
                description: newDescription,
                specifications: newSpecs,
                images: newImages,
                location: original.location, // Keep location same
                source: original.source,
                sellerId: original.sellerId,
                status: newStatus,
                createdAt: original.createdAt, // Keep original creation date
                updatedAt: Date() // Update timestamp
            )
        }
        
        return gen.resize(seed).generate
    }
    
    /// Compare two user profiles for equivalence
    func profilesAreEquivalent(_ p1: UserProfile, _ p2: UserProfile) -> Bool {
        // Compare basic fields
        guard p1.id == p2.id,
              p1.name == p2.name,
              p1.email == p2.email,
              p1.phoneNumber == p2.phoneNumber,
              p1.profilePhotoURL == p2.profilePhotoURL,
              p1.role == p2.role else {
            return false
        }
        
        // Compare visibility settings
        guard p1.visibilitySettings == p2.visibilitySettings else {
            return false
        }
        
        // Compare dates (within 1 second tolerance for Core Data precision)
        guard abs(p1.createdAt.timeIntervalSince(p2.createdAt)) < 1.0 else {
            return false
        }
        
        return true
    }
    
    /// Compare two properties for equivalence (accounting for floating point precision)
    func propertiesAreEquivalent(_ p1: RealDeal.Property, _ p2: RealDeal.Property) -> Bool {
        // Compare basic fields
        guard p1.id == p2.id,
              p1.address == p2.address,
              p1.price == p2.price,
              p1.propertyType == p2.propertyType,
              p1.description == p2.description,
              p1.location == p2.location,
              p1.source == p2.source,
              p1.sellerId == p2.sellerId,
              p1.status == p2.status else {
            return false
        }
        
        // Compare specifications (accounting for optional values)
        guard p1.specifications.bedrooms == p2.specifications.bedrooms,
              p1.specifications.squareFeet == p2.specifications.squareFeet,
              p1.specifications.yearBuilt == p2.specifications.yearBuilt else {
            return false
        }
        
        // Compare bathrooms with tolerance for floating point
        if let b1 = p1.specifications.bathrooms, let b2 = p2.specifications.bathrooms {
            guard abs(b1 - b2) < 0.001 else { return false }
        } else if p1.specifications.bathrooms != nil || p2.specifications.bathrooms != nil {
            return false
        }
        
        // Compare lot size with tolerance for floating point
        if let l1 = p1.specifications.lotSize, let l2 = p2.specifications.lotSize {
            guard abs(l1 - l2) < 0.001 else { return false }
        } else if p1.specifications.lotSize != nil || p2.specifications.lotSize != nil {
            return false
        }
        
        // Compare images
        guard p1.images.count == p2.images.count else { return false }
        for (img1, img2) in zip(p1.images.sorted(by: { $0.order < $1.order }),
                                 p2.images.sorted(by: { $0.order < $1.order })) {
            guard img1.id == img2.id,
                  img1.url == img2.url,
                  img1.order == img2.order else {
                return false
            }
        }
        
        // Compare dates (within 1 second tolerance for Core Data precision)
        guard abs(p1.createdAt.timeIntervalSince(p2.createdAt)) < 1.0,
              abs(p1.updatedAt.timeIntervalSince(p2.updatedAt)) < 1.0 else {
            return false
        }
        
        return true
    }
}

// MARK: - Generators for Valid Property Data

/// Generator for valid properties (properties that should pass validation and persistence)
func validPropertyGen() -> Gen<RealDeal.Property> {
    Gen.compose { c in
        let address = validAddressGen().generate
        let price = Decimal(c.generate(using: Gen.fromElements(in: 50000...5000000)))
        let propertyType = c.generate(using: Gen.fromElements(of: PropertyType.allCases))
        let description = c.generate(using: validDescriptionGen())
        let specifications = c.generate(using: validSpecificationsGen())
        let images = c.generate(using: validImagesGen())
        let location = validCoordinateGen().generate
        let source = c.generate(using: Gen.fromElements(of: [ListingSource.userGenerated, .mls, .zillow, .realtor]))
        let sellerId = c.generate(using: Gen.fromElements(of: [nil, "seller-123", "seller-456", "seller-789"]))
        let status = c.generate(using: Gen.fromElements(of: [PropertyStatus.active, .pending, .sold]))
        
        return RealDeal.Property(
            address: address,
            price: price,
            propertyType: propertyType,
            description: description,
            specifications: specifications,
            images: images,
            location: location,
            source: source,
            sellerId: sellerId,
            status: status
        )
    }
}

/// Generator for valid property descriptions
func validDescriptionGen() -> Gen<String> {
    Gen.fromElements(of: [
        "Beautiful family home with spacious backyard",
        "Modern apartment in downtown area with great amenities",
        "Charming condo with stunning city views",
        "Prime commercial property in business district",
        "Vacant land ready for development",
        "Luxury estate with pool and tennis court",
        "Cozy starter home perfect for first-time buyers",
        "Investment property with excellent rental history"
    ])
}

/// Generator for valid property specifications
func validSpecificationsGen() -> Gen<PropertySpecifications> {
    Gen.compose { c in
        let bedrooms = c.generate(using: Gen.fromElements(of: [nil, 1, 2, 3, 4, 5, 6]))
        let bathrooms = c.generate(using: Gen.fromElements(of: [nil, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0]))
        let squareFeet = c.generate(using: Gen.fromElements(of: [nil, 800, 1200, 1500, 2000, 2500, 3000, 4000]))
        let lotSize = c.generate(using: Gen.fromElements(of: [nil, 2000.0, 5000.0, 7500.0, 10000.0, 20000.0]))
        let yearBuilt = c.generate(using: Gen.fromElements(of: [nil, 1950, 1970, 1985, 1995, 2000, 2010, 2020]))
        
        return PropertySpecifications(
            bedrooms: bedrooms,
            bathrooms: bathrooms,
            squareFeet: squareFeet,
            lotSize: lotSize,
            yearBuilt: yearBuilt
        )
    }
}

/// Generator for valid property images
func validImagesGen() -> Gen<[PropertyImage]> {
    Gen.compose { c in
        let count = c.generate(using: Gen.fromElements(in: 0...5))
        var images: [PropertyImage] = []
        
        for i in 0..<count {
            let url = URL(string: "https://example.com/image\(i).jpg")!
            images.append(PropertyImage(url: url, order: i))
        }
        
        return images
    }
}

// MARK: - Generators for Invalid Property Data

/// Generator for invalid properties (properties that should fail validation)
func invalidPropertyGen() -> Gen<RealDeal.Property> {
    Gen.one(of: [
        invalidPricePropertyGen(),
        emptyDescriptionPropertyGen(),
        invalidAddressPropertyGen(),
        invalidCoordinatesPropertyGen(),
        invalidSpecificationsPropertyGen()
    ])
}

/// Generator for properties with invalid (non-positive) prices
func invalidPricePropertyGen() -> Gen<RealDeal.Property> {
    Gen.compose { c in
        let address = validAddressGen().generate
        let price = Decimal(c.generate(using: Gen.fromElements(in: -1000...0)))
        let location = validCoordinateGen().generate
        
        return RealDeal.Property(
            address: address,
            price: price,
            propertyType: .house,
            description: "Valid description",
            location: location
        )
    }
}

/// Generator for properties with empty or whitespace-only descriptions
func emptyDescriptionPropertyGen() -> Gen<RealDeal.Property> {
    Gen.compose { c in
        let address = validAddressGen().generate
        let price = Decimal(c.generate(using: Gen.fromElements(in: 100000...1000000)))
        let location = validCoordinateGen().generate
        let emptyDesc = c.generate(using: Gen.fromElements(of: ["", "   ", "\t", "\n", "  \t\n  "]))
        
        return RealDeal.Property(
            address: address,
            price: price,
            propertyType: .apartment,
            description: emptyDesc,
            location: location
        )
    }
}

/// Generator for properties with invalid addresses
func invalidAddressPropertyGen() -> Gen<RealDeal.Property> {
    Gen.compose { c in
        let invalidAddress = c.generate(using: invalidAddressGen())
        let price = Decimal(c.generate(using: Gen.fromElements(in: 100000...1000000)))
        let location = validCoordinateGen().generate
        
        return RealDeal.Property(
            address: invalidAddress,
            price: price,
            propertyType: .condo,
            description: "Valid description",
            location: location
        )
    }
}

/// Generator for properties with invalid coordinates
func invalidCoordinatesPropertyGen() -> Gen<RealDeal.Property> {
    Gen.compose { c in
        let address = validAddressGen().generate
        let price = Decimal(c.generate(using: Gen.fromElements(in: 100000...1000000)))
        let invalidCoord = c.generate(using: invalidCoordinateGen())
        
        return RealDeal.Property(
            address: address,
            price: price,
            propertyType: .land,
            description: "Valid description",
            location: invalidCoord
        )
    }
}

/// Generator for properties with invalid specifications
func invalidSpecificationsPropertyGen() -> Gen<RealDeal.Property> {
    Gen.compose { c in
        let address = validAddressGen().generate
        let price = Decimal(c.generate(using: Gen.fromElements(in: 100000...1000000)))
        let location = validCoordinateGen().generate
        let invalidSpecs = c.generate(using: invalidSpecificationsGen())
        
        return RealDeal.Property(
            address: address,
            price: price,
            propertyType: .house,
            description: "Valid description",
            specifications: invalidSpecs,
            location: location
        )
    }
}

// MARK: - Invalid Component Generators

/// Generator for invalid addresses (missing required fields or invalid formats)
func invalidAddressGen() -> Gen<Address> {
    Gen.one(of: [
        // Empty street
        Gen.pure(Address(street: "", city: "San Francisco", state: "CA", zipCode: "94102", country: "USA")),
        // Empty city
        Gen.pure(Address(street: "123 Main St", city: "", state: "CA", zipCode: "94102", country: "USA")),
        // Empty state
        Gen.pure(Address(street: "123 Main St", city: "San Francisco", state: "", zipCode: "94102", country: "USA")),
        // Invalid zip code format
        Gen.pure(Address(street: "123 Main St", city: "San Francisco", state: "CA", zipCode: "invalid", country: "USA")),
        Gen.pure(Address(street: "123 Main St", city: "San Francisco", state: "CA", zipCode: "123", country: "USA")),
        Gen.pure(Address(street: "123 Main St", city: "San Francisco", state: "CA", zipCode: "abcde", country: "USA")),
        // Empty country
        Gen.pure(Address(street: "123 Main St", city: "San Francisco", state: "CA", zipCode: "94102", country: ""))
    ])
}

/// Generator for invalid coordinates (out of valid range)
func invalidCoordinateGen() -> Gen<Coordinate> {
    Gen.one(of: [
        // Invalid latitude (> 90)
        Gen.fromElements(in: 91...200).map { Coordinate(latitude: Double($0), longitude: -122.4194) },
        // Invalid latitude (< -90)
        Gen.fromElements(in: -200...(-91)).map { Coordinate(latitude: Double($0), longitude: -122.4194) },
        // Invalid longitude (> 180)
        Gen.fromElements(in: 181...360).map { Coordinate(latitude: 37.7749, longitude: Double($0)) },
        // Invalid longitude (< -180)
        Gen.fromElements(in: -360...(-181)).map { Coordinate(latitude: 37.7749, longitude: Double($0)) }
    ])
}

/// Generator for invalid property specifications
func invalidSpecificationsGen() -> Gen<PropertySpecifications> {
    Gen.one(of: [
        // Negative bedrooms
        Gen.pure(PropertySpecifications(bedrooms: -1, bathrooms: 2, squareFeet: 1500, lotSize: 5000, yearBuilt: 2000)),
        // Negative bathrooms
        Gen.pure(PropertySpecifications(bedrooms: 3, bathrooms: -0.5, squareFeet: 1500, lotSize: 5000, yearBuilt: 2000)),
        // Zero or negative square feet
        Gen.pure(PropertySpecifications(bedrooms: 3, bathrooms: 2, squareFeet: 0, lotSize: 5000, yearBuilt: 2000)),
        Gen.pure(PropertySpecifications(bedrooms: 3, bathrooms: 2, squareFeet: -100, lotSize: 5000, yearBuilt: 2000)),
        // Zero or negative lot size
        Gen.pure(PropertySpecifications(bedrooms: 3, bathrooms: 2, squareFeet: 1500, lotSize: 0, yearBuilt: 2000)),
        Gen.pure(PropertySpecifications(bedrooms: 3, bathrooms: 2, squareFeet: 1500, lotSize: -1000, yearBuilt: 2000)),
        // Invalid year built (too old)
        Gen.pure(PropertySpecifications(bedrooms: 3, bathrooms: 2, squareFeet: 1500, lotSize: 5000, yearBuilt: 1700)),
        // Invalid year built (future)
        Gen.fromElements(in: 2030...2100).map { year in
            PropertySpecifications(bedrooms: 3, bathrooms: 2, squareFeet: 1500, lotSize: 5000, yearBuilt: year)
        }
    ])
}

// MARK: - Valid Component Generators (for creating test data)

/// Generator for valid addresses
func validAddressGen() -> Gen<Address> {
    Gen.compose { c in
        let streets = ["123 Main St", "456 Oak Ave", "789 Pine Rd", "321 Elm Blvd"]
        let cities = ["San Francisco", "Los Angeles", "New York", "Chicago"]
        let states = ["CA", "NY", "IL", "TX"]
        let zipCodes = ["94102", "10001", "60601", "75201", "94102-1234"]
        let countries = ["USA", "United States"]
        
        return Address(
            street: c.generate(using: Gen.fromElements(of: streets)),
            city: c.generate(using: Gen.fromElements(of: cities)),
            state: c.generate(using: Gen.fromElements(of: states)),
            zipCode: c.generate(using: Gen.fromElements(of: zipCodes)),
            country: c.generate(using: Gen.fromElements(of: countries))
        )
    }
}

/// Generator for valid coordinates
func validCoordinateGen() -> Gen<Coordinate> {
    Gen.compose { c in
        let latitude = Double(c.generate(using: Gen.fromElements(in: -90...90)))
        let longitude = Double(c.generate(using: Gen.fromElements(in: -180...180)))
        return Coordinate(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Generators for User Profile Data

/// Generator for valid user profiles
func validUserProfileGen() -> Gen<UserProfile> {
    Gen.compose { c in
        let names = ["John Doe", "Jane Smith", "Bob Johnson", "Alice Williams", "Charlie Brown"]
        let emails = ["john@example.com", "jane@example.com", "bob@example.com", "alice@example.com", "charlie@example.com"]
        let phoneNumbers: [String?] = [nil, "555-0100", "555-0101", "555-0102", "(555) 123-4567", "+1-555-987-6543"]
        let photoURLs: [URL?] = [
            nil,
            URL(string: "https://example.com/photo1.jpg"),
            URL(string: "https://example.com/photo2.png"),
            URL(string: "https://example.com/photo3.jpeg")
        ]
        let roles = [UserRole.buyer, UserRole.seller, UserRole.both]
        
        let name = c.generate(using: Gen.fromElements(of: names))
        let email = c.generate(using: Gen.fromElements(of: emails))
        let phoneNumber = c.generate(using: Gen.fromElements(of: phoneNumbers))
        let profilePhotoURL = c.generate(using: Gen.fromElements(of: photoURLs))
        let role = c.generate(using: Gen.fromElements(of: roles))
        let visibilitySettings = c.generate(using: validProfileVisibilityGen())
        
        return UserProfile(
            name: name,
            email: email,
            phoneNumber: phoneNumber,
            profilePhotoURL: profilePhotoURL,
            role: role,
            visibilitySettings: visibilitySettings
        )
    }
}

/// Generator for valid profile visibility settings
func validProfileVisibilityGen() -> Gen<ProfileVisibility> {
    Gen.compose { c in
        let showEmail = c.generate(using: Gen.fromElements(of: [true, false]))
        let showPhone = c.generate(using: Gen.fromElements(of: [true, false]))
        let showListings = c.generate(using: Gen.fromElements(of: [true, false]))
        
        return ProfileVisibility(
            showEmail: showEmail,
            showPhone: showPhone,
            showListings: showListings
        )
    }
}

// MARK: - Generators for Profile Photo Validation

/// Generator for invalid image data (should fail validation)
func invalidImageDataGen() -> Gen<Data> {
    Gen.one(of: [
        emptyImageDataGen(),
        tooLargeImageDataGen(),
        invalidFormatImageDataGen(),
        corruptedImageDataGen()
    ])
}

/// Generator for empty image data
func emptyImageDataGen() -> Gen<Data> {
    Gen.pure(Data())
}

/// Generator for image data that exceeds size limit (> 5 MB)
func tooLargeImageDataGen() -> Gen<Data> {
    Gen.compose { c in
        let size = c.generate(using: Gen.fromElements(in: (5 * 1024 * 1024 + 1)...(10 * 1024 * 1024)))
        return Data(repeating: 0xFF, count: size)
    }
}

/// Generator for data with invalid image format
func invalidFormatImageDataGen() -> Gen<Data> {
    Gen.one(of: [
        // Plain text data
        Gen.pure("This is not an image".data(using: .utf8)!),
        // Random bytes that don't match any image format
        Gen.compose { c in
            let size = c.generate(using: Gen.fromElements(in: 100...1000))
            var bytes = [UInt8](repeating: 0, count: size)
            for i in 0..<size {
                bytes[i] = UInt8(c.generate(using: Gen.fromElements(in: 0...255)))
            }
            return Data(bytes)
        },
        // PDF signature
        Gen.pure(Data([0x25, 0x50, 0x44, 0x46, 0x2D])),
        // GIF signature (not in allowed formats)
        Gen.pure(Data([0x47, 0x49, 0x46, 0x38, 0x39, 0x61]))
    ])
}

/// Generator for corrupted image data (valid signature but corrupted content)
func corruptedImageDataGen() -> Gen<Data> {
    Gen.one(of: [
        // JPEG signature but truncated/corrupted
        Gen.pure(Data([0xFF, 0xD8, 0xFF])),
        // PNG signature but truncated/corrupted
        Gen.pure(Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]))
    ])
}

/// Generator for valid image data (should pass validation)
func validImageDataGen() -> Gen<Data> {
    Gen.one(of: [
        validJPEGImageDataGen(),
        validPNGImageDataGen()
    ])
}

/// Generator for valid JPEG image data
func validJPEGImageDataGen() -> Gen<Data> {
    #if canImport(UIKit)
    Gen.compose { c in
        // Create a small valid JPEG image
        let size = CGSize(width: c.generate(using: Gen.fromElements(in: 100...500)),
                         height: c.generate(using: Gen.fromElements(in: 100...500)))
        
        UIGraphicsBeginImageContext(size)
        defer { UIGraphicsEndImageContext() }
        
        let context = UIGraphicsGetCurrentContext()!
        let red = CGFloat(c.generate(using: Gen.fromElements(in: 0...100))) / 100.0
        let green = CGFloat(c.generate(using: Gen.fromElements(in: 0...100))) / 100.0
        let blue = CGFloat(c.generate(using: Gen.fromElements(in: 0...100))) / 100.0
        
        context.setFillColor(red: red, green: green, blue: blue, alpha: 1.0)
        context.fill(CGRect(origin: .zero, size: size))
        
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        return image.jpegData(compressionQuality: 0.8)!
    }
    #else
    // Fallback for non-UIKit platforms: generate minimal JPEG header
    Gen.pure(Data([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10]))
    #endif
}

/// Generator for valid PNG image data
func validPNGImageDataGen() -> Gen<Data> {
    #if canImport(UIKit)
    Gen.compose { c in
        // Create a small valid PNG image
        let size = CGSize(width: c.generate(using: Gen.fromElements(in: 100...500)),
                         height: c.generate(using: Gen.fromElements(in: 100...500)))
        
        UIGraphicsBeginImageContext(size)
        defer { UIGraphicsEndImageContext() }
        
        let context = UIGraphicsGetCurrentContext()!
        let red = CGFloat(c.generate(using: Gen.fromElements(in: 0...100))) / 100.0
        let green = CGFloat(c.generate(using: Gen.fromElements(in: 0...100))) / 100.0
        let blue = CGFloat(c.generate(using: Gen.fromElements(in: 0...100))) / 100.0
        
        context.setFillColor(red: red, green: green, blue: blue, alpha: 1.0)
        context.fill(CGRect(origin: .zero, size: size))
        
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        return image.pngData()!
    }
    #else
    // Fallback for non-UIKit platforms: generate minimal PNG header
    Gen.pure(Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]))
    #endif
}

