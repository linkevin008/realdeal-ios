import XCTest
@testable import RealDeal

/// Tests for seller listing management functionality (Task 9)
/// Validates Requirements 2.1, 2.5
@available(iOS 15.0, macOS 12.0, *)
final class SellerListingManagementTests: XCTestCase {
    
    var mockRepository: MockPropertyRepository!
    var mockImageStorage: MockImageStorage!
    var listingService: PropertyListingService!
    
    override func setUp() async throws {
        try await super.setUp()
        mockRepository = MockPropertyRepository(simulateNetworkDelay: false)
        mockImageStorage = MockImageStorage(simulateNetworkDelay: false)
        listingService = PropertyListingService(
            repository: mockRepository,
            imageStorage: mockImageStorage
        )
    }
    
    override func tearDown() async throws {
        mockRepository = nil
        mockImageStorage = nil
        listingService = nil
        try await super.tearDown()
    }
    
    // MARK: - Test Seller Listing Filtering (Requirement 2.1)
    
    func testFetchSellerPropertiesReturnsOnlySellerListings() async throws {
        // Given: Multiple properties from different sellers
        let seller1Id = "seller1"
        let seller2Id = "seller2"
        
        let property1 = createTestProperty(sellerId: seller1Id, status: .active)
        let property2 = createTestProperty(sellerId: seller1Id, status: .pending)
        let property3 = createTestProperty(sellerId: seller2Id, status: .active)
        let property4 = createTestProperty(sellerId: seller1Id, status: .sold)
        
        _ = try await mockRepository.createProperty(property1)
        _ = try await mockRepository.createProperty(property2)
        _ = try await mockRepository.createProperty(property3)
        _ = try await mockRepository.createProperty(property4)
        
        // When: Fetching properties for seller1
        let seller1Properties = try await listingService.fetchSellerProperties(sellerId: seller1Id)
        
        // Then: Only seller1's properties should be returned
        XCTAssertEqual(seller1Properties.count, 3)
        XCTAssertTrue(seller1Properties.allSatisfy { $0.sellerId == seller1Id })
        
        // Verify all statuses are included
        let statuses = Set(seller1Properties.map { $0.status })
        XCTAssertTrue(statuses.contains(.active))
        XCTAssertTrue(statuses.contains(.pending))
        XCTAssertTrue(statuses.contains(.sold))
    }
    
    func testFetchSellerPropertiesReturnsEmptyForSellerWithNoListings() async throws {
        // Given: Properties from one seller
        let seller1Id = "seller1"
        let seller2Id = "seller2"
        
        let property1 = createTestProperty(sellerId: seller1Id, status: .active)
        _ = try await mockRepository.createProperty(property1)
        
        // When: Fetching properties for seller2 who has no listings
        let seller2Properties = try await listingService.fetchSellerProperties(sellerId: seller2Id)
        
        // Then: Empty array should be returned
        XCTAssertEqual(seller2Properties.count, 0)
    }
    
    // MARK: - Test Status Management (Requirement 2.5)
    
    func testUpdatePropertyStatusChangesStatus() async throws {
        // Given: A property with active status
        let property = createTestProperty(sellerId: "seller1", status: .active)
        let createdProperty = try await mockRepository.createProperty(property)
        
        // When: Updating the status to sold
        try await listingService.updatePropertyStatus(propertyId: createdProperty.id, status: .sold)
        
        // Then: The property status should be updated
        let updatedProperty = try await mockRepository.getProperty(id: createdProperty.id)
        XCTAssertNotNil(updatedProperty)
        XCTAssertEqual(updatedProperty?.status, .sold)
    }
    
    func testUpdatePropertyStatusUpdatesTimestamp() async throws {
        // Given: A property
        let property = createTestProperty(sellerId: "seller1", status: .active)
        let createdProperty = try await mockRepository.createProperty(property)
        let originalUpdatedAt = createdProperty.updatedAt
        
        // Wait a bit to ensure timestamp difference
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // When: Updating the status
        try await listingService.updatePropertyStatus(propertyId: createdProperty.id, status: .pending)
        
        // Then: The updatedAt timestamp should be newer
        let updatedProperty = try await mockRepository.getProperty(id: createdProperty.id)
        XCTAssertNotNil(updatedProperty)
        XCTAssertGreaterThan(updatedProperty!.updatedAt, originalUpdatedAt)
    }
    
    func testUpdatePropertyStatusThrowsErrorForNonexistentProperty() async throws {
        // Given: A non-existent property ID
        let nonexistentId = "nonexistent-id"
        
        // When/Then: Updating status should throw an error
        do {
            try await listingService.updatePropertyStatus(propertyId: nonexistentId, status: .sold)
            XCTFail("Expected error to be thrown for nonexistent property")
        } catch {
            // Expected error
            XCTAssertTrue(error is AppError)
        }
    }
    
