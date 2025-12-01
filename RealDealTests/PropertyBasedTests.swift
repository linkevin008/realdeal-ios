import XCTest
import SwiftCheck
import CoreLocation
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
        property("Invalid property data should be rejected") <- forAll { [self] (seed: Int) in
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
        property("Property persistence round-trip preserves all data") <- forAll { [self] (seed: Int) in
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
        property("Profile persistence round-trip preserves all data") <- forAll { [self] (seed: Int) in
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
        property("Invalid profile photos should be rejected") <- forAll(Gen.fromElements(in: 0...100)) { (seed: Int) in
            let invalidImageData = invalidImageDataGen().resize(seed).generate
            do {
                try ProfilePhotoValidator.validate(invalidImageData)
                return false // Should have thrown an error
            } catch {
                return true // Correctly rejected invalid image
            }
        }
        
        // Test that valid profile photos are accepted
        property("Valid profile photos should be accepted") <- forAll(Gen.fromElements(in: 0...100)) { (seed: Int) in
            let validImageData = validImageDataGen().resize(seed).generate
            do {
                try ProfilePhotoValidator.validate(validImageData)
                return true // Correctly accepted valid image
            } catch {
                return false // Should not have thrown an error
            }
        }
    }
    
    // MARK: - Property-Based Test for Valid Credentials Authentication
    
    /// Feature: real-estate-listings, Property 19: Valid credentials authenticate successfully
    /// Validates: Requirements 6.1
    func testValidCredentialsAuthenticateSuccessfully() {
        // Test that valid credentials successfully authenticate and grant access
        property("Valid credentials should authenticate successfully") <- forAll { [self] (seed: Int) in
            let credentials = validCredentialsGen().resize(seed).generate
            let expectation = XCTestExpectation(description: "Valid credentials authentication")
            var result = false
            
            Task {
                do {
                    // Use in-memory persistence controller for testing
                    let testPersistence = PersistenceController(inMemory: true)
                    let localDataSource = LocalDataSource(persistenceController: testPersistence)
                    let mockRemote = MockRemoteDataSource(simulateNetworkDelay: false)
                    let mockAuth = MockAuthenticationService(simulateNetworkDelay: false)
                    let userRepo = UserProfileRepository(
                        localDataSource: localDataSource,
                        remoteDataSource: mockRemote
                    )
                    let authService = AuthenticationService(
                        backendAuth: mockAuth,
                        userProfileRepository: userRepo
                    )
                    
                    // Step 1: Register the user with valid credentials
                    let profile = UserProfile(
                        name: credentials.name,
                        email: credentials.email,
                        role: .buyer
                    )
                    _ = try await authService.signUp(
                        email: credentials.email,
                        password: credentials.password,
                        profile: profile
                    )
                    
                    // Step 2: Sign out
                    try await authService.signOut()
                    
                    // Step 3: Sign in with the same valid credentials
                    let token = try await authService.signIn(
                        email: credentials.email,
                        password: credentials.password
                    )
                    
                    // Step 4: Verify authentication succeeded
                    // - Token should be non-empty
                    // - Current user should be set
                    // - Current user email should match
                    result = !token.accessToken.isEmpty &&
                             authService.currentUser != nil &&
                             authService.currentUser?.email == credentials.email
                    
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
    
    // MARK: - Property-Based Test for Invalid Credentials Rejection
    
    /// Feature: real-estate-listings, Property 20: Invalid credentials are rejected
    /// Validates: Requirements 6.2
    func testInvalidCredentialsAreRejected() {
        // Test that invalid credentials are rejected with appropriate error
        property("Invalid credentials should be rejected") <- forAll { [self] (seed: Int) in
            let invalidCreds = invalidCredentialsGen().resize(seed).generate
            let expectation = XCTestExpectation(description: "Invalid credentials rejection")
            var result = false
            
            Task {
                do {
                    // Use in-memory persistence controller for testing
                    let testPersistence = PersistenceController(inMemory: true)
                    let localDataSource = LocalDataSource(persistenceController: testPersistence)
                    let mockRemote = MockRemoteDataSource(simulateNetworkDelay: false)
                    let mockAuth = MockAuthenticationService(simulateNetworkDelay: false)
                    let userRepo = UserProfileRepository(
                        localDataSource: localDataSource,
                        remoteDataSource: mockRemote
                    )
                    let authService = AuthenticationService(
                        backendAuth: mockAuth,
                        userProfileRepository: userRepo
                    )
                    
                    // If we have a registered user, register them first
                    if let registeredUser = invalidCreds.registeredUser {
                        let profile = UserProfile(
                            name: registeredUser.name,
                            email: registeredUser.email,
                            role: .buyer
                        )
                        _ = try await authService.signUp(
                            email: registeredUser.email,
                            password: registeredUser.password,
                            profile: profile
                        )
                        try await authService.signOut()
                    }
                    
                    // Attempt to sign in with invalid credentials
                    _ = try await authService.signIn(
                        email: invalidCreds.attemptEmail,
                        password: invalidCreds.attemptPassword
                    )
                    
                    // If we reach here, authentication succeeded when it should have failed
                    result = false
                    expectation.fulfill()
                } catch {
                    // Authentication correctly failed - verify it's an appropriate error
                    result = true
                    expectation.fulfill()
                }
            }
            
            self.wait(for: [expectation], timeout: 5.0)
            return result
        }
    }
    
    // MARK: - Property-Based Test for Registration Validation
    
    /// Feature: real-estate-listings, Property 21: Registration validation enforcement
    /// Validates: Requirements 6.3
    func testRegistrationValidationEnforcement() {
        // Test that invalid registration data is rejected with appropriate validation errors
        property("Invalid registration data should be rejected") <- forAll { [self] (seed: Int) in
            let invalidReg = invalidRegistrationDataGen().resize(abs(seed)).generate
            let expectation = XCTestExpectation(description: "Invalid registration rejection")
            var result = false
            
            Task {
                do {
                    // Use in-memory persistence controller for testing
                    let testPersistence = PersistenceController(inMemory: true)
                    let localDataSource = LocalDataSource(persistenceController: testPersistence)
                    let mockRemote = MockRemoteDataSource(simulateNetworkDelay: false)
                    let mockAuth = MockAuthenticationService(simulateNetworkDelay: false)
                    let userRepo = UserProfileRepository(
                        localDataSource: localDataSource,
                        remoteDataSource: mockRemote
                    )
                    let authService = AuthenticationService(
                        backendAuth: mockAuth,
                        userProfileRepository: userRepo
                    )
                    
                    // Attempt to register with invalid data
                    _ = try await authService.signUp(
                        email: invalidReg.email,
                        password: invalidReg.password,
                        profile: invalidReg.profile
                    )
                    
                    // If we reach here, registration succeeded when it should have failed
                    result = false
                    expectation.fulfill()
                } catch {
                    // Registration correctly failed - any error is acceptable for invalid data
                    // The key is that it failed, not the specific error type
                    result = true
                    expectation.fulfill()
                }
            }
            
            self.wait(for: [expectation], timeout: 5.0)
            return result
        }
        
        // Test that valid registration data is accepted
        property("Valid registration data should be accepted") <- forAll { [self] (seed: Int) in
            let validReg = validRegistrationDataGen().resize(abs(seed)).generate
            let expectation = XCTestExpectation(description: "Valid registration acceptance")
            var result = false
            
            Task {
                do {
                    // Use in-memory persistence controller for testing
                    let testPersistence = PersistenceController(inMemory: true)
                    let localDataSource = LocalDataSource(persistenceController: testPersistence)
                    let mockRemote = MockRemoteDataSource(simulateNetworkDelay: false)
                    let mockAuth = MockAuthenticationService(simulateNetworkDelay: false)
                    let userRepo = UserProfileRepository(
                        localDataSource: localDataSource,
                        remoteDataSource: mockRemote
                    )
                    let authService = AuthenticationService(
                        backendAuth: mockAuth,
                        userProfileRepository: userRepo
                    )
                    
                    // Attempt to register with valid data
                    let token = try await authService.signUp(
                        email: validReg.email,
                        password: validReg.password,
                        profile: validReg.profile
                    )
                    
                    // Verify registration succeeded
                    result = !token.accessToken.isEmpty &&
                             authService.currentUser != nil &&
                             authService.currentUser?.email == validReg.email
                    
                    expectation.fulfill()
                } catch {
                    // Registration failed when it should have succeeded
                    result = false
                    expectation.fulfill()
                }
            }
            
            self.wait(for: [expectation], timeout: 5.0)
            return result
        }
    }
    
    // MARK: - Property-Based Test for Property Creation with Valid Data
    
    /// Feature: real-estate-listings, Property 1: Property creation with valid data succeeds
    /// Validates: Requirements 1.1
    func testPropertyCreationWithValidDataSucceeds() {
        // Test that creating a property with valid data results in a stored listing with matching data
        property("Property creation with valid data should succeed and persist correctly") <- forAll(Gen.fromElements(in: 0...100)) { (seed: Int) in
            let testProperty = validPropertyGen().resize(seed).generate
            let expectation = XCTestExpectation(description: "Property creation with valid data")
            var result = false
            
            Task {
                do {
                    // Use in-memory persistence controller for testing
                    let testPersistence = PersistenceController(inMemory: true)
                    let localDataSource = LocalDataSource(persistenceController: testPersistence)
                    let mockRemote = MockRemoteDataSource(simulateNetworkDelay: false)
                    let mockImageStorage = MockImageStorage()
                    
                    // Create repository and service
                    let repository = PropertyRepository(
                        localDataSource: localDataSource,
                        remoteDataSource: mockRemote
                    )
                    let listingService = PropertyListingService(
                        repository: repository,
                        imageStorage: mockImageStorage
                    )
                    
                    // Create the property (without images for simplicity in this test)
                    let createdProperty = try await listingService.createProperty(testProperty, imageDataArray: [])
                    
                    // Verify the property was created successfully
                    // 1. The created property should have an ID
                    guard !createdProperty.id.isEmpty else {
                        result = false
                        expectation.fulfill()
                        return
                    }
                    
                    // 2. Retrieve the property from storage
                    guard let retrievedProperty = try await repository.getProperty(id: createdProperty.id) else {
                        result = false
                        expectation.fulfill()
                        return
                    }
                    
                    // 3. Verify all data matches (the property was stored correctly)
                    result = self.propertiesAreEquivalent(testProperty, retrievedProperty)
                    expectation.fulfill()
                } catch {
                    // Property creation failed when it should have succeeded with valid data
                    result = false
                    expectation.fulfill()
                }
            }
            
            self.wait(for: [expectation], timeout: 5.0)
            return result
        }
    }
    
    // MARK: - Property-Based Test for Image Association Persistence
    
    /// Feature: real-estate-listings, Property 2: Image association persistence
    /// Validates: Requirements 1.2
    func testImageAssociationPersistence() {
        // Test that uploading images results in those images being associated with the correct property when retrieved
        property("Images uploaded with a property should be correctly associated when retrieved") <- forAll(Gen.fromElements(in: 1...5)) { (imageCount: Int) in
            let testProperty = validPropertyGen().generate
            let expectation = XCTestExpectation(description: "Image association persistence")
            var result = false
            
            Task {
                do {
                    // Use in-memory persistence controller for testing
                    let testPersistence = PersistenceController(inMemory: true)
                    let localDataSource = LocalDataSource(persistenceController: testPersistence)
                    let mockRemote = MockRemoteDataSource(simulateNetworkDelay: false)
                    let mockImageStorage = MockImageStorage(simulateNetworkDelay: false)
                    
                    // Create repository and service
                    let repository = PropertyRepository(
                        localDataSource: localDataSource,
                        remoteDataSource: mockRemote
                    )
                    let listingService = PropertyListingService(
                        repository: repository,
                        imageStorage: mockImageStorage
                    )
                    
                    // Generate valid image data for testing
                    let imageDataArray = (0..<imageCount).map { _ in
                        self.generateValidImageData()
                    }
                    
                    // Create the property with images
                    let createdProperty = try await listingService.createProperty(testProperty, imageDataArray: imageDataArray)
                    
                    // Step 1: Verify the created property has the correct number of images
                    guard createdProperty.images.count == imageCount else {
                        result = false
                        expectation.fulfill()
                        return
                    }
                    
                    // Step 2: Verify each image has a valid URL and correct order
                    for (index, image) in createdProperty.images.enumerated() {
                        guard !image.url.absoluteString.isEmpty,
                              image.order == index else {
                            result = false
                            expectation.fulfill()
                            return
                        }
                    }
                    
                    // Step 3: Retrieve the property from storage
                    guard let retrievedProperty = try await repository.getProperty(id: createdProperty.id) else {
                        result = false
                        expectation.fulfill()
                        return
                    }
                    
                    // Step 4: Verify the retrieved property has the same images
                    guard retrievedProperty.images.count == imageCount else {
                        result = false
                        expectation.fulfill()
                        return
                    }
                    
                    // Step 5: Verify each image is correctly associated (same URL and order)
                    let sortedCreatedImages = createdProperty.images.sorted(by: { $0.order < $1.order })
                    let sortedRetrievedImages = retrievedProperty.images.sorted(by: { $0.order < $1.order })
                    
                    for (createdImage, retrievedImage) in zip(sortedCreatedImages, sortedRetrievedImages) {
                        guard createdImage.id == retrievedImage.id,
                              createdImage.url == retrievedImage.url,
                              createdImage.order == retrievedImage.order else {
                            result = false
                            expectation.fulfill()
                            return
                        }
                    }
                    
                    // Step 6: Verify the images are actually stored in the image storage
                    for image in createdProperty.images {
                        guard mockImageStorage.getImageData(url: image.url) != nil else {
                            result = false
                            expectation.fulfill()
                            return
                        }
                    }
                    
                    // All checks passed
                    result = true
                    expectation.fulfill()
                } catch {
                    // Property creation or retrieval failed
                    result = false
                    expectation.fulfill()
                }
            }
            
            self.wait(for: [expectation], timeout: 10.0)
            return result
        }
    }
    
    // MARK: - Property-Based Test for Property Deletion
    
    /// Feature: real-estate-listings, Property 7: Property deletion removes from storage
    /// Validates: Requirements 2.4
    func testPropertyDeletionRemovesFromStorage() {
        // Test that deleting a property results in it no longer appearing in any queries or storage
        property("Deleted property should not appear in queries or storage") <- forAll(Gen.fromElements(in: 0...100)) { (seed: Int) in
            let testProperty = validPropertyGen().resize(seed).generate
            let expectation = XCTestExpectation(description: "Property deletion removes from storage")
            var result = false
            
            Task {
                do {
                    // Use in-memory persistence controller for testing
                    let testPersistence = PersistenceController(inMemory: true)
                    let localDataSource = LocalDataSource(persistenceController: testPersistence)
                    let mockRemote = MockRemoteDataSource(simulateNetworkDelay: false)
                    
                    // Create repository
                    let repository = PropertyRepository(
                        localDataSource: localDataSource,
                        remoteDataSource: mockRemote
                    )
                    
                    // Step 1: Create and save the property
                    try await localDataSource.saveProperty(testProperty)
                    
                    // Step 2: Verify the property exists in storage
                    guard let retrievedProperty = try await localDataSource.getProperty(id: testProperty.id) else {
                        result = false
                        expectation.fulfill()
                        return
                    }
                    
                    // Verify it's the same property
                    guard self.propertiesAreEquivalent(testProperty, retrievedProperty) else {
                        result = false
                        expectation.fulfill()
                        return
                    }
                    
                    // Step 3: Delete the property
                    try await repository.deleteProperty(id: testProperty.id)
                    
                    // Step 4: Verify the property no longer exists in storage
                    let deletedProperty = try await localDataSource.getProperty(id: testProperty.id)
                    guard deletedProperty == nil else {
                        result = false
                        expectation.fulfill()
                        return
                    }
                    
                    // Step 5: Verify the property doesn't appear in queries
                    let allProperties = try await localDataSource.fetchProperties(filters: nil)
                    let foundInQuery = allProperties.contains { $0.id == testProperty.id }
                    guard !foundInQuery else {
                        result = false
                        expectation.fulfill()
                        return
                    }
                    
                    // Step 6: Verify the property doesn't appear in filtered queries
                    let filters = PropertyFilters(
                        priceMin: testProperty.price - 1000,
                        priceMax: testProperty.price + 1000,
                        propertyTypes: [testProperty.propertyType],
                        locationRadius: nil,
                        minBedrooms: nil,
                        minBathrooms: nil,
                        sources: [testProperty.source]
                    )
                    let filteredProperties = try await localDataSource.fetchProperties(filters: filters)
                    let foundInFilteredQuery = filteredProperties.contains { $0.id == testProperty.id }
                    guard !foundInFilteredQuery else {
                        result = false
                        expectation.fulfill()
                        return
                    }
                    
                    // All checks passed - property was successfully deleted from storage
                    result = true
                    expectation.fulfill()
                } catch {
                    // Deletion or verification failed
                    result = false
                    expectation.fulfill()
                }
            }
            
            self.wait(for: [expectation], timeout: 10.0)
            return result
        }
    }
    
    // MARK: - Property-Based Test for Offline Cache Accessibility
    
    /// Feature: real-estate-listings, Property 33: Offline cache accessibility
    /// Validates: Requirements 10.3
    func testOfflineCacheAccessibility() {
        // Test that previously loaded properties remain accessible from cache when offline
        // This tests the core cache functionality that enables offline access
        property("Previously loaded properties should be accessible from cache when offline") <- forAll(Gen.fromElements(in: 1...10)) { (propertyCount: Int) in
            // Generate properties with guaranteed unique IDs
            let testProperties = (0..<propertyCount).map { index in
                let baseProperty = validPropertyGen().generate
                return RealDeal.Property(
                    id: "test-property-\(index)-\(UUID().uuidString)",
                    address: baseProperty.address,
                    price: baseProperty.price,
                    propertyType: baseProperty.propertyType,
                    description: baseProperty.description,
                    specifications: baseProperty.specifications,
                    images: baseProperty.images,
                    location: baseProperty.location,
                    source: baseProperty.source,
                    sellerId: baseProperty.sellerId,
                    status: baseProperty.status,
                    createdAt: baseProperty.createdAt,
                    updatedAt: baseProperty.updatedAt
                )
            }
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
    
    // MARK: - Property-Based Test for Timestamp Display
    
    /// Feature: real-estate-listings, Property 18: Timestamp display in property details
    /// Validates: Requirements 5.5
    func testTimestampDisplayInPropertyDetails() {
        // Test that property detail view displays both creation date and last updated date
        property("Property detail view should display creation and updated timestamps") <- forAll(Gen.fromElements(in: 0...100)) { (seed: Int) in
            let testProperty = validPropertyGen().resize(seed).generate
            let expectation = XCTestExpectation(description: "Timestamp display in property details")
            var result = false
            
            Task { @MainActor in
                // Use in-memory persistence controller for testing
                let testPersistence = PersistenceController(inMemory: true)
                let localDataSource = LocalDataSource(persistenceController: testPersistence)
                let mockRemote = MockRemoteDataSource(simulateNetworkDelay: false)
                
                // Create repositories
                let propertyRepository = PropertyRepository(
                    localDataSource: localDataSource,
                    remoteDataSource: mockRemote
                )
                let userProfileRepository = UserProfileRepository(
                    localDataSource: localDataSource,
                    remoteDataSource: mockRemote
                )
                
                // Create the view model
                let viewModel = PropertyDetailViewModel(
                    property: testProperty,
                    propertyRepository: propertyRepository,
                    userProfileRepository: userProfileRepository
                )
                
                // Verify timestamp formatting
                
                // 1. Created date should be formatted and non-empty
                let formattedCreatedDate = viewModel.formattedCreatedDate
                guard !formattedCreatedDate.isEmpty else {
                    result = false
                    expectation.fulfill()
                    return
                }
                
                // 2. Created date should contain "Listed on" prefix
                guard formattedCreatedDate.contains("Listed on") else {
                    result = false
                    expectation.fulfill()
                    return
                }
                
                // 3. Created date should contain a formatted date string
                // The formatted date should be a substring of the full string
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                dateFormatter.timeStyle = .none
                let expectedCreatedDateString = dateFormatter.string(from: testProperty.createdAt)
                guard formattedCreatedDate.contains(expectedCreatedDateString) else {
                    result = false
                    expectation.fulfill()
                    return
                }
                
                // 4. Updated date should be formatted and non-empty
                let formattedUpdatedDate = viewModel.formattedUpdatedDate
                guard !formattedUpdatedDate.isEmpty else {
                    result = false
                    expectation.fulfill()
                    return
                }
                
                // 5. Updated date should contain "Updated on" prefix
                guard formattedUpdatedDate.contains("Updated on") else {
                    result = false
                    expectation.fulfill()
                    return
                }
                
                // 6. Updated date should contain a formatted date string
                let expectedUpdatedDateString = dateFormatter.string(from: testProperty.updatedAt)
                guard formattedUpdatedDate.contains(expectedUpdatedDateString) else {
                    result = false
                    expectation.fulfill()
                    return
                }
                
                // 7. Verify the formatted strings match the expected format exactly
                let expectedCreatedFormat = "Listed on \(expectedCreatedDateString)"
                let expectedUpdatedFormat = "Updated on \(expectedUpdatedDateString)"
                
                guard formattedCreatedDate == expectedCreatedFormat,
                      formattedUpdatedDate == expectedUpdatedFormat else {
                    result = false
                    expectation.fulfill()
                    return
                }
                
                // All timestamp checks passed
                result = true
                expectation.fulfill()
            }
            
            self.wait(for: [expectation], timeout: 5.0)
            return result
        }
    }
    
    // MARK: - Property-Based Test for Property Detail Display Completeness
    
    /// Feature: real-estate-listings, Property 16: Property detail display completeness
    /// Validates: Requirements 5.1
    func testPropertyDetailDisplayCompleteness() {
        // Test that the detail view contains all required fields: address, price, description, and specifications
        property("Property detail view should contain all required fields") <- forAll(Gen.fromElements(in: 0...100)) { (seed: Int) in
            let testProperty = validPropertyGen().resize(seed).generate
            let expectation = XCTestExpectation(description: "Property detail display completeness")
            var result = false
            
            Task { @MainActor in
                // Use in-memory persistence controller for testing
                let testPersistence = PersistenceController(inMemory: true)
                let localDataSource = LocalDataSource(persistenceController: testPersistence)
                let mockRemote = MockRemoteDataSource(simulateNetworkDelay: false)
                
                // Create repositories
                let propertyRepository = PropertyRepository(
                    localDataSource: localDataSource,
                    remoteDataSource: mockRemote
                )
                let userProfileRepository = UserProfileRepository(
                    localDataSource: localDataSource,
                    remoteDataSource: mockRemote
                )
                
                // Create the view model
                let viewModel = PropertyDetailViewModel(
                    property: testProperty,
                    propertyRepository: propertyRepository,
                    userProfileRepository: userProfileRepository
                )
                
                // Verify all required fields are present and non-empty
                
                // 1. Address should be formatted and contain all components
                let formattedAddress = viewModel.formattedAddress
                guard !formattedAddress.isEmpty,
                      formattedAddress.contains(testProperty.address.street),
                      formattedAddress.contains(testProperty.address.city),
                      formattedAddress.contains(testProperty.address.state),
                      formattedAddress.contains(testProperty.address.zipCode) else {
                    result = false
                    expectation.fulfill()
                    return
                }
                
                // 2. Price should be formatted and non-empty
                let formattedPrice = viewModel.formattedPrice
                guard !formattedPrice.isEmpty,
                      formattedPrice.contains("$") else {
                    result = false
                    expectation.fulfill()
                    return
                }
                
                // 3. Description should be accessible and match the property description
                let description = viewModel.property.description
                guard !description.isEmpty,
                      description == testProperty.description else {
                    result = false
                    expectation.fulfill()
                    return
                }
                
                // 4. Specifications should be formatted (if present)
                // The specifications string may be empty if no specs are provided, but the formatter should work
                let formattedSpecs = viewModel.formattedSpecifications
                
                // If the property has bedrooms, it should appear in the formatted specs
                if let bedrooms = testProperty.specifications.bedrooms {
                    guard formattedSpecs.contains("\(bedrooms)") else {
                        result = false
                        expectation.fulfill()
                        return
                    }
                }
                
                // If the property has bathrooms, it should appear in the formatted specs
                if let bathrooms = testProperty.specifications.bathrooms {
                    guard formattedSpecs.contains("\(bathrooms)") else {
                        result = false
                        expectation.fulfill()
                        return
                    }
                }
                
                // If the property has square feet, it should appear in the formatted specs
                if let sqft = testProperty.specifications.squareFeet {
                    guard formattedSpecs.contains("\(sqft)") || formattedSpecs.contains("sqft") else {
                        result = false
                        expectation.fulfill()
                        return
                    }
                }
                
                // 5. Property type should be formatted and non-empty
                let formattedType = viewModel.formattedPropertyType
                guard !formattedType.isEmpty else {
                    result = false
                    expectation.fulfill()
                    return
                }
                
                // 6. Timestamps should be formatted and non-empty
                let formattedCreatedDate = viewModel.formattedCreatedDate
                let formattedUpdatedDate = viewModel.formattedUpdatedDate
                guard !formattedCreatedDate.isEmpty,
                      !formattedUpdatedDate.isEmpty,
                      formattedCreatedDate.contains("Listed on"),
                      formattedUpdatedDate.contains("Updated on") else {
                    result = false
                    expectation.fulfill()
                    return
                }
                
                // All required fields are present and properly formatted
                result = true
                expectation.fulfill()
            }
            
            self.wait(for: [expectation], timeout: 5.0)
            return result
        }
    }
    
    // MARK: - Property-Based Test for Active Listings as Map Markers
    
    /// Feature: real-estate-listings, Property 9: Active listings appear as map markers
    /// Validates: Requirements 3.1
    func testActiveListingsAppearAsMapMarkers() {
        // Test that all active property listings appear as markers on the map view
        property("All active listings should appear as map markers") <- forAll(Gen.fromElements(in: 1...20)) { (propertyCount: Int) in
            let expectation = XCTestExpectation(description: "Active listings appear as map markers")
            var result = false
            
            Task { @MainActor in
                do {
                    // Use in-memory persistence controller for testing
                    let testPersistence = PersistenceController(inMemory: true)
                    let localDataSource = LocalDataSource(persistenceController: testPersistence)
                    let mockRemote = MockRemoteDataSource(simulateNetworkDelay: false)
                    
                    // Create repository
                    let repository = PropertyRepository(
                        localDataSource: localDataSource,
                        remoteDataSource: mockRemote
                    )
                    
                    // Generate a mix of active and non-active properties
                    // Force unique IDs by creating new UUIDs for each property
                    var testProperties: [RealDeal.Property] = []
                    var activePropertyIds: Set<String> = []
                    
                    for i in 0..<propertyCount {
                        // Generate a property template
                        let template = validPropertyGen().resize(i * 73).generate
                        
                        // Create a new property with a guaranteed unique ID
                        let uniqueId = UUID().uuidString
                        let property = RealDeal.Property(
                            id: uniqueId,
                            address: template.address,
                            price: template.price,
                            propertyType: template.propertyType,
                            description: template.description,
                            specifications: template.specifications,
                            images: template.images,
                            location: template.location,
                            source: template.source,
                            sellerId: template.sellerId,
                            status: template.status,
                            createdAt: template.createdAt,
                            updatedAt: template.updatedAt
                        )
                        
                        // Determine status based on position in array
                        var finalProperty = property
                        
                        if i % 3 == 0 {
                            finalProperty.status = .active
                            activePropertyIds.insert(finalProperty.id)
                        } else if i % 3 == 1 {
                            finalProperty.status = .pending
                        } else {
                            finalProperty.status = .sold
                        }
                        
                        testProperties.append(finalProperty)
                    }
                    
                    // Save all properties to storage (both local and remote for consistency)
                    try await localDataSource.saveProperties(testProperties)
                    
                    // Also seed the mock remote data source so it returns the same properties
                    // This is important because the repository tries remote first if connected
                    mockRemote.seedData(properties: testProperties)
                    
                    // Verify all properties were saved by retrieving them individually
                    // (Note: fetchProperties filters out sold and deleted properties by default)
                    for property in testProperties {
                        guard let _ = try await localDataSource.getProperty(id: property.id) else {
                            result = false
                            expectation.fulfill()
                            return
                        }
                    }
                    
                    // Create MapViewModel
                    let locationManager = LocationManager()
                    let filterService = FilterService()
                    let mapViewModel = MapViewModel(
                        repository: repository,
                        filterService: filterService,
                        locationManager: locationManager
                    )
                    
                    // Load properties into the map view model
                    await mapViewModel.loadProperties()
                    
                    // Check for errors in the view model
                    guard mapViewModel.errorMessage == nil else {
                        result = false
                        expectation.fulfill()
                        return
                    }
                    
                    // Step 1: Verify that the number of annotations matches the number of active properties
                    let activeCount = testProperties.filter { $0.status == .active }.count
                    guard mapViewModel.annotations.count == activeCount else {
                        result = false
                        expectation.fulfill()
                        return
                    }
                    
                    // Step 2: Verify that each annotation corresponds to an active property
                    for annotation in mapViewModel.annotations {
                        guard activePropertyIds.contains(annotation.property.id) else {
                            result = false
                            expectation.fulfill()
                            return
                        }
                        
                        // Verify the annotation has the correct status
                        guard annotation.property.status == .active else {
                            result = false
                            expectation.fulfill()
                            return
                        }
                    }
                    
                    // Step 3: Verify that all active properties have corresponding annotations
                    let annotationPropertyIds = Set(mapViewModel.annotations.map { $0.property.id })
                    guard annotationPropertyIds == activePropertyIds else {
                        result = false
                        expectation.fulfill()
                        return
                    }
                    
                    // Step 4: Verify that non-active properties (pending, sold) do NOT appear as markers
                    let nonActiveProperties = testProperties.filter { $0.status != .active }
                    for nonActiveProperty in nonActiveProperties {
                        guard !annotationPropertyIds.contains(nonActiveProperty.id) else {
                            result = false
                            expectation.fulfill()
                            return
                        }
                    }
                    
                    // Step 5: Verify that each annotation has valid coordinate data
                    for annotation in mapViewModel.annotations {
                        let coordinate = annotation.coordinate
                        guard coordinate.latitude >= -90 && coordinate.latitude <= 90,
                              coordinate.longitude >= -180 && coordinate.longitude <= 180 else {
                            result = false
                            expectation.fulfill()
                            return
                        }
                    }
                    
                    // All checks passed - active listings correctly appear as map markers
                    result = true
                    expectation.fulfill()
                } catch {
                    // Test failed due to error
                    result = false
                    expectation.fulfill()
                }
            }
            
            self.wait(for: [expectation], timeout: 10.0)
            return result
        }
    }
    
    // MARK: - Property-Based Test for Marker Clustering
    
    /// Feature: real-estate-listings, Property 10: Marker clustering for nearby properties
    /// Validates: Requirements 3.5
    func testMarkerClusteringForNearbyProperties() {
        // Test that properties with coordinates within clustering distance are clustered with accurate count
        property("Nearby properties should be clustered with accurate count") <- forAll(Gen.fromElements(in: 5...20)) { (propertyCount: Int) in
            let expectation = XCTestExpectation(description: "Marker clustering for nearby properties")
            var result = false
            
            Task { @MainActor in
                do {
                    // Use in-memory persistence controller for testing
                    let testPersistence = PersistenceController(inMemory: true)
                    let localDataSource = LocalDataSource(persistenceController: testPersistence)
                    let mockRemote = MockRemoteDataSource(simulateNetworkDelay: false)
                    
                    // Create repository
                    let repository = PropertyRepository(
                        localDataSource: localDataSource,
                        remoteDataSource: mockRemote
                    )
                    
                    // Generate properties with nearby coordinates (within clustering distance)
                    // We'll create clusters by placing properties very close together
                    let baseLatitude = 37.7749
                    let baseLongitude = -122.4194
                    
                    // Create properties in tight clusters
                    // Cluster 1: 3-5 properties very close together (within ~100 meters)
                    let cluster1Size = min(propertyCount / 2, 5)
                    let cluster1Center = Coordinate(latitude: baseLatitude, longitude: baseLongitude)
                    
                    // Cluster 2: remaining properties in another location
                    let cluster2Size = propertyCount - cluster1Size
                    let cluster2Center = Coordinate(latitude: baseLatitude + 0.01, longitude: baseLongitude + 0.01)
                    
                    var testProperties: [RealDeal.Property] = []
                    
                    // Create cluster 1 properties (very close together - within 0.0001 degrees ~11 meters)
                    for i in 0..<cluster1Size {
                        let template = validPropertyGen().resize(i * 73).generate
                        let offset = Double(i) * 0.00005 // Very small offset for clustering
                        
                        let property = RealDeal.Property(
                            id: UUID().uuidString,
                            address: template.address,
                            price: template.price,
                            propertyType: template.propertyType,
                            description: template.description,
                            specifications: template.specifications,
                            images: template.images,
                            location: Coordinate(
                                latitude: cluster1Center.latitude + offset,
                                longitude: cluster1Center.longitude + offset
                            ),
                            source: template.source,
                            sellerId: template.sellerId,
                            status: .active, // All active for map display
                            createdAt: template.createdAt,
                            updatedAt: template.updatedAt
                        )
                        
                        testProperties.append(property)
                    }
                    
                    // Create cluster 2 properties (very close together in different location)
                    for i in 0..<cluster2Size {
                        let template = validPropertyGen().resize((i + cluster1Size) * 73).generate
                        let offset = Double(i) * 0.00005 // Very small offset for clustering
                        
                        let property = RealDeal.Property(
                            id: UUID().uuidString,
                            address: template.address,
                            price: template.price,
                            propertyType: template.propertyType,
                            description: template.description,
                            specifications: template.specifications,
                            images: template.images,
                            location: Coordinate(
                                latitude: cluster2Center.latitude + offset,
                                longitude: cluster2Center.longitude + offset
                            ),
                            source: template.source,
                            sellerId: template.sellerId,
                            status: .active, // All active for map display
                            createdAt: template.createdAt,
                            updatedAt: template.updatedAt
                        )
                        
                        testProperties.append(property)
                    }
                    
                    // Save all properties to storage
                    try await localDataSource.saveProperties(testProperties)
                    mockRemote.seedData(properties: testProperties)
                    
                    // Create MapViewModel
                    let locationManager = LocationManager()
                    let filterService = FilterService()
                    let mapViewModel = MapViewModel(
                        repository: repository,
                        filterService: filterService,
                        locationManager: locationManager
                    )
                    
                    // Load properties into the map view model
                    await mapViewModel.loadProperties()
                    
                    // Check for errors
                    guard mapViewModel.errorMessage == nil else {
                        result = false
                        expectation.fulfill()
                        return
                    }
                    
                    // Step 1: Verify all properties are represented as annotations
                    guard mapViewModel.annotations.count == propertyCount else {
                        result = false
                        expectation.fulfill()
                        return
                    }
                    
                    // Step 2: Verify each annotation has the clustering identifier set
                    // This is the key property that enables MapKit clustering
                    // We verify this by checking that PropertyAnnotation instances are created
                    // and that they have valid coordinates for clustering
                    for annotation in mapViewModel.annotations {
                        // Verify annotation has valid coordinates
                        let coordinate = annotation.coordinate
                        guard coordinate.latitude >= -90 && coordinate.latitude <= 90,
                              coordinate.longitude >= -180 && coordinate.longitude <= 180 else {
                            result = false
                            expectation.fulfill()
                            return
                        }
                        
                        // Verify annotation is a PropertyAnnotation (which supports clustering)
                        guard annotation is PropertyAnnotation else {
                            result = false
                            expectation.fulfill()
                            return
                        }
                    }
                    
                    // Step 3: Verify that nearby properties can be identified
                    // Group annotations by proximity to verify clustering potential
                    let cluster1Annotations = mapViewModel.annotations.filter { annotation in
                        let distance = self.calculateDistance(
                            from: annotation.coordinate,
                            to: CLLocationCoordinate2D(
                                latitude: cluster1Center.latitude,
                                longitude: cluster1Center.longitude
                            )
                        )
                        return distance < 500 // Within 500 meters of cluster 1 center
                    }
                    
                    let cluster2Annotations = mapViewModel.annotations.filter { annotation in
                        let distance = self.calculateDistance(
                            from: annotation.coordinate,
                            to: CLLocationCoordinate2D(
                                latitude: cluster2Center.latitude,
                                longitude: cluster2Center.longitude
                            )
                        )
                        return distance < 500 // Within 500 meters of cluster 2 center
                    }
                    
                    // Step 4: Verify that the annotations are properly distributed into clusters
                    // The sum of annotations in both clusters should equal total annotations
                    guard cluster1Annotations.count + cluster2Annotations.count == propertyCount else {
                        result = false
                        expectation.fulfill()
                        return
                    }
                    
                    // Step 5: Verify cluster sizes match expected sizes
                    guard cluster1Annotations.count == cluster1Size,
                          cluster2Annotations.count == cluster2Size else {
                        result = false
                        expectation.fulfill()
                        return
                    }
                    
                    // Step 6: Verify that the clustering identifier is set correctly
                    // This is what tells MapKit to cluster these annotations
                    // We verify this indirectly by confirming the MapViewModel has the clustering identifier
                    guard MapViewModel.clusteringIdentifier == "propertyCluster" else {
                        result = false
                        expectation.fulfill()
                        return
                    }
                    
                    // All checks passed - clustering is properly configured
                    // MapKit will handle the actual visual clustering based on zoom level
                    result = true
                    expectation.fulfill()
                } catch {
                    // Test failed due to error
                    result = false
                    expectation.fulfill()
                }
            }
            
            self.wait(for: [expectation], timeout: 10.0)
            return result
        }
    }
    
    /// Helper method to calculate distance between two coordinates in meters
    private func calculateDistance(from coord1: CLLocationCoordinate2D, to coord2: CLLocationCoordinate2D) -> Double {
        let location1 = CLLocation(latitude: coord1.latitude, longitude: coord1.longitude)
        let location2 = CLLocation(latitude: coord2.latitude, longitude: coord2.longitude)
        return location1.distance(from: location2)
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
    
    /// Generate valid image data for testing (creates a minimal valid JPEG)
    func generateValidImageData() -> Data {
        #if canImport(UIKit)
        // Create a small valid JPEG image
        let size = CGSize(width: 100, height: 100)
        
        UIGraphicsBeginImageContext(size)
        defer { UIGraphicsEndImageContext() }
        
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        context.fill(CGRect(origin: .zero, size: size))
        
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        return image.jpegData(compressionQuality: 0.8)!
        #else
        // Fallback: minimal valid JPEG header + data
        var data = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46])
        data.append(Data(repeating: 0x00, count: 100))
        return data
        #endif
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
    // Fallback for non-UIKit platforms: generate JPEG data that meets minimum size (1KB)
    Gen.pure({
        var data = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10]) // JPEG header
        // Pad with valid JPEG data to meet 1KB minimum
        data.append(Data(repeating: 0x00, count: 1024 - data.count))
        data.append(Data([0xFF, 0xD9])) // JPEG end marker
        return data
    }())
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
    // Fallback for non-UIKit platforms: generate PNG data that meets minimum size (1KB)
    Gen.pure({
        var data = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]) // PNG header
        // Pad with valid PNG data to meet 1KB minimum
        data.append(Data(repeating: 0x00, count: 1024 - data.count))
        return data
    }())
    #endif
}

// MARK: - Generators for Authentication Data

/// Struct to hold valid credentials for testing
struct ValidCredentials {
    let email: String
    let password: String
    let name: String
}

/// Generator for valid credentials (email, password, name)
func validCredentialsGen() -> Gen<ValidCredentials> {
    Gen.compose { c in
        // Generate valid email addresses
        let emailPrefixes = ["john.doe", "jane.smith", "bob.jones", "alice.williams", "charlie.brown", 
                            "david.miller", "emma.davis", "frank.wilson", "grace.moore", "henry.taylor"]
        let emailDomains = ["example.com", "test.com", "demo.org", "sample.net", "mail.com"]
        
        let prefix = c.generate(using: Gen.fromElements(of: emailPrefixes))
        let domain = c.generate(using: Gen.fromElements(of: emailDomains))
        let email = "\(prefix)@\(domain)"
        
        // Generate valid passwords (at least 8 characters with letters and numbers)
        let passwords = ["password123", "SecurePass1", "TestUser99", "MyPass2024", "Welcome123",
                        "Account456", "Login789", "Access2023", "User1234", "Demo5678"]
        let password = c.generate(using: Gen.fromElements(of: passwords))
        
        // Generate valid names
        let names = ["John Doe", "Jane Smith", "Bob Jones", "Alice Williams", "Charlie Brown",
                    "David Miller", "Emma Davis", "Frank Wilson", "Grace Moore", "Henry Taylor"]
        let name = c.generate(using: Gen.fromElements(of: names))
        
        return ValidCredentials(email: email, password: password, name: name)
    }
}

/// Struct to hold invalid credentials for testing
struct InvalidCredentials {
    let attemptEmail: String
    let attemptPassword: String
    let registeredUser: ValidCredentials? // If non-nil, this user should be registered first
}

/// Generator for invalid credentials (various failure scenarios)
func invalidCredentialsGen() -> Gen<InvalidCredentials> {
    Gen.one(of: [
        // Scenario 1: Unregistered email (user doesn't exist)
        unregisteredEmailGen(),
        // Scenario 2: Wrong password for registered user
        wrongPasswordGen(),
        // Scenario 3: Invalid email format
        invalidEmailFormatGen(),
        // Scenario 4: Empty password
        emptyPasswordGen(),
        // Scenario 5: Empty email
        emptyEmailGen()
    ])
}

/// Generator for unregistered email scenario
func unregisteredEmailGen() -> Gen<InvalidCredentials> {
    Gen.compose { c in
        let unregisteredEmails = ["nonexistent@example.com", "notregistered@test.com", 
                                 "unknown@demo.org", "fake@sample.net", "invalid@mail.com"]
        let email = c.generate(using: Gen.fromElements(of: unregisteredEmails))
        let password = c.generate(using: Gen.fromElements(of: ["password123", "anypassword", "test1234"]))
        
        return InvalidCredentials(
            attemptEmail: email,
            attemptPassword: password,
            registeredUser: nil
        )
    }
}

/// Generator for wrong password scenario (user exists but password is wrong)
func wrongPasswordGen() -> Gen<InvalidCredentials> {
    Gen.compose { c in
        // Generate a registered user
        let registeredUser = validCredentialsGen().generate
        
        // Generate a different password
        let wrongPasswords = ["wrongpass123", "incorrect1", "badpassword99", "notright456", "wrong789"]
        let wrongPassword = c.generate(using: Gen.fromElements(of: wrongPasswords))
        
        return InvalidCredentials(
            attemptEmail: registeredUser.email,
            attemptPassword: wrongPassword,
            registeredUser: registeredUser
        )
    }
}

/// Generator for invalid email format scenario
func invalidEmailFormatGen() -> Gen<InvalidCredentials> {
    Gen.compose { c in
        let invalidEmails = ["notanemail", "missing@domain", "@nodomain.com", "no-at-sign.com",
                           "double@@example.com", "spaces in@email.com", "invalid@", "test@.com"]
        let email = c.generate(using: Gen.fromElements(of: invalidEmails))
        let password = c.generate(using: Gen.fromElements(of: ["password123", "test1234"]))
        
        return InvalidCredentials(
            attemptEmail: email,
            attemptPassword: password,
            registeredUser: nil
        )
    }
}

/// Generator for empty password scenario
func emptyPasswordGen() -> Gen<InvalidCredentials> {
    Gen.compose { c in
        let validEmail = "test@example.com"
        
        return InvalidCredentials(
            attemptEmail: validEmail,
            attemptPassword: "",
            registeredUser: nil
        )
    }
}

/// Generator for empty email scenario
func emptyEmailGen() -> Gen<InvalidCredentials> {
    Gen.compose { c in
        let password = c.generate(using: Gen.fromElements(of: ["password123", "test1234"]))
        
        return InvalidCredentials(
            attemptEmail: "",
            attemptPassword: password,
            registeredUser: nil
        )
    }
}

// MARK: - Generators for Registration Data

/// Struct to hold registration data for testing
struct RegistrationData {
    let email: String
    let password: String
    let profile: UserProfile
}

/// Generator for valid registration data
func validRegistrationDataGen() -> Gen<RegistrationData> {
    Gen.compose { c in
        // Generate valid email addresses (unique to avoid conflicts)
        let emailPrefixes = ["john.doe", "jane.smith", "bob.jones", "alice.williams", "charlie.brown", 
                            "david.miller", "emma.davis", "frank.wilson", "grace.moore", "henry.taylor"]
        let emailDomains = ["example.com", "test.com", "demo.org", "sample.net", "mail.com"]
        
        let prefix = c.generate(using: Gen.fromElements(of: emailPrefixes))
        let domain = c.generate(using: Gen.fromElements(of: emailDomains))
        let email = "\(prefix)-\(UUID().uuidString.prefix(8))@\(domain)"
        
        // Generate valid passwords (at least 8 characters with letters and numbers)
        let passwords = ["password123", "SecurePass1", "TestUser99", "MyPass2024", "Welcome123",
                        "Account456", "Login789", "Access2023", "User1234", "Demo5678"]
        let password = c.generate(using: Gen.fromElements(of: passwords))
        
        // Generate valid profile
        let names = ["John Doe", "Jane Smith", "Bob Jones", "Alice Williams", "Charlie Brown",
                    "David Miller", "Emma Davis", "Frank Wilson", "Grace Moore", "Henry Taylor"]
        let name = c.generate(using: Gen.fromElements(of: names))
        
        let phoneNumbers: [String?] = [nil, "555-0100", "555-0101", "(555) 123-4567", "+1-555-987-6543"]
        let phoneNumber = c.generate(using: Gen.fromElements(of: phoneNumbers))
        
        let roles = [UserRole.buyer, UserRole.seller, UserRole.both]
        let role = c.generate(using: Gen.fromElements(of: roles))
        
        let profile = UserProfile(
            name: name,
            email: email,
            phoneNumber: phoneNumber,
            role: role
        )
        
        return RegistrationData(email: email, password: password, profile: profile)
    }
}

/// Generator for invalid registration data (various validation failure scenarios)
func invalidRegistrationDataGen() -> Gen<RegistrationData> {
    Gen.one(of: [
        // Scenario 1: Invalid email format
        invalidEmailRegistrationGen(),
        // Scenario 2: Weak password (too short)
        weakPasswordTooShortGen(),
        // Scenario 3: Weak password (no letters)
        weakPasswordNoLettersGen(),
        // Scenario 4: Weak password (no numbers)
        weakPasswordNoNumbersGen(),
        // Scenario 5: Empty name
        emptyNameRegistrationGen(),
        // Scenario 6: Whitespace-only name
        whitespaceNameRegistrationGen()
    ])
}

/// Generator for registration with invalid email format
func invalidEmailRegistrationGen() -> Gen<RegistrationData> {
    Gen.compose { c in
        let invalidEmails = ["notanemail", "missing@domain", "@nodomain.com", "no-at-sign.com",
                           "double@@example.com", "spaces in@email.com", "invalid@", "test@.com",
                           "test..double@example.com", ".startdot@example.com", "enddot.@example.com"]
        let email = c.generate(using: Gen.fromElements(of: invalidEmails))
        
        // Use valid password and profile
        let password = c.generate(using: Gen.fromElements(of: ["password123", "SecurePass1", "TestUser99"]))
        let name = c.generate(using: Gen.fromElements(of: ["John Doe", "Jane Smith", "Bob Jones"]))
        
        let profile = UserProfile(
            name: name,
            email: email,
            role: .buyer
        )
        
        return RegistrationData(email: email, password: password, profile: profile)
    }
}

/// Generator for registration with password that's too short
func weakPasswordTooShortGen() -> Gen<RegistrationData> {
    Gen.compose { c in
        // Generate passwords shorter than 8 characters
        let shortPasswords = ["pass1", "abc123", "test1", "pw12", "a1", "short7", "weak12"]
        let password = c.generate(using: Gen.fromElements(of: shortPasswords))
        
        // Use valid email and profile (unique email to avoid conflicts)
        let emailPrefix = c.generate(using: Gen.fromElements(of: ["user1", "user2", "user3", "user4", "user5"]))
        let email = "\(emailPrefix)-\(UUID().uuidString.prefix(8))@example.com"
        let name = c.generate(using: Gen.fromElements(of: ["John Doe", "Jane Smith", "Bob Jones"]))
        
        let profile = UserProfile(
            name: name,
            email: email,
            role: .buyer
        )
        
        return RegistrationData(email: email, password: password, profile: profile)
    }
}

/// Generator for registration with password that has no letters
func weakPasswordNoLettersGen() -> Gen<RegistrationData> {
    Gen.compose { c in
        // Generate passwords with only numbers (no letters)
        let noLetterPasswords = ["12345678", "98765432", "11111111", "00000000", "123456789"]
        let password = c.generate(using: Gen.fromElements(of: noLetterPasswords))
        
        // Use valid email and profile (unique email to avoid conflicts)
        let emailPrefix = c.generate(using: Gen.fromElements(of: ["user1", "user2", "user3", "user4", "user5"]))
        let email = "\(emailPrefix)-\(UUID().uuidString.prefix(8))@example.com"
        let name = c.generate(using: Gen.fromElements(of: ["John Doe", "Jane Smith", "Bob Jones"]))
        
        let profile = UserProfile(
            name: name,
            email: email,
            role: .buyer
        )
        
        return RegistrationData(email: email, password: password, profile: profile)
    }
}

/// Generator for registration with password that has no numbers
func weakPasswordNoNumbersGen() -> Gen<RegistrationData> {
    Gen.compose { c in
        // Generate passwords with only letters (no numbers)
        let noNumberPasswords = ["password", "testuser", "abcdefgh", "nodigits", "onlyletters"]
        let password = c.generate(using: Gen.fromElements(of: noNumberPasswords))
        
        // Use valid email and profile (unique email to avoid conflicts)
        let emailPrefix = c.generate(using: Gen.fromElements(of: ["user1", "user2", "user3", "user4", "user5"]))
        let email = "\(emailPrefix)-\(UUID().uuidString.prefix(8))@example.com"
        let name = c.generate(using: Gen.fromElements(of: ["John Doe", "Jane Smith", "Bob Jones"]))
        
        let profile = UserProfile(
            name: name,
            email: email,
            role: .buyer
        )
        
        return RegistrationData(email: email, password: password, profile: profile)
    }
}

/// Generator for registration with empty name
func emptyNameRegistrationGen() -> Gen<RegistrationData> {
    Gen.compose { c in
        // Use valid email and password (unique email to avoid conflicts)
        let emailPrefix = c.generate(using: Gen.fromElements(of: ["user1", "user2", "user3", "user4", "user5"]))
        let email = "\(emailPrefix)-\(UUID().uuidString.prefix(8))@example.com"
        let password = c.generate(using: Gen.fromElements(of: ["password123", "SecurePass1", "TestUser99"]))
        
        // Empty name
        let profile = UserProfile(
            name: "",
            email: email,
            role: .buyer
        )
        
        return RegistrationData(email: email, password: password, profile: profile)
    }
}

/// Generator for registration with whitespace-only name
func whitespaceNameRegistrationGen() -> Gen<RegistrationData> {
    Gen.compose { c in
        // Use valid email and password (unique email to avoid conflicts)
        let emailPrefix = c.generate(using: Gen.fromElements(of: ["user1", "user2", "user3", "user4", "user5"]))
        let email = "\(emailPrefix)-\(UUID().uuidString.prefix(8))@example.com"
        let password = c.generate(using: Gen.fromElements(of: ["password123", "SecurePass1", "TestUser99"]))
        
        // Whitespace-only name
        let whitespaceName = c.generate(using: Gen.fromElements(of: ["   ", "\t", "\n", "  \t\n  ", "\t\t\t"]))
        
        let profile = UserProfile(
            name: whitespaceName,
            email: email,
            role: .buyer
        )
        
        return RegistrationData(email: email, password: password, profile: profile)
    }
}

// MARK: - Generator for Seller Profiles

/// Generator for valid seller profiles (profiles with seller or both role)
func validSellerProfileGen() -> Gen<UserProfile> {
    Gen.compose { c in
        let names = ["John Seller", "Jane Realtor", "Bob Agent", "Alice Broker", "Charlie Dealer"]
        let emails = ["seller1@example.com", "seller2@example.com", "seller3@example.com", "seller4@example.com", "seller5@example.com"]
        let phoneNumbers: [String?] = ["555-0100", "555-0101", "555-0102", "(555) 123-4567", "+1-555-987-6543"]
        let photoURLs: [URL?] = [
            nil,
            URL(string: "https://example.com/seller1.jpg"),
            URL(string: "https://example.com/seller2.png"),
            URL(string: "https://example.com/seller3.jpeg")
        ]
        // Seller profiles should have seller or both role
        let roles = [UserRole.seller, UserRole.both]
        
        let name = c.generate(using: Gen.fromElements(of: names))
        let email = c.generate(using: Gen.fromElements(of: emails))
        let phoneNumber = c.generate(using: Gen.fromElements(of: phoneNumbers))
        let profilePhotoURL = c.generate(using: Gen.fromElements(of: photoURLs))
        let role = c.generate(using: Gen.fromElements(of: roles))
        
        // Seller profiles should have contact info visible for buyers to contact them
        let visibilitySettings = ProfileVisibility(
            showEmail: true,
            showPhone: true,
            showListings: true
        )
        
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

// MARK: - Property-Based Test for Profile Visibility Enforcement

extension PropertyBasedTests {
    /// Feature: real-estate-listings, Property 26: Profile visibility settings enforcement
    /// Validates: Requirements 7.5
    func testProfileVisibilitySettingsEnforcement() {
        // Test that when a profile is displayed to other users, only information marked as visible is shown
        property("Profile visibility settings should be enforced when displaying to other users") <- forAll(Gen.fromElements(in: 0...100)) { (seed: Int) in
            let testProfile = validUserProfileGen().resize(seed).generate
            let expectation = XCTestExpectation(description: "Profile visibility enforcement")
            var result = false
            
            Task { @MainActor in
                // Use in-memory persistence controller for testing
                let testPersistence = PersistenceController(inMemory: true)
                let localDataSource = LocalDataSource(persistenceController: testPersistence)
                let mockRemote = MockRemoteDataSource(simulateNetworkDelay: false)
                let repository = UserProfileRepository(
                    localDataSource: localDataSource,
                    remoteDataSource: mockRemote
                )
                
                let viewModel = ProfileViewModel(repository: repository)
                
                // Get filtered profile for display to other users (not own profile)
                let filteredProfile = viewModel.getFilteredProfile(testProfile, isOwnProfile: false)
                
                // Verify visibility settings are enforced
                var checksPass = true
                
                // Check email visibility
                if !testProfile.visibilitySettings.showEmail {
                    // Email should be hidden (replaced with "Hidden")
                    checksPass = checksPass && (filteredProfile.email == "Hidden")
                } else {
                    // Email should be visible (unchanged)
                    checksPass = checksPass && (filteredProfile.email == testProfile.email)
                }
                
                // Check phone visibility
                if !testProfile.visibilitySettings.showPhone {
                    // Phone should be hidden (set to nil)
                    checksPass = checksPass && (filteredProfile.phoneNumber == nil)
                } else {
                    // Phone should be visible (unchanged)
                    checksPass = checksPass && (filteredProfile.phoneNumber == testProfile.phoneNumber)
                }
                
                // Other fields should always be visible (name, role, photo, etc.)
                checksPass = checksPass && (filteredProfile.name == testProfile.name)
                checksPass = checksPass && (filteredProfile.role == testProfile.role)
                checksPass = checksPass && (filteredProfile.profilePhotoURL == testProfile.profilePhotoURL)
                checksPass = checksPass && (filteredProfile.id == testProfile.id)
                
                result = checksPass
                expectation.fulfill()
            }
            
            self.wait(for: [expectation], timeout: 5.0)
            return result
        }
        
        // Test that own profile always shows all information regardless of visibility settings
        property("Own profile should always show all information regardless of visibility settings") <- forAll(Gen.fromElements(in: 0...100)) { (seed: Int) in
            let testProfile = validUserProfileGen().resize(seed).generate
            let expectation = XCTestExpectation(description: "Own profile visibility")
            var result = false
            
            Task { @MainActor in
                // Use in-memory persistence controller for testing
                let testPersistence = PersistenceController(inMemory: true)
                let localDataSource = LocalDataSource(persistenceController: testPersistence)
                let mockRemote = MockRemoteDataSource(simulateNetworkDelay: false)
                let repository = UserProfileRepository(
                    localDataSource: localDataSource,
                    remoteDataSource: mockRemote
                )
                
                let viewModel = ProfileViewModel(repository: repository)
                
                // Get filtered profile for own profile display
                let filteredProfile = viewModel.getFilteredProfile(testProfile, isOwnProfile: true)
                
                // Verify all fields are unchanged (no filtering applied)
                result = self.profilesAreEquivalent(testProfile, filteredProfile)
                expectation.fulfill()
            }
            
            self.wait(for: [expectation], timeout: 5.0)
            return result
        }
    }
    
    // MARK: - Property-Based Test for Seller Listing Filtering
    
    /// Feature: real-estate-listings, Property 5: Seller listing filtering
    /// Validates: Requirements 2.1
    func testSellerListingFiltering() {
        // Test that querying for a specific seller's listings returns only listings created by that seller
        property("Seller listing filtering should return only properties created by that seller") <- forAll(Gen.fromElements(in: 2...5)) { (sellerCount: Int) in
            let expectation = XCTestExpectation(description: "Seller listing filtering")
            var result = false
            
            Task {
                do {
                    // Use in-memory persistence controller for testing
                    let testPersistence = PersistenceController(inMemory: true)
                    let localDataSource = LocalDataSource(persistenceController: testPersistence)
                    
                    // Step 1: Create multiple sellers
                    let sellerIds = (0..<sellerCount).map { "seller-\($0)-\(UUID().uuidString)" }
                    
                    // Step 2: Create properties for each seller (2-4 properties per seller)
                    var allProperties: [RealDeal.Property] = []
                    var propertiesBySeller: [String: [RealDeal.Property]] = [:]
                    
                    for sellerId in sellerIds {
                        let propertyCount = Int.random(in: 2...4)
                        let sellerProperties = (0..<propertyCount).map { _ in
                            var property = validPropertyGen().generate
                            property.sellerId = sellerId
                            property.status = .active // Ensure active status
                            return property
                        }
                        propertiesBySeller[sellerId] = sellerProperties
                        allProperties.append(contentsOf: sellerProperties)
                    }
                    
                    // Step 3: Save all properties to storage
                    try await localDataSource.saveProperties(allProperties)
                    
                    // Step 4: For each seller, query their properties and verify filtering
                    var allChecksPass = true
                    
                    for sellerId in sellerIds {
                        // Create filter for this specific seller
                        let filters = PropertyFilters(sellerId: sellerId)
                        
                        // Fetch properties for this seller
                        let fetchedProperties = try await localDataSource.fetchProperties(filters: filters)
                        
                        // Get expected properties for this seller
                        let expectedProperties = propertiesBySeller[sellerId] ?? []
                        
                        // Check 1: Count should match
                        guard fetchedProperties.count == expectedProperties.count else {
                            allChecksPass = false
                            break
                        }
                        
                        // Check 2: All fetched properties should belong to this seller
                        let allBelongToSeller = fetchedProperties.allSatisfy { property in
                            property.sellerId == sellerId
                        }
                        guard allBelongToSeller else {
                            allChecksPass = false
                            break
                        }
                        
                        // Check 3: All expected properties should be in the fetched results
                        let expectedIds = Set(expectedProperties.map { $0.id })
                        let fetchedIds = Set(fetchedProperties.map { $0.id })
                        guard expectedIds == fetchedIds else {
                            allChecksPass = false
                            break
                        }
                        
                        // Check 4: No properties from other sellers should be included
                        let otherSellerIds = sellerIds.filter { $0 != sellerId }
                        for otherSellerId in otherSellerIds {
                            let hasOtherSellerProperty = fetchedProperties.contains { property in
                                property.sellerId == otherSellerId
                            }
                            guard !hasOtherSellerProperty else {
                                allChecksPass = false
                                break
                            }
                        }
                        
                        if !allChecksPass {
                            break
                        }
                    }
                    
                    result = allChecksPass
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
    
    // MARK: - Property-Based Test for Sold Listings Exclusion
    
    /// Feature: real-estate-listings, Property 8: Sold listings excluded from buyer searches
    /// Validates: Requirements 2.5
    func testSoldListingsExcludedFromBuyerSearches() {
        // Test that properties marked as sold do not appear in buyer search results
        property("Sold listings should be excluded from buyer searches") <- forAll(Gen.fromElements(in: 2...10)) { (propertyCount: Int) in
            let expectation = XCTestExpectation(description: "Sold listings exclusion from buyer searches")
            var result = false
            
            Task {
                do {
                    // Use in-memory persistence controller for testing
                    let testPersistence = PersistenceController(inMemory: true)
                    let localDataSource = LocalDataSource(persistenceController: testPersistence)
                    
                    // Step 1: Create a mix of properties with different statuses
                    var allProperties: [RealDeal.Property] = []
                    var activeProperties: [RealDeal.Property] = []
                    var soldProperties: [RealDeal.Property] = []
                    var pendingProperties: [RealDeal.Property] = []
                    
                    for i in 0..<propertyCount {
                        var property = validPropertyGen().generate
                        
                        // Assign different statuses to properties
                        if i % 3 == 0 {
                            property.status = .sold
                            soldProperties.append(property)
                        } else if i % 3 == 1 {
                            property.status = .active
                            activeProperties.append(property)
                        } else {
                            property.status = .pending
                            pendingProperties.append(property)
                        }
                        
                        allProperties.append(property)
                    }
                    
                    // Step 2: Save all properties to storage
                    try await localDataSource.saveProperties(allProperties)
                    
                    // Step 3: Perform a buyer search (no filters - should return all non-sold, non-deleted properties)
                    // Buyer searches should exclude sold properties
                    let buyerSearchResults = try await localDataSource.fetchProperties(filters: nil)
                    
                    // Step 4: Verify that no sold properties appear in the results
                    let hasSoldProperty = buyerSearchResults.contains { property in
                        property.status == .sold
                    }
                    guard !hasSoldProperty else {
                        result = false
                        expectation.fulfill()
                        return
                    }
                    
                    // Step 5: Verify that active and pending properties DO appear in results
                    // (This ensures we're not just returning an empty list)
                    let expectedNonSoldCount = activeProperties.count + pendingProperties.count
                    guard buyerSearchResults.count == expectedNonSoldCount else {
                        result = false
                        expectation.fulfill()
                        return
                    }
                    
                    // Step 6: Verify each sold property is NOT in the results
                    for soldProperty in soldProperties {
                        let foundInResults = buyerSearchResults.contains { $0.id == soldProperty.id }
                        guard !foundInResults else {
                            result = false
                            expectation.fulfill()
                            return
                        }
                    }
                    
                    // Step 7: Verify each active/pending property IS in the results
                    let expectedPropertyIds = Set(activeProperties.map { $0.id } + pendingProperties.map { $0.id })
                    let resultPropertyIds = Set(buyerSearchResults.map { $0.id })
                    guard expectedPropertyIds == resultPropertyIds else {
                        result = false
                        expectation.fulfill()
                        return
                    }
                    
                    // Step 8: Test with various filters to ensure sold properties are excluded regardless of filter
                    // Test with price filter
                    if let firstSoldProperty = soldProperties.first {
                        let priceFilters = PropertyFilters(
                            priceMin: firstSoldProperty.price - 1000,
                            priceMax: firstSoldProperty.price + 1000
                        )
                        let priceFilteredResults = try await localDataSource.fetchProperties(filters: priceFilters)
                        
                        // Verify the sold property doesn't appear even though it matches the price range
                        let soldFoundInPriceFilter = priceFilteredResults.contains { $0.id == firstSoldProperty.id }
                        guard !soldFoundInPriceFilter else {
                            result = false
                            expectation.fulfill()
                            return
                        }
                    }
                    
                    // Step 9: Test with property type filter
                    if let firstSoldProperty = soldProperties.first {
                        let typeFilters = PropertyFilters(
                            propertyTypes: [firstSoldProperty.propertyType]
                        )
                        let typeFilteredResults = try await localDataSource.fetchProperties(filters: typeFilters)
                        
                        // Verify the sold property doesn't appear even though it matches the type
                        let soldFoundInTypeFilter = typeFilteredResults.contains { $0.id == firstSoldProperty.id }
                        guard !soldFoundInTypeFilter else {
                            result = false
                            expectation.fulfill()
                            return
                        }
                    }
                    
                    // All checks passed - sold properties are correctly excluded from buyer searches
                    result = true
                    expectation.fulfill()
                } catch {
                    // Search or verification failed
                    result = false
                    expectation.fulfill()
                }
            }
            
            self.wait(for: [expectation], timeout: 10.0)
            return result
        }
    }
    
    // MARK: - Property-Based Test for Seller Profile Display Completeness
    
    /// Feature: real-estate-listings, Property 24: Seller profile display completeness
    /// Validates: Requirements 7.3
    func testSellerProfileDisplayCompleteness() {
        // Test that seller profiles display contact information and active listings count
        property("Seller profile should display contact information and active listings count") <- forAll(Gen.fromElements(in: 0...100)) { (seed: Int) in
            // Generate a seller profile with visible contact information
            let sellerProfile = validSellerProfileGen().resize(seed).generate
            
            // Generate some active properties for this seller
            let activeListingsCount = seed % 10 // 0-9 active listings
            let activeProperties = (0..<activeListingsCount).map { _ in
                var property = validPropertyGen().generate
                property.sellerId = sellerProfile.id
                property.status = .active
                return property
            }
            
            let expectation = XCTestExpectation(description: "Seller profile display completeness")
            var result = false
            
            Task { @MainActor in
                do {
                    // Use in-memory persistence controller for testing
                    let testPersistence = PersistenceController(inMemory: true)
                    let localDataSource = LocalDataSource(persistenceController: testPersistence)
                    
                    // Save the seller profile
                    try await localDataSource.saveUserProfile(sellerProfile)
                    
                    // Save the active properties
                    try await localDataSource.saveProperties(activeProperties)
                    
                    // Fetch the seller's active properties directly from local storage
                    // (This simulates what the UI would do to display the count)
                    let allProperties = try await localDataSource.fetchProperties(filters: nil)
                    let sellerActiveProperties = allProperties.filter { 
                        $0.sellerId == sellerProfile.id && $0.status == .active 
                    }
                    
                    // Verify completeness of seller profile display
                    var checksPass = true
                    
                    // 1. Contact information should be available
                    // Name should be present
                    checksPass = checksPass && !sellerProfile.name.isEmpty
                    
                    // Email should be present
                    checksPass = checksPass && !sellerProfile.email.isEmpty
                    
                    // Phone should be available if set (respecting visibility)
                    // For seller profiles, we expect contact info to be visible
                    if sellerProfile.visibilitySettings.showPhone && sellerProfile.phoneNumber != nil {
                        checksPass = checksPass && !sellerProfile.phoneNumber!.isEmpty
                    }
                    
                    // 2. Active listings count should be retrievable and accurate
                    checksPass = checksPass && (sellerActiveProperties.count == activeListingsCount)
                    
                    // 3. Profile should have seller or both role
                    checksPass = checksPass && (sellerProfile.role == .seller || sellerProfile.role == .both)
                    
                    result = checksPass
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
    
    // MARK: - Property-Based Test for Price Range Filter Correctness
    
    /// Feature: real-estate-listings, Property 11: Price range filter correctness
    /// Validates: Requirements 4.1
    func testPriceRangeFilterCorrectness() {
        // Test that all returned results have prices within the specified range
        property("Price range filter should return only properties within the specified price range") <- forAll(Gen.fromElements(in: 5...20)) { (propertyCount: Int) in
            let expectation = XCTestExpectation(description: "Price range filter correctness")
            var result = false
            
            Task {
                do {
                    // Use in-memory persistence controller for testing
                    let testPersistence = PersistenceController(inMemory: true)
                    let localDataSource = LocalDataSource(persistenceController: testPersistence)
                    let filterService = FilterService()
                    
                    // Step 1: Generate a diverse set of properties with various prices
                    let properties = (0..<propertyCount).map { i -> RealDeal.Property in
                        var property = validPropertyGen().generate
                        // Create a wide range of prices from $50k to $5M
                        let priceValue = 50000 + (i * 250000)
                        property.price = Decimal(priceValue)
                        property.status = .active
                        return property
                    }
                    
                    // Step 2: Save all properties to storage
                    try await localDataSource.saveProperties(properties)
                    
                    // Step 3: Generate random price range for filtering
                    // Pick a min price somewhere in the lower half of our range
                    let minPriceValue = Int.random(in: 100000...2000000)
                    let minPrice = Decimal(minPriceValue)
                    
                    // Pick a max price somewhere above the min price
                    let maxPriceValue = Int.random(in: (minPriceValue + 100000)...4000000)
                    let maxPrice = Decimal(maxPriceValue)
                    
                    // Step 4: Create filter with price range
                    let filters = PropertyFilters(
                        priceMin: minPrice,
                        priceMax: maxPrice
                    )
                    
                    // Step 5: Fetch all properties first (to apply filter service)
                    let allProperties = try await localDataSource.fetchProperties(filters: nil)
                    
                    // Step 6: Apply price range filter using FilterService
                    let filteredProperties = try filterService.applyFilters(allProperties, filters: filters)
                    
                    // Step 7: Verify all returned properties are within the price range
                    let allWithinRange = filteredProperties.allSatisfy { property in
                        property.price >= minPrice && property.price <= maxPrice
                    }
                    
                    guard allWithinRange else {
                        result = false
                        expectation.fulfill()
                        return
                    }
                    
                    // Step 8: Verify no properties outside the range are included
                    let propertiesOutsideRange = allProperties.filter { property in
                        property.price < minPrice || property.price > maxPrice
                    }
                    
                    for outsideProperty in propertiesOutsideRange {
                        let foundInFiltered = filteredProperties.contains { $0.id == outsideProperty.id }
                        guard !foundInFiltered else {
                            result = false
                            expectation.fulfill()
                            return
                        }
                    }
                    
                    // Step 9: Verify all properties within the range ARE included
                    let propertiesInsideRange = allProperties.filter { property in
                        property.price >= minPrice && property.price <= maxPrice
                    }
                    
                    guard filteredProperties.count == propertiesInsideRange.count else {
                        result = false
                        expectation.fulfill()
                        return
                    }
                    
                    let expectedIds = Set(propertiesInsideRange.map { $0.id })
                    let filteredIds = Set(filteredProperties.map { $0.id })
                    
                    guard expectedIds == filteredIds else {
                        result = false
                        expectation.fulfill()
                        return
                    }
                    
                    // All checks passed
                    result = true
                    expectation.fulfill()
                } catch {
                    result = false
                    expectation.fulfill()
                }
            }
            
            self.wait(for: [expectation], timeout: 10.0)
            return result
        }
        
        // Test edge case: minimum price only
        property("Price range filter with only minimum price should return properties >= min price") <- forAll(Gen.fromElements(in: 5...15)) { (propertyCount: Int) in
            let expectation = XCTestExpectation(description: "Price range filter - min only")
            var result = false
            
            Task {
                do {
                    let testPersistence = PersistenceController(inMemory: true)
                    let localDataSource = LocalDataSource(persistenceController: testPersistence)
                    let filterService = FilterService()
                    
                    // Generate properties with various prices
                    let properties = (0..<propertyCount).map { i -> RealDeal.Property in
                        var property = validPropertyGen().generate
                        let priceValue = 100000 + (i * 200000)
                        property.price = Decimal(priceValue)
                        property.status = .active
                        return property
                    }
                    
                    try await localDataSource.saveProperties(properties)
                    
                    // Filter with only minimum price
                    let minPrice = Decimal(500000)
                    let filters = PropertyFilters(priceMin: minPrice, priceMax: nil)
                    
                    let allProperties = try await localDataSource.fetchProperties(filters: nil)
                    let filteredProperties = try filterService.applyFilters(allProperties, filters: filters)
                    
                    // Verify all returned properties have price >= minPrice
                    let allAboveMin = filteredProperties.allSatisfy { $0.price >= minPrice }
                    
                    // Verify no properties below min are included
                    let propertiesBelowMin = allProperties.filter { $0.price < minPrice }
                    let noBelowMinIncluded = propertiesBelowMin.allSatisfy { belowMinProp in
                        !filteredProperties.contains { $0.id == belowMinProp.id }
                    }
                    
                    result = allAboveMin && noBelowMinIncluded
                    expectation.fulfill()
                } catch {
                    result = false
                    expectation.fulfill()
                }
            }
            
            self.wait(for: [expectation], timeout: 10.0)
            return result
        }
        
        // Test edge case: maximum price only
        property("Price range filter with only maximum price should return properties <= max price") <- forAll(Gen.fromElements(in: 5...15)) { (propertyCount: Int) in
            let expectation = XCTestExpectation(description: "Price range filter - max only")
            var result = false
            
            Task {
                do {
                    let testPersistence = PersistenceController(inMemory: true)
                    let localDataSource = LocalDataSource(persistenceController: testPersistence)
                    let filterService = FilterService()
                    
                    // Generate properties with various prices
                    let properties = (0..<propertyCount).map { i -> RealDeal.Property in
                        var property = validPropertyGen().generate
                        let priceValue = 100000 + (i * 200000)
                        property.price = Decimal(priceValue)
                        property.status = .active
                        return property
                    }
                    
                    try await localDataSource.saveProperties(properties)
                    
                    // Filter with only maximum price
                    let maxPrice = Decimal(1000000)
                    let filters = PropertyFilters(priceMin: nil, priceMax: maxPrice)
                    
                    let allProperties = try await localDataSource.fetchProperties(filters: nil)
                    let filteredProperties = try filterService.applyFilters(allProperties, filters: filters)
                    
                    // Verify all returned properties have price <= maxPrice
                    let allBelowMax = filteredProperties.allSatisfy { $0.price <= maxPrice }
                    
                    // Verify no properties above max are included
                    let propertiesAboveMax = allProperties.filter { $0.price > maxPrice }
                    let noAboveMaxIncluded = propertiesAboveMax.allSatisfy { aboveMaxProp in
                        !filteredProperties.contains { $0.id == aboveMaxProp.id }
                    }
                    
                    result = allBelowMax && noAboveMaxIncluded
                    expectation.fulfill()
                } catch {
                    result = false
                    expectation.fulfill()
                }
            }
            
            self.wait(for: [expectation], timeout: 10.0)
            return result
        }
        
        // Test edge case: exact price match
        property("Price range filter should include properties with exact boundary prices") <- forAll(Gen.fromElements(in: 3...10)) { (propertyCount: Int) in
            let expectation = XCTestExpectation(description: "Price range filter - boundary inclusion")
            var result = false
            
            Task {
                do {
                    let testPersistence = PersistenceController(inMemory: true)
                    let localDataSource = LocalDataSource(persistenceController: testPersistence)
                    let filterService = FilterService()
                    
                    let minPrice = Decimal(500000)
                    let maxPrice = Decimal(1000000)
                    
                    // Create properties including some at exact boundaries
                    var properties: [RealDeal.Property] = []
                    
                    // Property at exact min price
                    var propertyAtMin = validPropertyGen().generate
                    propertyAtMin.price = minPrice
                    propertyAtMin.status = .active
                    properties.append(propertyAtMin)
                    
                    // Property at exact max price
                    var propertyAtMax = validPropertyGen().generate
                    propertyAtMax.price = maxPrice
                    propertyAtMax.status = .active
                    properties.append(propertyAtMax)
                    
                    // Properties within range
                    for i in 0..<propertyCount {
                        var property = validPropertyGen().generate
                        let priceValue = 600000 + (i * 50000)
                        property.price = Decimal(priceValue)
                        property.status = .active
                        properties.append(property)
                    }
                    
                    // Properties outside range
                    var propertyBelowMin = validPropertyGen().generate
                    propertyBelowMin.price = minPrice - 1000
                    propertyBelowMin.status = .active
                    properties.append(propertyBelowMin)
                    
                    var propertyAboveMax = validPropertyGen().generate
                    propertyAboveMax.price = maxPrice + 1000
                    propertyAboveMax.status = .active
                    properties.append(propertyAboveMax)
                    
                    try await localDataSource.saveProperties(properties)
                    
                    // Apply filter
                    let filters = PropertyFilters(priceMin: minPrice, priceMax: maxPrice)
                    let allProperties = try await localDataSource.fetchProperties(filters: nil)
                    let filteredProperties = try filterService.applyFilters(allProperties, filters: filters)
                    
                    // Verify properties at exact boundaries ARE included
                    let minPriceIncluded = filteredProperties.contains { $0.id == propertyAtMin.id }
                    let maxPriceIncluded = filteredProperties.contains { $0.id == propertyAtMax.id }
                    
                    // Verify properties outside boundaries are NOT included
                    let belowMinExcluded = !filteredProperties.contains { $0.id == propertyBelowMin.id }
                    let aboveMaxExcluded = !filteredProperties.contains { $0.id == propertyAboveMax.id }
                    
                    result = minPriceIncluded && maxPriceIncluded && belowMinExcluded && aboveMaxExcluded
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
    
    // MARK: - Property-Based Test for Property Type Filter
    
    /// Feature: real-estate-listings, Property 12: Property type filter correctness
    /// Validates: Requirements 4.2
    func testPropertyTypeFilterCorrectness() {
        // Test that all returned results match one of the selected property types
        property("Property type filter should return only properties matching selected types") <- forAll(Gen.fromElements(in: 5...20)) { (propertyCount: Int) in
            let expectation = XCTestExpectation(description: "Property type filter correctness")
            var result = false
            
            Task {
                do {
                    // Use in-memory persistence controller for testing
                    let testPersistence = PersistenceController(inMemory: true)
                    let localDataSource = LocalDataSource(persistenceController: testPersistence)
                    let filterService = FilterService()
                    
                    // Step 1: Generate a diverse set of properties with various types
                    let allTypes = PropertyType.allCases
                    let properties = (0..<propertyCount).map { i -> RealDeal.Property in
                        var property = validPropertyGen().generate
                        // Distribute properties across all types
                        property.propertyType = allTypes[i % allTypes.count]
                        property.status = .active
                        return property
                    }
                    
                    // Step 2: Save all properties to storage
                    try await localDataSource.saveProperties(properties)
                    
                    // Step 3: Randomly select 1-3 property types to filter by
                    let filterTypeCount = Int.random(in: 1...3)
                    let shuffledTypes = allTypes.shuffled()
                    let selectedTypes = Set(shuffledTypes.prefix(filterTypeCount))
                    
                    // Step 4: Create filter with selected property types
                    let filters = PropertyFilters(
                        propertyTypes: selectedTypes
                    )
                    
                    // Step 5: Fetch all properties first (to apply filter service)
                    let allProperties = try await localDataSource.fetchProperties(filters: nil)
                    
                    // Step 6: Apply property type filter using FilterService
                    let filteredProperties = try filterService.applyFilters(allProperties, filters: filters)
                    
                    // Step 7: Verify all returned properties match one of the selected types
                    let allMatchSelectedTypes = filteredProperties.allSatisfy { property in
                        selectedTypes.contains(property.propertyType)
                    }
                    
                    guard allMatchSelectedTypes else {
                        result = false
                        expectation.fulfill()
                        return
                    }
                    
                    // Step 8: Verify no properties with non-selected types are included
                    let propertiesWithOtherTypes = allProperties.filter { property in
                        !selectedTypes.contains(property.propertyType)
                    }
                    
                    for otherTypeProperty in propertiesWithOtherTypes {
                        let foundInFiltered = filteredProperties.contains { $0.id == otherTypeProperty.id }
                        guard !foundInFiltered else {
                            result = false
                            expectation.fulfill()
                            return
                        }
                    }
                    
                    // Step 9: Verify all properties with selected types ARE included
                    let propertiesWithSelectedTypes = allProperties.filter { property in
                        selectedTypes.contains(property.propertyType)
                    }
                    
                    guard filteredProperties.count == propertiesWithSelectedTypes.count else {
                        result = false
                        expectation.fulfill()
                        return
                    }
                    
                    let expectedIds = Set(propertiesWithSelectedTypes.map { $0.id })
                    let filteredIds = Set(filteredProperties.map { $0.id })
                    
                    guard expectedIds == filteredIds else {
                        result = false
                        expectation.fulfill()
                        return
                    }
                    
                    // All checks passed
                    result = true
                    expectation.fulfill()
                } catch {
                    result = false
                    expectation.fulfill()
                }
            }
            
            self.wait(for: [expectation], timeout: 10.0)
            return result
        }
        
        // Test edge case: single property type filter
        property("Property type filter with single type should return only that type") <- forAll(Gen.fromElements(in: 5...15)) { (propertyCount: Int) in
            let expectation = XCTestExpectation(description: "Property type filter - single type")
            var result = false
            
            Task {
                do {
                    let testPersistence = PersistenceController(inMemory: true)
                    let localDataSource = LocalDataSource(persistenceController: testPersistence)
                    let filterService = FilterService()
                    
                    // Generate properties with various types
                    let allTypes = PropertyType.allCases
                    let properties = (0..<propertyCount).map { i -> RealDeal.Property in
                        var property = validPropertyGen().generate
                        property.propertyType = allTypes[i % allTypes.count]
                        property.status = .active
                        return property
                    }
                    
                    try await localDataSource.saveProperties(properties)
                    
                    // Filter for only houses
                    let selectedType: PropertyType = .house
                    let filters = PropertyFilters(propertyTypes: [selectedType])
                    
                    let allProperties = try await localDataSource.fetchProperties(filters: nil)
                    let filteredProperties = try filterService.applyFilters(allProperties, filters: filters)
                    
                    // Verify all returned properties are houses
                    let allAreHouses = filteredProperties.allSatisfy { $0.propertyType == selectedType }
                    
                    // Verify no non-house properties are included
                    let nonHouseProperties = allProperties.filter { $0.propertyType != selectedType }
                    let noNonHousesIncluded = nonHouseProperties.allSatisfy { nonHouseProp in
                        !filteredProperties.contains { $0.id == nonHouseProp.id }
                    }
                    
                    result = allAreHouses && noNonHousesIncluded
                    expectation.fulfill()
                } catch {
                    result = false
                    expectation.fulfill()
                }
            }
            
            self.wait(for: [expectation], timeout: 10.0)
            return result
        }
        
        // Test edge case: all property types selected
        property("Property type filter with all types should return all properties") <- forAll(Gen.fromElements(in: 5...15)) { (propertyCount: Int) in
            let expectation = XCTestExpectation(description: "Property type filter - all types")
            var result = false
            
            Task {
                do {
                    let testPersistence = PersistenceController(inMemory: true)
                    let localDataSource = LocalDataSource(persistenceController: testPersistence)
                    let filterService = FilterService()
                    
                    // Generate properties with various types
                    let allTypes = PropertyType.allCases
                    let properties = (0..<propertyCount).map { i -> RealDeal.Property in
                        var property = validPropertyGen().generate
                        property.propertyType = allTypes[i % allTypes.count]
                        property.status = .active
                        return property
                    }
                    
                    try await localDataSource.saveProperties(properties)
                    
                    // Filter with all property types selected
                    let filters = PropertyFilters(propertyTypes: Set(allTypes))
                    
                    let allProperties = try await localDataSource.fetchProperties(filters: nil)
                    let filteredProperties = try filterService.applyFilters(allProperties, filters: filters)
                    
                    // Verify all properties are returned (since all types are selected)
                    guard filteredProperties.count == allProperties.count else {
                        result = false
                        expectation.fulfill()
                        return
                    }
                    
                    let allIds = Set(allProperties.map { $0.id })
                    let filteredIds = Set(filteredProperties.map { $0.id })
                    
                    result = allIds == filteredIds
                    expectation.fulfill()
                } catch {
                    result = false
                    expectation.fulfill()
                }
            }
            
            self.wait(for: [expectation], timeout: 10.0)
            return result
        }
        
        // Test edge case: multiple specific types
        property("Property type filter with multiple types should return properties matching any selected type") <- forAll(Gen.fromElements(in: 8...20)) { (propertyCount: Int) in
            let expectation = XCTestExpectation(description: "Property type filter - multiple types")
            var result = false
            
            Task {
                do {
                    let testPersistence = PersistenceController(inMemory: true)
                    let localDataSource = LocalDataSource(persistenceController: testPersistence)
                    let filterService = FilterService()
                    
                    // Generate properties with various types
                    let allTypes = PropertyType.allCases
                    let properties = (0..<propertyCount).map { i -> RealDeal.Property in
                        var property = validPropertyGen().generate
                        property.propertyType = allTypes[i % allTypes.count]
                        property.status = .active
                        return property
                    }
                    
                    try await localDataSource.saveProperties(properties)
                    
                    // Filter for apartments and condos only
                    let selectedTypes: Set<PropertyType> = [.apartment, .condo]
                    let filters = PropertyFilters(propertyTypes: selectedTypes)
                    
                    let allProperties = try await localDataSource.fetchProperties(filters: nil)
                    let filteredProperties = try filterService.applyFilters(allProperties, filters: filters)
                    
                    // Verify all returned properties are either apartments or condos
                    let allMatchSelected = filteredProperties.allSatisfy { property in
                        selectedTypes.contains(property.propertyType)
                    }
                    
                    // Verify properties of other types are excluded
                    let otherTypeProperties = allProperties.filter { property in
                        !selectedTypes.contains(property.propertyType)
                    }
                    let noOtherTypesIncluded = otherTypeProperties.allSatisfy { otherProp in
                        !filteredProperties.contains { $0.id == otherProp.id }
                    }
                    
                    // Verify all apartments and condos ARE included
                    let expectedProperties = allProperties.filter { property in
                        selectedTypes.contains(property.propertyType)
                    }
                    
                    let countMatches = filteredProperties.count == expectedProperties.count
                    
                    result = allMatchSelected && noOtherTypesIncluded && countMatches
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
    
    // MARK: - Property-Based Test for Location Radius Filter
    
    /// Feature: real-estate-listings, Property 13: Location radius filter correctness
    /// Validates: Requirements 4.3
    func testLocationRadiusFilterCorrectness() {
        // Test that all returned results are within the specified distance from the center point
        property("Location radius filter should return only properties within the specified distance") <- forAll(Gen.fromElements(in: 5...20)) { (propertyCount: Int) in
            let expectation = XCTestExpectation(description: "Location radius filter correctness")
            var result = false
            
            Task {
                do {
                    // Use in-memory persistence controller for testing
                    let testPersistence = PersistenceController(inMemory: true)
                    let localDataSource = LocalDataSource(persistenceController: testPersistence)
                    let filterService = FilterService()
                    
                    // Step 1: Define a center point (e.g., San Francisco)
                    let centerLat = 37.7749
                    let centerLon = -122.4194
                    let centerCoordinate = Coordinate(latitude: centerLat, longitude: centerLon)
                    
                    // Step 2: Define a radius in miles (e.g., 10 miles)
                    let radiusInMiles = Double.random(in: 5.0...50.0)
                    
                    // Step 3: Generate properties at various distances from the center
                    // Some within radius, some outside radius
                    var properties: [RealDeal.Property] = []
                    var propertiesWithinRadius: [RealDeal.Property] = []
                    var propertiesOutsideRadius: [RealDeal.Property] = []
                    
                    for i in 0..<propertyCount {
                        var property = validPropertyGen().generate
                        property.status = .active
                        
                        // Generate a location at a specific distance from center
                        // Half the properties should be within radius, half outside
                        let shouldBeInside = i % 2 == 0
                        
                        if shouldBeInside {
                            // Generate a location within the radius
                            // Random distance from 0 to radiusInMiles
                            let distance = Double.random(in: 0.0...(radiusInMiles * 0.9))
                            let bearing = Double.random(in: 0.0...(2 * .pi))
                            let newLocation = self.calculateDestination(
                                from: centerCoordinate,
                                distance: distance,
                                bearing: bearing
                            )
                            property.location = newLocation
                            propertiesWithinRadius.append(property)
                        } else {
                            // Generate a location outside the radius
                            // Random distance from radiusInMiles + 1 to radiusInMiles + 50
                            let distance = Double.random(in: (radiusInMiles + 1.0)...(radiusInMiles + 50.0))
                            let bearing = Double.random(in: 0.0...(2 * .pi))
                            let newLocation = self.calculateDestination(
                                from: centerCoordinate,
                                distance: distance,
                                bearing: bearing
                            )
                            property.location = newLocation
                            propertiesOutsideRadius.append(property)
                        }
                        
                        properties.append(property)
                    }
                    
                    // Step 4: Save all properties to storage
                    try await localDataSource.saveProperties(properties)
                    
                    // Step 5: Create filter with location radius
                    let locationRadius = LocationRadius(
                        center: centerCoordinate,
                        radiusInMiles: radiusInMiles
                    )
                    let filters = PropertyFilters(locationRadius: locationRadius)
                    
                    // Step 6: Fetch all properties first (to apply filter service)
                    let allProperties = try await localDataSource.fetchProperties(filters: nil)
                    
                    // Step 7: Apply location radius filter using FilterService
                    let filteredProperties = try filterService.applyFilters(allProperties, filters: filters)
                    
                    // Step 8: Verify all returned properties are within the radius
                    let radiusInMeters = radiusInMiles * 1609.34
                    let allWithinRadius = filteredProperties.allSatisfy { property in
                        let distance = self.calculateDistance(
                            from: centerCoordinate,
                            to: property.location
                        )
                        return distance <= radiusInMeters
                    }
                    
                    guard allWithinRadius else {
                        result = false
                        expectation.fulfill()
                        return
                    }
                    
                    // Step 9: Verify no properties outside the radius are included
                    for outsideProperty in propertiesOutsideRadius {
                        let foundInFiltered = filteredProperties.contains { $0.id == outsideProperty.id }
                        guard !foundInFiltered else {
                            result = false
                            expectation.fulfill()
                            return
                        }
                    }
                    
                    // Step 10: Verify all properties within the radius ARE included
                    // (accounting for floating point precision in distance calculations)
                    for insideProperty in propertiesWithinRadius {
                        let distance = self.calculateDistance(
                            from: centerCoordinate,
                            to: insideProperty.location
                        )
                        
                        // Only check if the property is clearly within radius
                        // (with a small tolerance for floating point precision)
                        if distance <= radiusInMeters * 0.99 {
                            let foundInFiltered = filteredProperties.contains { $0.id == insideProperty.id }
                            guard foundInFiltered else {
                                result = false
                                expectation.fulfill()
                                return
                            }
                        }
                    }
                    
                    // All checks passed
                    result = true
                    expectation.fulfill()
                } catch {
                    result = false
                    expectation.fulfill()
                }
            }
            
            self.wait(for: [expectation], timeout: 10.0)
            return result
        }
        
        // Test edge case: very small radius
        property("Location radius filter with small radius should only return very nearby properties") <- forAll(Gen.fromElements(in: 5...15)) { (propertyCount: Int) in
            let expectation = XCTestExpectation(description: "Location radius filter - small radius")
            var result = false
            
            Task {
                do {
                    let testPersistence = PersistenceController(inMemory: true)
                    let localDataSource = LocalDataSource(persistenceController: testPersistence)
                    let filterService = FilterService()
                    
                    // Center point
                    let centerCoordinate = Coordinate(latitude: 37.7749, longitude: -122.4194)
                    
                    // Very small radius (1 mile)
                    let radiusInMiles = 1.0
                    
                    // Generate properties at various distances
                    var properties: [RealDeal.Property] = []
                    
                    for i in 0..<propertyCount {
                        var property = validPropertyGen().generate
                        property.status = .active
                        
                        // Generate locations at different distances
                        // Use 0.6 mile increments to avoid boundary issues at exactly 1.0 mile
                        let distance = Double(i) * 0.6 // 0, 0.6, 1.2, 1.8, 2.4, ... miles
                        let bearing = Double.random(in: 0.0...(2 * .pi))
                        let newLocation = self.calculateDestination(
                            from: centerCoordinate,
                            distance: distance,
                            bearing: bearing
                        )
                        property.location = newLocation
                        properties.append(property)
                    }
                    
                    try await localDataSource.saveProperties(properties)
                    
                    // Apply filter with small radius
                    let locationRadius = LocationRadius(
                        center: centerCoordinate,
                        radiusInMiles: radiusInMiles
                    )
                    let filters = PropertyFilters(locationRadius: locationRadius)
                    
                    let allProperties = try await localDataSource.fetchProperties(filters: nil)
                    let filteredProperties = try filterService.applyFilters(allProperties, filters: filters)
                    
                    // Verify all returned properties are within 1 mile (with small tolerance for floating point)
                    let radiusInMeters = radiusInMiles * 1609.34
                    let tolerance = 1.0 // 1 meter tolerance for floating point precision
                    let allWithinRadius = filteredProperties.allSatisfy { property in
                        let distance = self.calculateDistance(
                            from: centerCoordinate,
                            to: property.location
                        )
                        return distance <= (radiusInMeters + tolerance)
                    }
                    
                    // Verify properties clearly beyond 1 mile are excluded
                    let propertiesClearlyBeyondRadius = allProperties.filter { property in
                        let distance = self.calculateDistance(
                            from: centerCoordinate,
                            to: property.location
                        )
                        // Only check properties that are clearly beyond the radius (not at boundary)
                        return distance > (radiusInMeters + tolerance)
                    }
                    
                    let noBeyondRadiusIncluded = propertiesClearlyBeyondRadius.allSatisfy { beyondProp in
                        !filteredProperties.contains { $0.id == beyondProp.id }
                    }
                    
                    result = allWithinRadius && noBeyondRadiusIncluded
                    expectation.fulfill()
                } catch {
                    result = false
                    expectation.fulfill()
                }
            }
            
            self.wait(for: [expectation], timeout: 10.0)
            return result
        }
        
        // Test edge case: large radius
        property("Location radius filter with large radius should return most properties") <- forAll(Gen.fromElements(in: 5...15)) { (propertyCount: Int) in
            let expectation = XCTestExpectation(description: "Location radius filter - large radius")
            var result = false
            
            Task {
                do {
                    let testPersistence = PersistenceController(inMemory: true)
                    let localDataSource = LocalDataSource(persistenceController: testPersistence)
                    let filterService = FilterService()
                    
                    // Center point
                    let centerCoordinate = Coordinate(latitude: 37.7749, longitude: -122.4194)
                    
                    // Large radius (100 miles)
                    let radiusInMiles = 100.0
                    
                    // Generate properties within a reasonable area (most should be within 100 miles)
                    var properties: [RealDeal.Property] = []
                    
                    for i in 0..<propertyCount {
                        var property = validPropertyGen().generate
                        property.status = .active
                        
                        // Generate locations within 50 miles (all should be included)
                        let distance = Double.random(in: 0.0...50.0)
                        let bearing = Double.random(in: 0.0...(2 * .pi))
                        let newLocation = self.calculateDestination(
                            from: centerCoordinate,
                            distance: distance,
                            bearing: bearing
                        )
                        property.location = newLocation
                        properties.append(property)
                    }
                    
                    try await localDataSource.saveProperties(properties)
                    
                    // Apply filter with large radius
                    let locationRadius = LocationRadius(
                        center: centerCoordinate,
                        radiusInMiles: radiusInMiles
                    )
                    let filters = PropertyFilters(locationRadius: locationRadius)
                    
                    let allProperties = try await localDataSource.fetchProperties(filters: nil)
                    let filteredProperties = try filterService.applyFilters(allProperties, filters: filters)
                    
                    // Since all properties are within 50 miles and radius is 100 miles,
                    // all properties should be returned
                    guard filteredProperties.count == allProperties.count else {
                        result = false
                        expectation.fulfill()
                        return
                    }
                    
                    let allIds = Set(allProperties.map { $0.id })
                    let filteredIds = Set(filteredProperties.map { $0.id })
                    
                    result = allIds == filteredIds
                    expectation.fulfill()
                } catch {
                    result = false
                    expectation.fulfill()
                }
            }
            
            self.wait(for: [expectation], timeout: 10.0)
            return result
        }
        
        // Test edge case: property at exact boundary
        property("Location radius filter should include properties at exact boundary distance") <- forAll(Gen.fromElements(in: 1...8)) { (additionalPropertyCount: Int) in
            let expectation = XCTestExpectation(description: "Location radius filter - boundary inclusion")
            var result = false
            
            Task {
                do {
                    let testPersistence = PersistenceController(inMemory: true)
                    let localDataSource = LocalDataSource(persistenceController: testPersistence)
                    let filterService = FilterService()
                    
                    // Center point
                    let centerCoordinate = Coordinate(latitude: 37.7749, longitude: -122.4194)
                    
                    // Radius
                    let radiusInMiles = 10.0
                    let radiusInMeters = radiusInMiles * 1609.34
                    
                    // Create properties at specific distances
                    var properties: [RealDeal.Property] = []
                    
                    // Property well within radius (5 miles)
                    var propertyInside = validPropertyGen().generate
                    propertyInside.status = .active
                    propertyInside.location = self.calculateDestination(
                        from: centerCoordinate,
                        distance: 5.0,
                        bearing: 0.0
                    )
                    properties.append(propertyInside)
                    
                    // Property near boundary but clearly inside (9.9 miles)
                    var propertyNearBoundary = validPropertyGen().generate
                    propertyNearBoundary.status = .active
                    propertyNearBoundary.location = self.calculateDestination(
                        from: centerCoordinate,
                        distance: 9.9,
                        bearing: .pi / 2
                    )
                    properties.append(propertyNearBoundary)
                    
                    // Property clearly outside radius (11 miles)
                    var propertyOutside = validPropertyGen().generate
                    propertyOutside.status = .active
                    propertyOutside.location = self.calculateDestination(
                        from: centerCoordinate,
                        distance: 11.0,
                        bearing: .pi
                    )
                    properties.append(propertyOutside)
                    
                    // Additional random properties
                    for _ in 0..<additionalPropertyCount {
                        var property = validPropertyGen().generate
                        property.status = .active
                        let distance = Double.random(in: 0.0...20.0)
                        let bearing = Double.random(in: 0.0...(2 * .pi))
                        property.location = self.calculateDestination(
                            from: centerCoordinate,
                            distance: distance,
                            bearing: bearing
                        )
                        properties.append(property)
                    }
                    
                    try await localDataSource.saveProperties(properties)
                    
                    // Apply filter
                    let locationRadius = LocationRadius(
                        center: centerCoordinate,
                        radiusInMiles: radiusInMiles
                    )
                    let filters = PropertyFilters(locationRadius: locationRadius)
                    
                    let allProperties = try await localDataSource.fetchProperties(filters: nil)
                    let filteredProperties = try filterService.applyFilters(allProperties, filters: filters)
                    
                    // Verify property inside is included
                    let insideIncluded = filteredProperties.contains { $0.id == propertyInside.id }
                    guard insideIncluded else {
                        result = false
                        expectation.fulfill()
                        return
                    }
                    
                    // Verify property near boundary is included
                    let nearBoundaryIncluded = filteredProperties.contains { $0.id == propertyNearBoundary.id }
                    guard nearBoundaryIncluded else {
                        result = false
                        expectation.fulfill()
                        return
                    }
                    
                    // Verify property clearly outside is excluded
                    let outsideExcluded = !filteredProperties.contains { $0.id == propertyOutside.id }
                    guard outsideExcluded else {
                        result = false
                        expectation.fulfill()
                        return
                    }
                    
                    // Verify all filtered properties are within radius
                    let allWithinRadius = filteredProperties.allSatisfy { property in
                        let distance = self.calculateDistance(
                            from: centerCoordinate,
                            to: property.location
                        )
                        return distance <= radiusInMeters
                    }
                    
                    result = allWithinRadius
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
    
    // MARK: - Property-Based Test for Multiple Filter Conjunction
    
    /// Feature: real-estate-listings, Property 14: Multiple filter conjunction
    /// Validates: Requirements 4.4
    func testMultipleFilterConjunction() {
        // Test that when multiple filters are applied, all returned results satisfy ALL criteria simultaneously
        property("Multiple filters should be combined with AND logic - all criteria must be satisfied") <- forAll(Gen.fromElements(in: 10...30)) { (propertyCount: Int) in
            let expectation = XCTestExpectation(description: "Multiple filter conjunction")
            var result = false
            
            Task {
                do {
                    // Use in-memory persistence controller for testing
                    let testPersistence = PersistenceController(inMemory: true)
                    let localDataSource = LocalDataSource(persistenceController: testPersistence)
                    let filterService = FilterService()
                    
                    // Step 1: Generate a diverse set of properties with various attributes
                    let allTypes = PropertyType.allCases
                    let properties = (0..<propertyCount).map { i -> RealDeal.Property in
                        var property = validPropertyGen().generate
                        
                        // Create diverse properties
                        property.price = Decimal(100000 + (i * 150000))
                        property.propertyType = allTypes[i % allTypes.count]
                        property.status = .active
                        
                        // Vary specifications
                        property.specifications.bedrooms = (i % 5) + 1 // 1-5 bedrooms
                        property.specifications.bathrooms = Double((i % 4) + 1) + (i % 2 == 0 ? 0.5 : 0.0) // 1.0-4.5 bathrooms
                        
                        // Vary locations around San Francisco
                        let baseLat = 37.7749
                        let baseLon = -122.4194
                        let latOffset = (Double(i % 20) - 10.0) * 0.01 // Spread properties around
                        let lonOffset = (Double((i + 5) % 20) - 10.0) * 0.01
                        property.location = Coordinate(
                            latitude: baseLat + latOffset,
                            longitude: baseLon + lonOffset
                        )
                        
                        return property
                    }
                    
                    // Step 2: Save all properties to storage
                    try await localDataSource.saveProperties(properties)
                    
                    // Step 3: Create multiple filters that should work together with AND logic
                    let minPrice = Decimal(300000)
                    let maxPrice = Decimal(1500000)
                    let selectedTypes: Set<PropertyType> = [.house, .apartment]
                    let centerCoordinate = Coordinate(latitude: 37.7749, longitude: -122.4194)
                    let radiusInMiles = 10.0
                    let minBedrooms = 2
                    let minBathrooms = 1.5
                    
                    let filters = PropertyFilters(
                        priceMin: minPrice,
                        priceMax: maxPrice,
                        propertyTypes: selectedTypes,
                        locationRadius: LocationRadius(center: centerCoordinate, radiusInMiles: radiusInMiles),
                        minBedrooms: minBedrooms,
                        minBathrooms: minBathrooms
                    )
                    
                    // Step 4: Fetch all properties and apply filters
                    let allProperties = try await localDataSource.fetchProperties(filters: nil)
                    let filteredProperties = try filterService.applyFilters(allProperties, filters: filters)
                    
                    // Step 5: Verify ALL filtered properties satisfy ALL criteria (AND logic)
                    let radiusInMeters = radiusInMiles * 1609.34
                    
                    let allSatisfyAllCriteria = filteredProperties.allSatisfy { property in
                        // Check price range
                        let priceInRange = property.price >= minPrice && property.price <= maxPrice
                        
                        // Check property type
                        let typeMatches = selectedTypes.contains(property.propertyType)
                        
                        // Check location radius
                        let distance = self.calculateDistance(from: centerCoordinate, to: property.location)
                        let withinRadius = distance <= radiusInMeters
                        
                        // Check bedrooms
                        let bedroomsMatch = (property.specifications.bedrooms ?? 0) >= minBedrooms
                        
                        // Check bathrooms
                        let bathroomsMatch = (property.specifications.bathrooms ?? 0) >= minBathrooms
                        
                        // ALL criteria must be satisfied
                        return priceInRange && typeMatches && withinRadius && bedroomsMatch && bathroomsMatch
                    }
                    
                    guard allSatisfyAllCriteria else {
                        result = false
                        expectation.fulfill()
                        return
                    }
                    
                    // Step 6: Verify that properties NOT satisfying ALL criteria are excluded
                    // Find properties that fail at least one criterion
                    let propertiesFailingCriteria = allProperties.filter { property in
                        let priceInRange = property.price >= minPrice && property.price <= maxPrice
                        let typeMatches = selectedTypes.contains(property.propertyType)
                        let distance = self.calculateDistance(from: centerCoordinate, to: property.location)
                        let withinRadius = distance <= radiusInMeters
                        let bedroomsMatch = (property.specifications.bedrooms ?? 0) >= minBedrooms
                        let bathroomsMatch = (property.specifications.bathrooms ?? 0) >= minBathrooms
                        
                        // Return true if ANY criterion is NOT satisfied
                        return !(priceInRange && typeMatches && withinRadius && bedroomsMatch && bathroomsMatch)
                    }
                    
                    // Verify none of these properties are in the filtered results
                    for failingProperty in propertiesFailingCriteria {
                        let foundInFiltered = filteredProperties.contains { $0.id == failingProperty.id }
                        guard !foundInFiltered else {
                            result = false
                            expectation.fulfill()
                            return
                        }
                    }
                    
                    // Step 7: Verify that ALL properties satisfying ALL criteria ARE included
                    let propertiesSatisfyingAllCriteria = allProperties.filter { property in
                        let priceInRange = property.price >= minPrice && property.price <= maxPrice
                        let typeMatches = selectedTypes.contains(property.propertyType)
                        let distance = self.calculateDistance(from: centerCoordinate, to: property.location)
                        let withinRadius = distance <= radiusInMeters
                        let bedroomsMatch = (property.specifications.bedrooms ?? 0) >= minBedrooms
                        let bathroomsMatch = (property.specifications.bathrooms ?? 0) >= minBathrooms
                        
                        // Return true if ALL criteria are satisfied
                        return priceInRange && typeMatches && withinRadius && bedroomsMatch && bathroomsMatch
                    }
                    
                    // Verify count matches
                    guard filteredProperties.count == propertiesSatisfyingAllCriteria.count else {
                        result = false
                        expectation.fulfill()
                        return
                    }
                    
                    // Verify IDs match
                    let expectedIds = Set(propertiesSatisfyingAllCriteria.map { $0.id })
                    let filteredIds = Set(filteredProperties.map { $0.id })
                    
                    guard expectedIds == filteredIds else {
                        result = false
                        expectation.fulfill()
                        return
                    }
                    
                    // All checks passed - filters are correctly combined with AND logic
                    result = true
                    expectation.fulfill()
                } catch {
                    result = false
                    expectation.fulfill()
                }
            }
            
            self.wait(for: [expectation], timeout: 15.0)
            return result
        }
        
        // Test edge case: Multiple filters with no matching properties
        property("Multiple filters with no matches should return empty results") <- forAll(Gen.fromElements(in: 5...15)) { (propertyCount: Int) in
            let expectation = XCTestExpectation(description: "Multiple filters - no matches")
            var result = false
            
            Task {
                do {
                    let testPersistence = PersistenceController(inMemory: true)
                    let localDataSource = LocalDataSource(persistenceController: testPersistence)
                    let filterService = FilterService()
                    
                    // Generate properties with specific attributes
                    let properties = (0..<propertyCount).map { i -> RealDeal.Property in
                        var property = validPropertyGen().generate
                        property.price = Decimal(100000 + (i * 50000)) // All under $1M
                        property.propertyType = .house
                        property.status = .active
                        property.specifications.bedrooms = 2
                        property.specifications.bathrooms = 1.0
                        return property
                    }
                    
                    try await localDataSource.saveProperties(properties)
                    
                    // Create filters that won't match any property
                    // (e.g., looking for expensive apartments with many bedrooms)
                    let filters = PropertyFilters(
                        priceMin: Decimal(2000000), // Higher than any property
                        propertyTypes: [.apartment], // Different type
                        minBedrooms: 5 // More than any property
                    )
                    
                    let allProperties = try await localDataSource.fetchProperties(filters: nil)
                    let filteredProperties = try filterService.applyFilters(allProperties, filters: filters)
                    
                    // Should return empty results
                    result = filteredProperties.isEmpty
                    expectation.fulfill()
                } catch {
                    result = false
                    expectation.fulfill()
                }
            }
            
            self.wait(for: [expectation], timeout: 10.0)
            return result
        }
        
        // Test edge case: Subset of filters applied
        property("Subset of filters should still use AND logic correctly") <- forAll(Gen.fromElements(in: 10...20)) { (propertyCount: Int) in
            let expectation = XCTestExpectation(description: "Subset of filters")
            var result = false
            
            Task {
                do {
                    let testPersistence = PersistenceController(inMemory: true)
                    let localDataSource = LocalDataSource(persistenceController: testPersistence)
                    let filterService = FilterService()
                    
                    // Generate diverse properties
                    let properties = (0..<propertyCount).map { i -> RealDeal.Property in
                        var property = validPropertyGen().generate
                        property.price = Decimal(200000 + (i * 100000))
                        property.propertyType = i % 2 == 0 ? .house : .apartment
                        property.status = .active
                        property.specifications.bedrooms = (i % 4) + 1
                        return property
                    }
                    
                    try await localDataSource.saveProperties(properties)
                    
                    // Apply only price and type filters (not all possible filters)
                    let minPrice = Decimal(500000)
                    let maxPrice = Decimal(1200000)
                    let selectedTypes: Set<PropertyType> = [.house]
                    
                    let filters = PropertyFilters(
                        priceMin: minPrice,
                        priceMax: maxPrice,
                        propertyTypes: selectedTypes
                    )
                    
                    let allProperties = try await localDataSource.fetchProperties(filters: nil)
                    let filteredProperties = try filterService.applyFilters(allProperties, filters: filters)
                    
                    // Verify all results satisfy both criteria
                    let allSatisfyBothCriteria = filteredProperties.allSatisfy { property in
                        let priceInRange = property.price >= minPrice && property.price <= maxPrice
                        let typeMatches = selectedTypes.contains(property.propertyType)
                        return priceInRange && typeMatches
                    }
                    
                    // Verify properties failing either criterion are excluded
                    let propertiesFailingEitherCriterion = allProperties.filter { property in
                        let priceInRange = property.price >= minPrice && property.price <= maxPrice
                        let typeMatches = selectedTypes.contains(property.propertyType)
                        return !(priceInRange && typeMatches)
                    }
                    
                    let noneFailingIncluded = propertiesFailingEitherCriterion.allSatisfy { failingProp in
                        !filteredProperties.contains { $0.id == failingProp.id }
                    }
                    
                    result = allSatisfyBothCriteria && noneFailingIncluded
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
    
    // MARK: - Property-Based Test for Filter Clearing
    
    /// Feature: real-estate-listings, Property 15: Filter clearing restores all active listings
    /// Validates: Requirements 4.5
    func testFilterClearingRestoresAllActiveListings() {
        // Test that clearing filters results in all active listings being displayed
        property("Clearing filters should restore all active listings") <- forAll(Gen.fromElements(in: 10...30)) { (propertyCount: Int) in
            let expectation = XCTestExpectation(description: "Filter clearing restores all active listings")
            var result = false
            
            Task {
                do {
                    // Use in-memory persistence controller for testing
                    let testPersistence = PersistenceController(inMemory: true)
                    let localDataSource = LocalDataSource(persistenceController: testPersistence)
                    let filterService = FilterService()
                    
                    // Step 1: Generate a diverse set of properties with various statuses
                    let allTypes = PropertyType.allCases
                    var allProperties: [RealDeal.Property] = []
                    var activeProperties: [RealDeal.Property] = []
                    var soldProperties: [RealDeal.Property] = []
                    var pendingProperties: [RealDeal.Property] = []
                    
                    for i in 0..<propertyCount {
                        var property = validPropertyGen().generate
                        
                        // Create diverse properties with various attributes
                        property.price = Decimal(100000 + (i * 150000))
                        property.propertyType = allTypes[i % allTypes.count]
                        
                        // Vary specifications
                        property.specifications.bedrooms = (i % 5) + 1 // 1-5 bedrooms
                        property.specifications.bathrooms = Double((i % 4) + 1) + (i % 2 == 0 ? 0.5 : 0.0) // 1.0-4.5 bathrooms
                        
                        // Vary locations around San Francisco
                        let baseLat = 37.7749
                        let baseLon = -122.4194
                        let latOffset = (Double(i % 20) - 10.0) * 0.01
                        let lonOffset = (Double((i + 5) % 20) - 10.0) * 0.01
                        property.location = Coordinate(
                            latitude: baseLat + latOffset,
                            longitude: baseLon + lonOffset
                        )
                        
                        // Assign different statuses to properties
                        if i % 4 == 0 {
                            property.status = .sold
                            soldProperties.append(property)
                        } else if i % 4 == 1 {
                            property.status = .pending
                            pendingProperties.append(property)
                        } else {
                            property.status = .active
                            activeProperties.append(property)
                        }
                        
                        allProperties.append(property)
                    }
                    
                    // Step 2: Save all properties to storage
                    try await localDataSource.saveProperties(allProperties)
                    
                    // Step 3: Apply restrictive filters that will exclude many properties
                    let minPrice = Decimal(500000)
                    let maxPrice = Decimal(1000000)
                    let selectedTypes: Set<PropertyType> = [.house]
                    let centerCoordinate = Coordinate(latitude: 37.7749, longitude: -122.4194)
                    let radiusInMiles = 5.0
                    let minBedrooms = 3
                    
                    let restrictiveFilters = PropertyFilters(
                        priceMin: minPrice,
                        priceMax: maxPrice,
                        propertyTypes: selectedTypes,
                        locationRadius: LocationRadius(center: centerCoordinate, radiusInMiles: radiusInMiles),
                        minBedrooms: minBedrooms
                    )
                    
                    // Step 4: Fetch properties with restrictive filters applied
                    let allPropertiesFromStorage = try await localDataSource.fetchProperties(filters: nil)
                    let filteredProperties = try filterService.applyFilters(allPropertiesFromStorage, filters: restrictiveFilters)
                    
                    // Step 5: Verify that filtered results are a subset of all active properties
                    // (This confirms filters are actually restricting results)
                    guard filteredProperties.count < activeProperties.count else {
                        // If filtered count equals active count, filters didn't restrict anything
                        // This is unlikely with our restrictive filters, but we should handle it
                        // For this test to be meaningful, we need filters to actually restrict
                        result = false
                        expectation.fulfill()
                        return
                    }
                    
                    // Step 6: Clear filters by passing nil filters
                    let clearedFilters: PropertyFilters? = nil
                    let propertiesAfterClearing = try filterService.applyFilters(allPropertiesFromStorage, filters: clearedFilters)
                    
                    // Step 7: Verify that clearing filters returns ALL active listings
                    // (excluding sold and deleted properties, but including pending)
                    let expectedActiveAndPendingProperties = allPropertiesFromStorage.filter { property in
                        property.status == .active || property.status == .pending
                    }
                    
                    // Check count matches
                    guard propertiesAfterClearing.count == expectedActiveAndPendingProperties.count else {
                        result = false
                        expectation.fulfill()
                        return
                    }
                    
                    // Step 8: Verify all active properties are present after clearing
                    let clearedIds = Set(propertiesAfterClearing.map { $0.id })
                    let expectedIds = Set(expectedActiveAndPendingProperties.map { $0.id })
                    
                    guard clearedIds == expectedIds else {
                        result = false
                        expectation.fulfill()
                        return
                    }
                    
                    // Step 9: Verify that sold properties are still excluded after clearing
                    // (Clearing filters should restore active listings, not sold ones)
                    let hasSoldProperty = propertiesAfterClearing.contains { property in
                        property.status == .sold
                    }
                    
                    guard !hasSoldProperty else {
                        result = false
                        expectation.fulfill()
                        return
                    }
                    
                    // Step 10: Verify each active property is in the cleared results
                    for activeProperty in activeProperties {
                        let foundInCleared = propertiesAfterClearing.contains { $0.id == activeProperty.id }
                        guard foundInCleared else {
                            result = false
                            expectation.fulfill()
                            return
                        }
                    }
                    
                    // Step 11: Verify each pending property is in the cleared results
                    for pendingProperty in pendingProperties {
                        let foundInCleared = propertiesAfterClearing.contains { $0.id == pendingProperty.id }
                        guard foundInCleared else {
                            result = false
                            expectation.fulfill()
                            return
                        }
                    }
                    
                    // Step 12: Verify no sold properties are in the cleared results
                    for soldProperty in soldProperties {
                        let foundInCleared = propertiesAfterClearing.contains { $0.id == soldProperty.id }
                        guard !foundInCleared else {
                            result = false
                            expectation.fulfill()
                            return
                        }
                    }
                    
                    // All checks passed - clearing filters correctly restores all active listings
                    result = true
                    expectation.fulfill()
                } catch {
                    result = false
                    expectation.fulfill()
                }
            }
            
            self.wait(for: [expectation], timeout: 15.0)
            return result
        }
        
        // Test edge case: Clearing already empty filters
        property("Clearing empty filters should still return all active listings") <- forAll(Gen.fromElements(in: 5...15)) { (propertyCount: Int) in
            let expectation = XCTestExpectation(description: "Clearing empty filters")
            var result = false
            
            Task {
                do {
                    let testPersistence = PersistenceController(inMemory: true)
                    let localDataSource = LocalDataSource(persistenceController: testPersistence)
                    let filterService = FilterService()
                    
                    // Generate properties with various statuses
                    var properties: [RealDeal.Property] = []
                    var activeProperties: [RealDeal.Property] = []
                    
                    for i in 0..<propertyCount {
                        var property = validPropertyGen().generate
                        property.status = i % 3 == 0 ? .sold : .active
                        
                        if property.status == .active {
                            activeProperties.append(property)
                        }
                        
                        properties.append(property)
                    }
                    
                    try await localDataSource.saveProperties(properties)
                    
                    // Apply no filters (nil)
                    let allPropertiesFromStorage = try await localDataSource.fetchProperties(filters: nil)
                    let propertiesWithNoFilters = try filterService.applyFilters(allPropertiesFromStorage, filters: nil)
                    
                    // Clear filters (also nil)
                    let propertiesAfterClearing = try filterService.applyFilters(allPropertiesFromStorage, filters: nil)
                    
                    // Both should return the same results (all active properties)
                    guard propertiesWithNoFilters.count == propertiesAfterClearing.count else {
                        result = false
                        expectation.fulfill()
                        return
                    }
                    
                    let noFiltersIds = Set(propertiesWithNoFilters.map { $0.id })
                    let clearedIds = Set(propertiesAfterClearing.map { $0.id })
                    
                    result = noFiltersIds == clearedIds
                    expectation.fulfill()
                } catch {
                    result = false
                    expectation.fulfill()
                }
            }
            
            self.wait(for: [expectation], timeout: 10.0)
            return result
        }
        
        // Test edge case: Multiple filter clear cycles
        property("Multiple cycles of applying and clearing filters should be consistent") <- forAll(Gen.fromElements(in: 8...20)) { (propertyCount: Int) in
            let expectation = XCTestExpectation(description: "Multiple filter clear cycles")
            var result = false
            
            Task {
                do {
                    let testPersistence = PersistenceController(inMemory: true)
                    let localDataSource = LocalDataSource(persistenceController: testPersistence)
                    let filterService = FilterService()
                    
                    // Generate diverse properties
                    let properties = (0..<propertyCount).map { i -> RealDeal.Property in
                        var property = validPropertyGen().generate
                        property.price = Decimal(200000 + (i * 100000))
                        property.propertyType = i % 2 == 0 ? .house : .apartment
                        property.status = i % 5 == 0 ? .sold : .active
                        property.specifications.bedrooms = (i % 4) + 1
                        return property
                    }
                    
                    try await localDataSource.saveProperties(properties)
                    
                    let allPropertiesFromStorage = try await localDataSource.fetchProperties(filters: nil)
                    
                    // Cycle 1: Apply filters, then clear
                    let filters1 = PropertyFilters(
                        priceMin: Decimal(500000),
                        propertyTypes: [.house]
                    )
                    _ = try filterService.applyFilters(allPropertiesFromStorage, filters: filters1)
                    let cleared1 = try filterService.applyFilters(allPropertiesFromStorage, filters: nil)
                    
                    // Cycle 2: Apply different filters, then clear
                    let filters2 = PropertyFilters(
                        priceMax: Decimal(800000),
                        propertyTypes: [.apartment],
                        minBedrooms: 2
                    )
                    _ = try filterService.applyFilters(allPropertiesFromStorage, filters: filters2)
                    let cleared2 = try filterService.applyFilters(allPropertiesFromStorage, filters: nil)
                    
                    // Cycle 3: Apply yet different filters, then clear
                    let filters3 = PropertyFilters(
                        priceMin: Decimal(300000),
                        priceMax: Decimal(1200000)
                    )
                    _ = try filterService.applyFilters(allPropertiesFromStorage, filters: filters3)
                    let cleared3 = try filterService.applyFilters(allPropertiesFromStorage, filters: nil)
                    
                    // All cleared results should be identical (all active properties)
                    let cleared1Ids = Set(cleared1.map { $0.id })
                    let cleared2Ids = Set(cleared2.map { $0.id })
                    let cleared3Ids = Set(cleared3.map { $0.id })
                    
                    result = cleared1Ids == cleared2Ids && cleared2Ids == cleared3Ids
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
    
    // MARK: - Property-Based Test for Image Gallery Display
    
    /// Feature: real-estate-listings, Property 17: All property images displayed
    /// Validates: Requirements 5.2
    func testAllPropertyImagesDisplayed() {
        // Test that the gallery view displays all images associated with a property
        property("Gallery view should display all property images") <- forAll(Gen.fromElements(in: 1...10)) { (imageCount: Int) in
            let expectation = XCTestExpectation(description: "All property images displayed")
            var result = false
            
            Task { @MainActor in
                // Create a property with a specific number of images
                var testProperty = validPropertyGen().generate
                
                // Generate images with sequential order
                let images = (0..<imageCount).map { index in
                    PropertyImage(
                        id: "image-\(index)-\(UUID().uuidString)",
                        url: URL(string: "https://example.com/property/image\(index).jpg")!,
                        order: index
                    )
                }
                testProperty.images = images
                
                // Use in-memory persistence controller for testing
                let testPersistence = PersistenceController(inMemory: true)
                let localDataSource = LocalDataSource(persistenceController: testPersistence)
                let mockRemote = MockRemoteDataSource(simulateNetworkDelay: false)
                
                // Create repositories
                let propertyRepository = PropertyRepository(
                    localDataSource: localDataSource,
                    remoteDataSource: mockRemote
                )
                let userProfileRepository = UserProfileRepository(
                    localDataSource: localDataSource,
                    remoteDataSource: mockRemote
                )
                
                // Create the view model
                let viewModel = PropertyDetailViewModel(
                    property: testProperty,
                    propertyRepository: propertyRepository,
                    userProfileRepository: userProfileRepository
                )
                
                // Step 1: Verify the view model has images
                guard viewModel.hasImages else {
                    result = false
                    expectation.fulfill()
                    return
                }
                
                // Step 2: Get the sorted images (this is what the gallery view uses)
                let sortedImages = viewModel.sortedImages
                
                // Step 3: Verify the count matches the expected number of images
                guard sortedImages.count == imageCount else {
                    result = false
                    expectation.fulfill()
                    return
                }
                
                // Step 4: Verify all images are present (by ID)
                let expectedImageIds = Set(images.map { $0.id })
                let displayedImageIds = Set(sortedImages.map { $0.id })
                guard expectedImageIds == displayedImageIds else {
                    result = false
                    expectation.fulfill()
                    return
                }
                
                // Step 5: Verify images are sorted by order
                let isSortedByOrder = sortedImages.enumerated().allSatisfy { index, image in
                    image.order == index
                }
                guard isSortedByOrder else {
                    result = false
                    expectation.fulfill()
                    return
                }
                
                // Step 6: Verify each image has the correct URL
                for (index, image) in sortedImages.enumerated() {
                    let expectedURL = URL(string: "https://example.com/property/image\(index).jpg")!
                    guard image.url == expectedURL else {
                        result = false
                        expectation.fulfill()
                        return
                    }
                }
                
                // Step 7: Verify no duplicate images are displayed
                let uniqueImageIds = Set(sortedImages.map { $0.id })
                guard uniqueImageIds.count == sortedImages.count else {
                    result = false
                    expectation.fulfill()
                    return
                }
                
                // All checks passed - all images are correctly displayed
                result = true
                expectation.fulfill()
            }
            
            self.wait(for: [expectation], timeout: 5.0)
            return result
        }
        
        // Test that properties with no images are handled correctly
        property("Properties with no images should show no gallery") <- forAll(Gen.fromElements(in: 0...100)) { (seed: Int) in
            let expectation = XCTestExpectation(description: "No images handled correctly")
            var result = false
            
            Task { @MainActor in
                // Create a property with no images
                var testProperty = validPropertyGen().resize(seed).generate
                testProperty.images = []
                
                // Use in-memory persistence controller for testing
                let testPersistence = PersistenceController(inMemory: true)
                let localDataSource = LocalDataSource(persistenceController: testPersistence)
                let mockRemote = MockRemoteDataSource(simulateNetworkDelay: false)
                
                // Create repositories
                let propertyRepository = PropertyRepository(
                    localDataSource: localDataSource,
                    remoteDataSource: mockRemote
                )
                let userProfileRepository = UserProfileRepository(
                    localDataSource: localDataSource,
                    remoteDataSource: mockRemote
                )
                
                // Create the view model
                let viewModel = PropertyDetailViewModel(
                    property: testProperty,
                    propertyRepository: propertyRepository,
                    userProfileRepository: userProfileRepository
                )
                
                // Verify the view model correctly reports no images
                guard !viewModel.hasImages else {
                    result = false
                    expectation.fulfill()
                    return
                }
                
                // Verify sortedImages returns an empty array
                guard viewModel.sortedImages.isEmpty else {
                    result = false
                    expectation.fulfill()
                    return
                }
                
                // All checks passed
                result = true
                expectation.fulfill()
            }
            
            self.wait(for: [expectation], timeout: 5.0)
            return result
        }
        
        // Test that images with out-of-order indices are correctly sorted
        property("Images with out-of-order indices should be sorted correctly") <- forAll(Gen.fromElements(in: 3...8)) { (imageCount: Int) in
            let expectation = XCTestExpectation(description: "Out-of-order images sorted correctly")
            var result = false
            
            Task { @MainActor in
                // Create a property with images in random order
                var testProperty = validPropertyGen().generate
                
                // Generate images with shuffled order values
                var orderValues = Array(0..<imageCount)
                orderValues.shuffle()
                
                let images = orderValues.enumerated().map { index, order in
                    PropertyImage(
                        id: "image-\(index)-\(UUID().uuidString)",
                        url: URL(string: "https://example.com/property/image\(order).jpg")!,
                        order: order
                    )
                }
                testProperty.images = images
                
                // Use in-memory persistence controller for testing
                let testPersistence = PersistenceController(inMemory: true)
                let localDataSource = LocalDataSource(persistenceController: testPersistence)
                let mockRemote = MockRemoteDataSource(simulateNetworkDelay: false)
                
                // Create repositories
                let propertyRepository = PropertyRepository(
                    localDataSource: localDataSource,
                    remoteDataSource: mockRemote
                )
                let userProfileRepository = UserProfileRepository(
                    localDataSource: localDataSource,
                    remoteDataSource: mockRemote
                )
                
                // Create the view model
                let viewModel = PropertyDetailViewModel(
                    property: testProperty,
                    propertyRepository: propertyRepository,
                    userProfileRepository: userProfileRepository
                )
                
                // Get the sorted images
                let sortedImages = viewModel.sortedImages
                
                // Verify all images are present
                guard sortedImages.count == imageCount else {
                    result = false
                    expectation.fulfill()
                    return
                }
                
                // Verify images are sorted by order (0, 1, 2, ...)
                let isSortedCorrectly = sortedImages.enumerated().allSatisfy { index, image in
                    image.order == index
                }
                guard isSortedCorrectly else {
                    result = false
                    expectation.fulfill()
                    return
                }
                
                // Verify the URLs correspond to the correct order
                for (index, image) in sortedImages.enumerated() {
                    let expectedURL = URL(string: "https://example.com/property/image\(index).jpg")!
                    guard image.url == expectedURL else {
                        result = false
                        expectation.fulfill()
                        return
                    }
                }
                
                // All checks passed
                result = true
                expectation.fulfill()
            }
            
            self.wait(for: [expectation], timeout: 5.0)
            return result
        }
    }
    
    // MARK: - Helper Methods for Location Calculations
    
    /// Calculate the distance in meters between two coordinates using the Haversine formula
    func calculateDistance(from: Coordinate, to: Coordinate) -> Double {
        let earthRadiusInMeters = 6371000.0
        
        let lat1Rad = from.latitude * .pi / 180.0
        let lat2Rad = to.latitude * .pi / 180.0
        let deltaLatRad = (to.latitude - from.latitude) * .pi / 180.0
        let deltaLonRad = (to.longitude - from.longitude) * .pi / 180.0
        
        let a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
                cos(lat1Rad) * cos(lat2Rad) *
                sin(deltaLonRad / 2) * sin(deltaLonRad / 2)
        
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        
        return earthRadiusInMeters * c
    }
    
    /// Calculate a destination coordinate given a starting point, distance (in miles), and bearing (in radians)
    func calculateDestination(from: Coordinate, distance: Double, bearing: Double) -> Coordinate {
        let earthRadiusInMeters = 6371000.0
        let distanceInMeters = distance * 1609.34 // Convert miles to meters
        
        let lat1Rad = from.latitude * .pi / 180.0
        let lon1Rad = from.longitude * .pi / 180.0
        
        let angularDistance = distanceInMeters / earthRadiusInMeters
        
        let lat2Rad = asin(
            sin(lat1Rad) * cos(angularDistance) +
            cos(lat1Rad) * sin(angularDistance) * cos(bearing)
        )
        
        let lon2Rad = lon1Rad + atan2(
            sin(bearing) * sin(angularDistance) * cos(lat1Rad),
            cos(angularDistance) - sin(lat1Rad) * sin(lat2Rad)
        )
        
        let lat2 = lat2Rad * 180.0 / .pi
        let lon2 = lon2Rad * 180.0 / .pi
        
        return Coordinate(latitude: lat2, longitude: lon2)
    }
}

