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
}