    @MainActor
    func testMyListingsViewModelLoadsSellerProperties() async throws {
        // Given: Properties for a seller
        let sellerId = "seller1"
        let property1 = createTestProperty(sellerId: sellerId, status: .active)
        let property2 = createTestProperty(sellerId: sellerId, status: .pending)
        
        _ = try await mockRepository.createProperty(property1)
        _ = try await mockRepository.createProperty(property2)
        
        // When: Creating ViewModel and loading properties
        let viewModel = MyListingsViewModel(service: listingService, currentUserId: sellerId)
        await viewModel.loadProperties()
        
        // Then: Properties should be loaded
        XCTAssertEqual(viewModel.properties.count, 2)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    @MainActor
    func testMyListingsViewModelFiltersPropertiesByStatus() async throws {
        // Given: Properties with different statuses
        let sellerId = "seller1"
        let property1 = createTestProperty(sellerId: sellerId, status: .active)
        let property2 = createTestProperty(sellerId: sellerId, status: .pending)
        let property3 = createTestProperty(sellerId: sellerId, status: .sold)
        
        _ = try await mockRepository.createProperty(property1)
        _ = try await mockRepository.createProperty(property2)
        _ = try await mockRepository.createProperty(property3)
        
        // When: Creating ViewModel and loading properties
        let viewModel = MyListingsViewModel(service: listingService, currentUserId: sellerId)
        await viewModel.loadProperties()
        
        // Then: Filtering by status should work
        XCTAssertEqual(viewModel.properties.count, 3)
        
        viewModel.selectedStatus = .active
        XCTAssertEqual(viewModel.filteredProperties.count, 1)
        XCTAssertEqual(viewModel.filteredProperties.first?.status, .active)
        
        viewModel.selectedStatus = .pending
        XCTAssertEqual(viewModel.filteredProperties.count, 1)
        XCTAssertEqual(viewModel.filteredProperties.first?.status, .pending)
        
        viewModel.selectedStatus = .sold
        XCTAssertEqual(viewModel.filteredProperties.count, 1)
        XCTAssertEqual(viewModel.filteredProperties.first?.status, .sold)
        
        viewModel.selectedStatus = nil
        XCTAssertEqual(viewModel.filteredProperties.count, 3)
    }
    
    @MainActor
    func testMyListingsViewModelCountsPropertiesByStatus() async throws {
        // Given: Properties with different statuses
        let sellerId = "seller1"
        let property1 = createTestProperty(sellerId: sellerId, status: .active)
        let property2 = createTestProperty(sellerId: sellerId, status: .active)
        let property3 = createTestProperty(sellerId: sellerId, status: .pending)
        let property4 = createTestProperty(sellerId: sellerId, status: .sold)
        
        _ = try await mockRepository.createProperty(property1)
        _ = try await mockRepository.createProperty(property2)
        _ = try await mockRepository.createProperty(property3)
        _ = try await mockRepository.createProperty(property4)
        
        // When: Creating ViewModel and loading properties
        let viewModel = MyListingsViewModel(service: listingService, currentUserId: sellerId)
        await viewModel.loadProperties()
        
        // Then: Counts should be correct
        XCTAssertEqual(viewModel.activeCount, 2)
        XCTAssertEqual(viewModel.pendingCount, 1)
        XCTAssertEqual(viewModel.soldCount, 1)
    }
    
    @MainActor
    func testMyListingsViewModelUpdatesPropertyStatus() async throws {
        // Given: A property
        let sellerId = "seller1"
        let property = createTestProperty(sellerId: sellerId, status: .active)
        let createdProperty = try await mockRepository.createProperty(property)
        
        let viewModel = MyListingsViewModel(service: listingService, currentUserId: sellerId)
        await viewModel.loadProperties()
        
        // When: Updating property status through ViewModel
        await viewModel.updatePropertyStatus(createdProperty, status: .sold)
        
        // Then: Property status should be updated in ViewModel
        XCTAssertEqual(viewModel.properties.first?.status, .sold)
        XCTAssertNil(viewModel.errorMessage)
        
        // Verify it's also updated in repository
        let updatedProperty = try await mockRepository.getProperty(id: createdProperty.id)
        XCTAssertEqual(updatedProperty?.status, .sold)
    }
    
    @MainActor
    func testMyListingsViewModelDeletesProperty() async throws {
        // Given: A property
        let sellerId = "seller1"
        let property = createTestProperty(sellerId: sellerId, status: .active)
        let createdProperty = try await mockRepository.createProperty(property)
        
        let viewModel = MyListingsViewModel(service: listingService, currentUserId: sellerId)
        await viewModel.loadProperties()
        
        XCTAssertEqual(viewModel.properties.count, 1)
        
        // When: Deleting property through ViewModel
        await viewModel.deleteProperty(createdProperty)
        
        // Then: Property should be removed from ViewModel
        XCTAssertEqual(viewModel.properties.count, 0)
        XCTAssertNil(viewModel.errorMessage)
        
        // Verify it's also deleted from repository
        let deletedProperty = try await mockRepository.getProperty(id: createdProperty.id)
        XCTAssertNil(deletedProperty)
    }
    
    // MARK: - Helper Methods
    
    private func createTestProperty(sellerId: String, status: PropertyStatus) -> Property {
        Property(
            id: UUID().uuidString,
            address: Address(
                street: "123 Test St",
                city: "Test City",
                province: "ON",
                postalCode: "A1A 1A1",
                country: "Canada"
            ),
            price: Decimal(500000),
            propertyType: .house,
            description: "Test property",
            specifications: PropertySpecifications(
                bedrooms: 3,
                bathrooms: 2.0,
                squareFeet: 2000
            ),
            location: Coordinate(latitude: 37.7749, longitude: -122.4194),
            sellerId: sellerId,
            status: status
        )
    }
}
