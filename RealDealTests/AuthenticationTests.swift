import XCTest
@testable import RealDeal

@available(iOS 15.0, macOS 12.0, *)
final class AuthenticationTests: XCTestCase {
    var mockAuth: MockAuthenticationService!
    var mockRemote: MockRemoteDataSource!
    var persistence: PersistenceController!
    var userRepo: UserProfileRepository!
    var authService: AuthenticationService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        mockAuth = MockAuthenticationService(simulateNetworkDelay: false)
        mockRemote = MockRemoteDataSource(simulateNetworkDelay: false)
        persistence = PersistenceController(inMemory: true)
        userRepo = UserProfileRepository(
            localDataSource: LocalDataSource(persistenceController: persistence),
            remoteDataSource: mockRemote
        )
        authService = AuthenticationService(
            backendAuth: mockAuth,
            userProfileRepository: userRepo
        )
    }
    
    override func tearDown() async throws {
        mockAuth = nil
        mockRemote = nil
        persistence = nil
        userRepo = nil
        authService = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Sign In Tests
    
    func testSignInWithValidCredentials() async throws {
        // Given: A registered user
        let profile = UserProfile(
            name: "Test User",
            email: "test@example.com",
            role: .buyer
        )
        _ = try await mockAuth.signUp(email: "test@example.com", password: "password123", profile: profile)
        
        // When: Signing in with valid credentials
        let token = try await authService.signIn(email: "test@example.com", password: "password123")
        
        // Then: Authentication succeeds
        XCTAssertFalse(token.accessToken.isEmpty)
        XCTAssertNotNil(authService.currentUser)
        XCTAssertEqual(authService.currentUser?.email, "test@example.com")
    }
    
    func testSignInWithInvalidEmail() async throws {
        // When: Signing in with invalid email format
        do {
            _ = try await authService.signIn(email: "invalid-email", password: "password123")
            XCTFail("Should have thrown validation error")
        } catch let error as AppError {
            // Then: Validation error is thrown
            if case .validation(let validationError) = error {
                XCTAssertEqual(validationError, .invalidEmailFormat)
            } else {
                XCTFail("Expected validation error")
            }
        }
    }
    
    func testSignInWithEmptyPassword() async throws {
        // When: Signing in with empty password
        do {
            _ = try await authService.signIn(email: "test@example.com", password: "")
            XCTFail("Should have thrown validation error")
        } catch let error as AppError {
            // Then: Validation error is thrown
            if case .validation = error {
                XCTAssertTrue(true)
            } else {
                XCTFail("Expected validation error")
            }
        }
    }
    
    // MARK: - Sign Up Tests
    
    func testSignUpWithValidData() async throws {
        // Given: Valid registration data
        let profile = UserProfile(
            name: "New User",
            email: "newuser@example.com",
            role: .seller
        )
        
        // When: Signing up
        let token = try await authService.signUp(
            email: "newuser@example.com",
            password: "SecurePass123",
            profile: profile
        )
        
        // Then: Registration succeeds
        XCTAssertFalse(token.accessToken.isEmpty)
        XCTAssertNotNil(authService.currentUser)
        XCTAssertEqual(authService.currentUser?.name, "New User")
    }
    
    func testSignUpWithInvalidEmail() async throws {
        // Given: Invalid email
        let profile = UserProfile(
            name: "Test User",
            email: "invalid",
            role: .buyer
        )
        
        // When: Signing up with invalid email
        do {
            _ = try await authService.signUp(
                email: "invalid",
                password: "password123",
                profile: profile
            )
            XCTFail("Should have thrown validation error")
        } catch let error as AppError {
            // Then: Validation error is thrown
            if case .validation(let validationError) = error {
                XCTAssertEqual(validationError, .invalidEmailFormat)
            } else {
                XCTFail("Expected validation error")
            }
        }
    }
    
    func testSignUpWithWeakPassword() async throws {
        // Given: Weak password (less than 8 characters)
        let profile = UserProfile(
            name: "Test User",
            email: "test@example.com",
            role: .buyer
        )
        
        // When: Signing up with weak password
        do {
            _ = try await authService.signUp(
                email: "test@example.com",
                password: "weak",
                profile: profile
            )
            XCTFail("Should have thrown validation error")
        } catch let error as AppError {
            // Then: Validation error is thrown
            if case .validation(let validationError) = error {
                XCTAssertEqual(validationError, .weakPassword)
            } else {
                XCTFail("Expected validation error")
            }
        }
    }
    
    func testSignUpWithEmptyName() async throws {
        // Given: Empty name
        let profile = UserProfile(
            name: "   ",
            email: "test@example.com",
            role: .buyer
        )
        
        // When: Signing up with empty name
        do {
            _ = try await authService.signUp(
                email: "test@example.com",
                password: "password123",
                profile: profile
            )
            XCTFail("Should have thrown validation error")
        } catch let error as AppError {
            // Then: Validation error is thrown
            if case .validation = error {
                XCTAssertTrue(true)
            } else {
                XCTFail("Expected validation error")
            }
        }
    }
    
    // MARK: - Sign Out Tests
    
    func testSignOut() async throws {
        // Given: A signed-in user
        let profile = UserProfile(
            name: "Test User",
            email: "test@example.com",
            role: .buyer
        )
        _ = try await mockAuth.signUp(email: "test@example.com", password: "password123", profile: profile)
        _ = try await authService.signIn(email: "test@example.com", password: "password123")
        
        XCTAssertNotNil(authService.currentUser)
        
        // When: Signing out
        try await authService.signOut()
        
        // Then: User is signed out
        XCTAssertNil(authService.currentUser)
    }
    
    // MARK: - Validator Tests
    
    func testEmailValidation() {
        XCTAssertTrue(Validator.isValidEmail("test@example.com"))
        XCTAssertTrue(Validator.isValidEmail("user.name+tag@example.co.uk"))
        XCTAssertFalse(Validator.isValidEmail("invalid"))
        XCTAssertFalse(Validator.isValidEmail("@example.com"))
        XCTAssertFalse(Validator.isValidEmail("test@"))
        XCTAssertFalse(Validator.isValidEmail("test@.com"))
    }
    
    func testPasswordValidation() {
        XCTAssertTrue(Validator.isValidPassword("password123"))
        XCTAssertTrue(Validator.isValidPassword("SecurePass1"))
        XCTAssertFalse(Validator.isValidPassword("short1"))
        XCTAssertFalse(Validator.isValidPassword("nodigits"))
        XCTAssertFalse(Validator.isValidPassword("12345678"))
        XCTAssertFalse(Validator.isValidPassword(""))
    }
}
