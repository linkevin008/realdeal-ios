import XCTest
@testable import RealDeal

@available(iOS 15.0, macOS 12.0, *)
final class BackendIntegrationTests: XCTestCase {
    
    // MARK: - MockRemoteDataSource Tests
    
    func testMockRemoteDataSourceCreateAndFetchProperty() async throws {
        let mockDataSource = MockRemoteDataSource(simulateNetworkDelay: false)
        
        let property = Property(
            address: Address(street: "123 Main St", city: "San Francisco", state: "CA", zipCode: "94102", country: "USA"),
            price: 500000,
            propertyType: .house,
            description: "Beautiful house",
            location: Coordinate(latitude: 37.7749, longitude: -122.4194)
        )
        
        let createdProperty = try await mockDataSource.createProperty(property)
        XCTAssertFalse(createdProperty.id.isEmpty)
        
        let fetchedProperties = try await mockDataSource.fetchProperties(filters: nil)
        XCTAssertEqual(fetchedProperties.count, 1)
        XCTAssertEqual(fetchedProperties.first?.id, createdProperty.id)
    }
    
    func testMockRemoteDataSourceUpdateProperty() async throws {
        let mockDataSource = MockRemoteDataSource(simulateNetworkDelay: false)
        
        var property = Property(
            address: Address(street: "123 Main St", city: "San Francisco", state: "CA", zipCode: "94102", country: "USA"),
            price: 500000,
            propertyType: .house,
            description: "Beautiful house",
            location: Coordinate(latitude: 37.7749, longitude: -122.4194)
        )
        
        property = try await mockDataSource.createProperty(property)
        
        var updatedProperty = property
        updatedProperty.price = 550000
        try await mockDataSource.updateProperty(updatedProperty)
        
        let fetchedProperties = try await mockDataSource.fetchProperties(filters: nil)
        XCTAssertEqual(fetchedProperties.first?.price, 550000)
    }
    
    func testMockRemoteDataSourceDeleteProperty() async throws {
        let mockDataSource = MockRemoteDataSource(simulateNetworkDelay: false)
        
        let property = Property(
            address: Address(street: "123 Main St", city: "San Francisco", state: "CA", zipCode: "94102", country: "USA"),
            price: 500000,
            propertyType: .house,
            description: "Beautiful house",
            location: Coordinate(latitude: 37.7749, longitude: -122.4194)
        )
        
        let createdProperty = try await mockDataSource.createProperty(property)
        try await mockDataSource.deleteProperty(id: createdProperty.id)
        
        let fetchedProperties = try await mockDataSource.fetchProperties(filters: nil)
        XCTAssertEqual(fetchedProperties.count, 0)
    }
    
    func testMockRemoteDataSourceFilterByPrice() async throws {
        let mockDataSource = MockRemoteDataSource(simulateNetworkDelay: false)
        
        let property1 = Property(
            address: Address(street: "123 Main St", city: "San Francisco", state: "CA", zipCode: "94102", country: "USA"),
            price: 300000,
            propertyType: .house,
            description: "Affordable house",
            location: Coordinate(latitude: 37.7749, longitude: -122.4194)
        )
        
        let property2 = Property(
            address: Address(street: "456 Oak Ave", city: "San Francisco", state: "CA", zipCode: "94103", country: "USA"),
            price: 700000,
            propertyType: .house,
            description: "Expensive house",
            location: Coordinate(latitude: 37.7849, longitude: -122.4094)
        )
        
        _ = try await mockDataSource.createProperty(property1)
        _ = try await mockDataSource.createProperty(property2)
        
        let filters = PropertyFilters(priceMin: 250000, priceMax: 500000)
        let filteredProperties = try await mockDataSource.fetchProperties(filters: filters)
        
        XCTAssertEqual(filteredProperties.count, 1)
        XCTAssertEqual(filteredProperties.first?.price, 300000)
    }
    
    // MARK: - MockAuthenticationService Tests
    
