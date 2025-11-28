import XCTest
import CoreData
@testable import RealDeal

final class LocalDataSourceTests: XCTestCase {
    var localDataSource: LocalDataSource!
    var persistenceController: PersistenceController!
    
    override func setUp() {
        super.setUp()
        // Use in-memory store for testing
        persistenceController = PersistenceController(inMemory: true)
        localDataSource = LocalDataSource(persistenceController: persistenceController)
    }
    
    override func tearDown() {
        localDataSource = nil
        persistenceController = nil
        super.tearDown()
    }
    
    // MARK: - Property Tests
    
    func testSaveAndFetchProperty() async throws {
        // Create a test property
        let property = Property(
            address: Address(
                street: "123 Main St",
                city: "San Francisco",
                state: "CA",
                zipCode: "94102",
                country: "USA"
            ),
            price: 1000000,
            propertyType: .house,
            description: "Beautiful house",
            location: Coordinate(latitude: 37.7749, longitude: -122.4194)
        )
        
        // Save the property
        try await localDataSource.saveProperty(property)
        
        // Fetch the property
        let fetchedProperty = try await localDataSource.getProperty(id: property.id)
        
        // Verify
        XCTAssertNotNil(fetchedProperty)
        XCTAssertEqual(fetchedProperty?.id, property.id)
        XCTAssertEqual(fetchedProperty?.address.street, "123 Main St")
        XCTAssertEqual(fetchedProperty?.price, 1000000)
        XCTAssertEqual(fetchedProperty?.propertyType, .house)
    }
    
    func testFetchPropertiesWithFilters() async throws {
        // Create test properties
        let property1 = Property(
            address: Address(street: "123 Main St", city: "SF", state: "CA", zipCode: "94102", country: "USA"),
            price: 500000,
            propertyType: .house,
            description: "House 1",
            location: Coordinate(latitude: 37.7749, longitude: -122.4194)
        )
        
        let property2 = Property(
            address: Address(street: "456 Oak Ave", city: "SF", state: "CA", zipCode: "94103", country: "USA"),
            price: 1500000,
            propertyType: .apartment,
            description: "Apartment 1",
            location: Coordinate(latitude: 37.7849, longitude: -122.4094)
        )
        
        try await localDataSource.saveProperties([property1, property2])
        
        // Test price filter
        let priceFilter = PropertyFilters(priceMin: 400000, priceMax: 600000)
        let filteredProperties = try await localDataSource.fetchProperties(filters: priceFilter)
        
        XCTAssertEqual(filteredProperties.count, 1)
        XCTAssertEqual(filteredProperties.first?.id, property1.id)
    }
    
    func testDeleteProperty() async throws {
        // Create and save a property
        let property = Property(
            address: Address(street: "123 Main St", city: "SF", state: "CA", zipCode: "94102", country: "USA"),
            price: 1000000,
            propertyType: .house,
            description: "Test house",
            location: Coordinate(latitude: 37.7749, longitude: -122.4194)
        )
        
        try await localDataSource.saveProperty(property)
        
        // Verify it exists
        var fetchedProperty = try await localDataSource.getProperty(id: property.id)
        XCTAssertNotNil(fetchedProperty)
        
        // Delete it
        try await localDataSource.deleteProperty(id: property.id)
        
        // Verify it's gone
        fetchedProperty = try await localDataSource.getProperty(id: property.id)
        XCTAssertNil(fetchedProperty)
    }
    
    // MARK: - User Profile Tests
    
    func testSaveAndFetchUserProfile() async throws {
        // Create a test profile
        let profile = UserProfile(
            name: "John Doe",
            email: "john@example.com",
            phoneNumber: "555-1234",
            role: .seller
        )
        
        // Save the profile
        try await localDataSource.saveUserProfile(profile)
        
        // Fetch the profile
        let fetchedProfile = try await localDataSource.getUserProfile(id: profile.id)
        
        // Verify
        XCTAssertNotNil(fetchedProfile)
        XCTAssertEqual(fetchedProfile?.id, profile.id)
        XCTAssertEqual(fetchedProfile?.name, "John Doe")
        XCTAssertEqual(fetchedProfile?.email, "john@example.com")
        XCTAssertEqual(fetchedProfile?.role, .seller)
    }
    
    func testDeleteUserProfile() async throws {
        // Create and save a profile
        let profile = UserProfile(
            name: "Jane Doe",
            email: "jane@example.com"
        )
        
        try await localDataSource.saveUserProfile(profile)
        
        // Verify it exists
        var fetchedProfile = try await localDataSource.getUserProfile(id: profile.id)
        XCTAssertNotNil(fetchedProfile)
        
        // Delete it
        try await localDataSource.deleteUserProfile(id: profile.id)
        
        // Verify it's gone
        fetchedProfile = try await localDataSource.getUserProfile(id: profile.id)
        XCTAssertNil(fetchedProfile)
    }
    
    // MARK: - Favorites Tests
    
    func testSaveAndFetchFavorites() async throws {
        // Create test data
        let userId = UUID().uuidString
        let propertyId = UUID().uuidString
        
        let favorite = Favorite(
            userId: userId,
            propertyId: propertyId
        )
        
        // Save the favorite
        try await localDataSource.saveFavorite(favorite)
        
        // Fetch favorites for user
        let favorites = try await localDataSource.getFavorites(userId: userId)
        
        // Verify
        XCTAssertEqual(favorites.count, 1)
        XCTAssertEqual(favorites.first?.userId, userId)
        XCTAssertEqual(favorites.first?.propertyId, propertyId)
    }
    
    func testIsFavorite() async throws {
        // Create test data
        let userId = UUID().uuidString
        let propertyId = UUID().uuidString
        
        // Initially should not be favorite
        var isFav = try await localDataSource.isFavorite(propertyId: propertyId, userId: userId)
        XCTAssertFalse(isFav)
        
        // Add to favorites
        let favorite = Favorite(userId: userId, propertyId: propertyId)
        try await localDataSource.saveFavorite(favorite)
        
        // Now should be favorite
        isFav = try await localDataSource.isFavorite(propertyId: propertyId, userId: userId)
        XCTAssertTrue(isFav)
    }
    
    func testDeleteFavorite() async throws {
        // Create and save a favorite
        let favorite = Favorite(
            userId: UUID().uuidString,
            propertyId: UUID().uuidString
        )
        
        try await localDataSource.saveFavorite(favorite)
        
        // Verify it exists
        var favorites = try await localDataSource.getFavorites(userId: favorite.userId)
        XCTAssertEqual(favorites.count, 1)
        
        // Delete it
        try await localDataSource.deleteFavorite(id: favorite.id)
        
        // Verify it's gone
        favorites = try await localDataSource.getFavorites(userId: favorite.userId)
        XCTAssertEqual(favorites.count, 0)
    }
}