    func testMockAuthenticationServiceSignUp() async throws {
        let mockAuthService = MockAuthenticationService(simulateNetworkDelay: false)
        
        let profile = UserProfile(
            name: "John Doe",
            email: "john@example.com"
        )
        
        let token = try await mockAuthService.signUp(email: "john@example.com", password: "Password123", profile: profile)
        
        XCTAssertFalse(token.accessToken.isEmpty)
        XCTAssertNotNil(mockAuthService.currentUser)
        XCTAssertEqual(mockAuthService.currentUser?.name, "John Doe")
    }
    
    func testMockAuthenticationServiceSignIn() async throws {
        let mockAuthService = MockAuthenticationService(simulateNetworkDelay: false)
        
        let profile = UserProfile(
            name: "Jane Doe",
            email: "jane@example.com"
        )
        
        _ = try await mockAuthService.signUp(email: "jane@example.com", password: "Password123", profile: profile)
        try await mockAuthService.signOut()
        
        let token = try await mockAuthService.signIn(email: "jane@example.com", password: "Password123")
        
        XCTAssertFalse(token.accessToken.isEmpty)
        XCTAssertNotNil(mockAuthService.currentUser)
    }
    
    func testMockAuthenticationServiceInvalidCredentials() async throws {
        let mockAuthService = MockAuthenticationService(simulateNetworkDelay: false)
        
        do {
            _ = try await mockAuthService.signIn(email: "nonexistent@example.com", password: "wrong")
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error is MockAuthError)
        }
    }
    
    func testMockAuthenticationServiceWeakPassword() async throws {
        let mockAuthService = MockAuthenticationService(simulateNetworkDelay: false)
        
        let profile = UserProfile(
            name: "Test User",
            email: "test@example.com"
        )
        
        do {
            _ = try await mockAuthService.signUp(email: "test@example.com", password: "weak", profile: profile)
            XCTFail("Should have thrown an error for weak password")
        } catch MockAuthError.weakPassword {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    // MARK: - MockImageStorage Tests
    
    func testMockImageStorageUploadAndRetrieve() async throws {
        let mockImageStorage = MockImageStorage(simulateNetworkDelay: false)
        
        let imageData = "fake image data".data(using: .utf8)!
        let url = try await mockImageStorage.uploadImage(imageData, path: "properties/123/image1.jpg")
        
        XCTAssertTrue(url.absoluteString.contains("properties/123/image1.jpg"))
        XCTAssertEqual(mockImageStorage.getImageCount(), 1)
    }
    
    func testMockImageStorageDeleteImage() async throws {
        let mockImageStorage = MockImageStorage(simulateNetworkDelay: false)
        
        let imageData = "fake image data".data(using: .utf8)!
        let url = try await mockImageStorage.uploadImage(imageData, path: "properties/123/image1.jpg")
        
        try await mockImageStorage.deleteImage(url: url)
        
        XCTAssertEqual(mockImageStorage.getImageCount(), 0)
    }
    
    func testMockImageStorageBatchUpload() async throws {
        let mockImageStorage = MockImageStorage(simulateNetworkDelay: false)
        
        let images = [
            (data: "image1".data(using: .utf8)!, path: "properties/123/image1.jpg"),
            (data: "image2".data(using: .utf8)!, path: "properties/123/image2.jpg"),
            (data: "image3".data(using: .utf8)!, path: "properties/123/image3.jpg")
        ]
        
        let urls = try await mockImageStorage.uploadImages(images)
        
        XCTAssertEqual(urls.count, 3)
        XCTAssertEqual(mockImageStorage.getImageCount(), 3)
    }
    
    // MARK: - BackendConfiguration Tests
    
    func testBackendConfigurationFirebase() {
        let config = BackendConfiguration.firebase(
            projectId: "test-project",
            apiKey: "test-api-key",
            storageBucket: "test-bucket"
        )
        
        XCTAssertNotNil(config.baseURL)
        XCTAssertEqual(config.apiKey, "test-api-key")
        XCTAssertNotNil(config.authEndpoint)
        XCTAssertNotNil(config.storageEndpoint)
    }
    
    func testBackendConfigurationSupabase() {
        let projectURL = URL(string: "https://test.supabase.co")!
        let config = BackendConfiguration.supabase(
            projectURL: projectURL,
            apiKey: "test-api-key"
        )
        
        XCTAssertNotNil(config.baseURL)
        XCTAssertEqual(config.apiKey, "test-api-key")
        XCTAssertNotNil(config.authEndpoint)
        XCTAssertNotNil(config.storageEndpoint)
    }
    
    func testBackendConfigurationMock() {
        let config = BackendConfiguration.mock
        
        XCTAssertNotNil(config.baseURL)
        XCTAssertEqual(config.apiKey, "mock-api-key")
        XCTAssertTrue(config.enableLogging)
    }
    
    // MARK: - External Listing API Tests
    
    func testMockMLSAPIClientFetchListings() async throws {
        let mockClient = MockMLSAPIClient()
        
        let parameters = SearchParameters(
            location: "San Francisco",
            radius: 10,
            minPrice: nil,
            maxPrice: nil,
            propertyTypes: nil
        )
        
        let listings = try await mockClient.fetchListings(parameters: parameters)
        
        XCTAssertFalse(listings.isEmpty)
        XCTAssertTrue(listings.allSatisfy { !$0.id.isEmpty })
    }
    
    func testMockMLSAPIClientFilterByPrice() async throws {
        let mockClient = MockMLSAPIClient()
        
        let parameters = SearchParameters(
            location: nil,
            radius: nil,
            minPrice: 500000,
            maxPrice: 1000000,
            propertyTypes: nil
        )
        
        let listings = try await mockClient.fetchListings(parameters: parameters)
        
        XCTAssertFalse(listings.isEmpty)
        for listing in listings {
            if let price = listing.rawData["price"] as? Double {
                XCTAssertGreaterThanOrEqual(Decimal(price), 500000)
                XCTAssertLessThanOrEqual(Decimal(price), 1000000)
            }
        }
    }
    
    func testMockMLSAPIClientFilterByPropertyType() async throws {
        let mockClient = MockMLSAPIClient()
        
        let parameters = SearchParameters(
            location: nil,
            radius: nil,
            minPrice: nil,
            maxPrice: nil,
            propertyTypes: ["house"]
        )
        
        let listings = try await mockClient.fetchListings(parameters: parameters)
        
        XCTAssertFalse(listings.isEmpty)
        for listing in listings {
            if let type = listing.rawData["property_type"] as? String {
                XCTAssertEqual(type.lowercased(), "house")
            }
        }
    }
    
    func testMockMLSAPIClientNormalizeToProperty() async throws {
        let mockClient = MockMLSAPIClient()
        
        let parameters = SearchParameters()
        let listings = try await mockClient.fetchListings(parameters: parameters)
        
        XCTAssertFalse(listings.isEmpty)
        
        let property = mockClient.normalizeToProperty(listings[0])
        
        // Verify source attribution
        XCTAssertEqual(property.source, .mls)
        
        // Verify required fields are present
        XCTAssertFalse(property.address.street.isEmpty)
        XCTAssertFalse(property.address.city.isEmpty)
        XCTAssertFalse(property.address.state.isEmpty)
        XCTAssertGreaterThan(property.price, 0)
        XCTAssertFalse(property.description.isEmpty)
        
        // Verify location is valid
        XCTAssertNotEqual(property.location.latitude, 0)
        XCTAssertNotEqual(property.location.longitude, 0)
    }
    
    func testExternalDataValidatorValidListing() throws {
        let validData: [String: Any] = [
            "street": "123 Main St",
            "city": "San Francisco",
            "state": "CA",
            "price": 500000.0,
            "property_type": "house",
            "latitude": 37.7749,
            "longitude": -122.4194
        ]
        
        let listing = ExternalListing(id: "test-1", rawData: validData)
        
        XCTAssertNoThrow(try ExternalDataValidator.validate(listing))
    }
    
    func testExternalDataValidatorMissingStreet() throws {
        let invalidData: [String: Any] = [
            "city": "San Francisco",
            "state": "CA",
            "price": 500000.0,
            "property_type": "house",
            "latitude": 37.7749,
            "longitude": -122.4194
        ]
        
        let listing = ExternalListing(id: "test-1", rawData: invalidData)
        
        XCTAssertThrowsError(try ExternalDataValidator.validate(listing)) { error in
            if case AppError.validation(let validationError) = error {
                XCTAssertEqual(validationError, .missingRequiredField("street"))
            } else {
                XCTFail("Expected validation error")
            }
        }
    }
    
    func testExternalDataValidatorInvalidPrice() throws {
        let invalidData: [String: Any] = [
            "street": "123 Main St",
            "city": "San Francisco",
            "state": "CA",
            "price": -100.0,
            "property_type": "house",
            "latitude": 37.7749,
            "longitude": -122.4194
        ]
        
        let listing = ExternalListing(id: "test-1", rawData: invalidData)
        
        XCTAssertThrowsError(try ExternalDataValidator.validate(listing)) { error in
            if case AppError.validation(let validationError) = error {
                XCTAssertEqual(validationError, .invalidFormat("price"))
            } else {
                XCTFail("Expected validation error")
            }
        }
    }
    
    func testExternalDataValidatorInvalidCoordinates() throws {
        let invalidData: [String: Any] = [
            "street": "123 Main St",
            "city": "San Francisco",
            "state": "CA",
            "price": 500000.0,
            "property_type": "house",
            "latitude": 200.0, // Invalid latitude
            "longitude": -122.4194
        ]
        
        let listing = ExternalListing(id: "test-1", rawData: invalidData)
        
        XCTAssertThrowsError(try ExternalDataValidator.validate(listing)) { error in
            if case AppError.validation(let validationError) = error {
                XCTAssertEqual(validationError, .invalidFormat("latitude"))
            } else {
                XCTFail("Expected validation error")
            }
        }
    }
    
    func testExternalDataValidatorSanitizeString() {
        let dirtyString = "  Hello\nWorld\t  "
        let sanitized = ExternalDataValidator.sanitizeString(dirtyString)
        
        XCTAssertEqual(sanitized, "HelloWorld")
    }
    
    func testExternalDataValidatorSanitizeImageURLs() {
        let urls = [
            "https://example.com/image1.jpg",
            "http://example.com/image2.jpg",
            "ftp://invalid.com/image3.jpg", // Invalid scheme
            "not-a-url",
            "https://example.com/image4.jpg"
        ]
        
        let sanitized = ExternalDataValidator.sanitizeImageURLs(urls)
        
        XCTAssertEqual(sanitized.count, 3)
        XCTAssertTrue(sanitized.allSatisfy { $0.scheme == "http" || $0.scheme == "https" })
    }
    
    func testMLSAPIClientSourceAttribution() async throws {
        let mockClient = MockMLSAPIClient()
        
        let parameters = SearchParameters()
        let listings = try await mockClient.fetchListings(parameters: parameters)
        
        for listing in listings {
            let property = mockClient.normalizeToProperty(listing)
            
            // Verify source attribution (Requirement 8.2)
            XCTAssertEqual(property.source, .mls, "All MLS listings should have source set to .mls")
        }
    }
    
    func testMLSAPIClientDataNormalization() async throws {
        let mockClient = MockMLSAPIClient()
        
        let parameters = SearchParameters()
        let listings = try await mockClient.fetchListings(parameters: parameters)
        
        XCTAssertFalse(listings.isEmpty)
        
        for listing in listings {
            let property = mockClient.normalizeToProperty(listing)
            
            // Verify all required fields are normalized (Requirement 8.1)
            XCTAssertFalse(property.id.isEmpty)
            XCTAssertFalse(property.address.street.isEmpty)
            XCTAssertFalse(property.address.city.isEmpty)
            XCTAssertFalse(property.address.state.isEmpty)
            XCTAssertGreaterThan(property.price, 0)
            XCTAssertFalse(property.description.isEmpty)
            
            // Verify coordinates are valid
            XCTAssertGreaterThanOrEqual(property.location.latitude, -90)
            XCTAssertLessThanOrEqual(property.location.latitude, 90)
            XCTAssertGreaterThanOrEqual(property.location.longitude, -180)
            XCTAssertLessThanOrEqual(property.location.longitude, 180)
        }
    }
    
    // MARK: - AggregationService Tests
    
    func testAggregationServiceFetchFromMultipleSources() async throws {
        let localDataSource = LocalDataSource()
        let mockMLSClient = MockMLSAPIClient()
        
        let aggregationService = AggregationService(
            localDataSource: localDataSource,
            externalAPIs: [mockMLSClient]
        )
        
        // Add a user-generated property to local storage
        let userProperty = Property(
            id: "user-1",
            address: Address(street: "100 User St", city: "Portland", state: "OR", zipCode: "97201", country: "USA"),
            price: 400000,
            propertyType: .house,
            description: "User-generated listing",
            location: Coordinate(latitude: 45.5152, longitude: -122.6784),
            source: .userGenerated
        )
        try await localDataSource.saveProperty(userProperty)
        
        let parameters = SearchParameters()
        let aggregatedProperties = try await aggregationService.fetchAggregatedListings(parameters: parameters)
        
        // Should have both user-generated and MLS listings
        XCTAssertGreaterThan(aggregatedProperties.count, 1)
        
        let sources = Set(aggregatedProperties.map { $0.source })
        XCTAssertTrue(sources.contains(.userGenerated))
        XCTAssertTrue(sources.contains(.mls))
    }
    
    func testAggregationServiceDuplicateDetection() async throws {
        let localDataSource = LocalDataSource()
        
        // Create two mock clients that return the same property
        let mockClient1 = MockMLSAPIClient()
        let mockClient2 = MockMLSAPIClient()
        
        let aggregationService = AggregationService(
            localDataSource: localDataSource,
            externalAPIs: [mockClient1, mockClient2]
        )
        
        let parameters = SearchParameters()
        let aggregatedProperties = try await aggregationService.fetchAggregatedListings(parameters: parameters)
        
        // Check for duplicates by address
        var addressSet = Set<String>()
        for property in aggregatedProperties {
            let addressKey = "\(property.address.street)|\(property.address.city)|\(property.address.state)"
            XCTAssertFalse(addressSet.contains(addressKey), "Duplicate property found: \(addressKey)")
            addressSet.insert(addressKey)
        }
    }
    
    func testAggregationServiceConflictResolution() async throws {
        let localDataSource = LocalDataSource()
        
        // Create a property with same address but different sources
        let sharedAddress = Address(street: "123 Oak Street", city: "San Francisco", state: "CA", zipCode: "94102", country: "USA")
        let sharedLocation = Coordinate(latitude: 37.7749, longitude: -122.4194)
        
        // User-generated property (higher priority)
        let userProperty = Property(
            id: "user-conflict",
            address: sharedAddress,
            price: 1300000,
            propertyType: .house,
            description: "User-generated version",
            location: sharedLocation,
            source: .userGenerated
        )
        try await localDataSource.saveProperty(userProperty)
        
        // MLS will also have a property at this address (from mock data)
        let mockMLSClient = MockMLSAPIClient()
        
        let aggregationService = AggregationService(
            localDataSource: localDataSource,
            externalAPIs: [mockMLSClient],
            conflictResolution: .default
        )
        
        let parameters = SearchParameters()
        let aggregatedProperties = try await aggregationService.fetchAggregatedListings(parameters: parameters)
        
        // Find the property at the shared address
        let conflictedProperty = aggregatedProperties.first { property in
            property.address.street == sharedAddress.street &&
            property.address.city == sharedAddress.city &&
            property.address.state == sharedAddress.state
        }
        
        // Should prefer user-generated source (higher priority)
        XCTAssertNotNil(conflictedProperty)
        XCTAssertEqual(conflictedProperty?.source, .userGenerated)
        XCTAssertEqual(conflictedProperty?.price, 1300000)
    }
    
    func testAggregationServiceHandlesAPIFailure() async throws {
        let localDataSource = LocalDataSource()
        
        // Add a local property
        let localProperty = Property(
            address: Address(street: "200 Local St", city: "Seattle", state: "WA", zipCode: "98101", country: "USA"),
            price: 600000,
            propertyType: .condo,
            description: "Local listing",
            location: Coordinate(latitude: 47.6062, longitude: -122.3321)
        )
        try await localDataSource.saveProperty(localProperty)
        
        // Create a failing mock client
        let failingClient = MockMLSAPIClient()
        failingClient.shouldFail = true
        
        let aggregationService = AggregationService(
            localDataSource: localDataSource,
            externalAPIs: [failingClient]
        )
        
        let parameters = SearchParameters()
        let aggregatedProperties = try await aggregationService.fetchAggregatedListings(parameters: parameters)
        
        // Should still return local properties even if external API fails
        XCTAssertGreaterThanOrEqual(aggregatedProperties.count, 1)
        XCTAssertTrue(aggregatedProperties.contains { $0.id == localProperty.id })
    }
    
    func testAggregationServiceParallelFetching() async throws {
        let localDataSource = LocalDataSource()
        
        // Create multiple mock clients
        let mockClient1 = MockMLSAPIClient()
        let mockClient2 = MockMLSAPIClient()
        let mockClient3 = MockMLSAPIClient()
        
        let aggregationService = AggregationService(
            localDataSource: localDataSource,
            externalAPIs: [mockClient1, mockClient2, mockClient3]
        )
        
        let startTime = Date()
        let parameters = SearchParameters()
        _ = try await aggregationService.fetchAggregatedListings(parameters: parameters)
        let duration = Date().timeIntervalSince(startTime)
        
        // With parallel fetching, should complete faster than sequential
        // Each mock has 0.5s delay, so parallel should be ~0.5s, sequential would be ~1.5s
        XCTAssertLessThan(duration, 1.0, "Parallel fetching should complete in less than 1 second")
    }
    
    func testAggregationServiceCustomPrioritization() async throws {
        let localDataSource = LocalDataSource()
        
        // Create custom conflict resolution that prioritizes MLS over user-generated
        let customConfig = ConflictResolutionConfig(
            sourcePriority: [
                .mls: 100,
                .userGenerated: 50,
                .zillow: 60,
                .realtor: 60,
                .other: 40
            ]
        )
        
        let sharedAddress = Address(street: "123 Oak Street", city: "San Francisco", state: "CA", zipCode: "94102", country: "USA")
        let sharedLocation = Coordinate(latitude: 37.7749, longitude: -122.4194)
        
        // User-generated property
        let userProperty = Property(
            id: "user-custom",
            address: sharedAddress,
            price: 1300000,
            propertyType: .house,
            description: "User version",
            location: sharedLocation,
            source: .userGenerated
        )
        try await localDataSource.saveProperty(userProperty)
        
        let mockMLSClient = MockMLSAPIClient()
        
        let aggregationService = AggregationService(
            localDataSource: localDataSource,
            externalAPIs: [mockMLSClient],
            conflictResolution: customConfig
        )
        
        let parameters = SearchParameters()
        let aggregatedProperties = try await aggregationService.fetchAggregatedListings(parameters: parameters)
        
        // Find the property at the shared address
        let conflictedProperty = aggregatedProperties.first { property in
            property.address.street == sharedAddress.street &&
            property.address.city == sharedAddress.city &&
            property.address.state == sharedAddress.state
        }
        
        // With custom config, should prefer MLS source
        XCTAssertNotNil(conflictedProperty)
        XCTAssertEqual(conflictedProperty?.source, .mls)
    }
}
