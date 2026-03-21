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
            role: .homeowner
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

    // MARK: - Apple Sign In Tests

    func testAppleSignInCreatesUserAndReturnsToken() async throws {
        // Given: a fresh mock service and a simulated Apple identity token
        let identityToken = "apple-identity-token-abc"
        let nonce = "random-nonce"

        // When: signing in with Apple
        let token = try await mockAuth.signInWithApple(
            identityToken: identityToken,
            nonce: nonce,
            fullName: "Apple Tester",
            email: "appletester@privaterelay.appleid.com"
        )

        // Then: a valid token is returned and the user is set
        XCTAssertFalse(token.accessToken.isEmpty, "Apple Sign In should return a non-empty access token")
        XCTAssertNotNil(mockAuth.currentUser, "currentUser should be set after Apple Sign In")
        XCTAssertEqual(mockAuth.currentUser?.name, "Apple Tester")
    }

    func testAppleSignInTwiceWithSameTokenIsIdempotent() async throws {
        // Given: an identity token already used once
        let identityToken = "apple-idempotent-token"
        let nonce = "nonce-1"

        let firstToken = try await mockAuth.signInWithApple(
            identityToken: identityToken,
            nonce: nonce,
            fullName: "First Apple",
            email: "first@apple.com"
        )
        let firstUserId = mockAuth.currentUser?.id

        // When: signing in again with the same identity token
        _ = try await mockAuth.signInWithApple(
            identityToken: identityToken,
            nonce: nonce,
            fullName: "Should Be Ignored",
            email: "shouldbeignored@apple.com"
        )
        let secondUserId = mockAuth.currentUser?.id

        // Then: the same user account is returned — no duplicate is created
        XCTAssertFalse(firstToken.accessToken.isEmpty)
        XCTAssertEqual(firstUserId, secondUserId, "Signing in twice with the same Apple token should resolve to the same user")
        XCTAssertEqual(mockAuth.getAllUsers().filter { $0.id == firstUserId }.count, 1,
            "Only one user should exist for a given Apple token")
    }

    // MARK: - Google Sign In Tests

    func testGoogleSignInCreatesUserAndReturnsToken() async throws {
        // Given: a simulated Google ID token
        let idToken = "google-id-token-xyz"

        // When: signing in with Google
        let token = try await mockAuth.signInWithGoogle(idToken: idToken)

        // Then: a valid token is returned and the user is set
        XCTAssertFalse(token.accessToken.isEmpty, "Google Sign In should return a non-empty access token")
        XCTAssertNotNil(mockAuth.currentUser, "currentUser should be set after Google Sign In")
    }

    func testGoogleSignInUserHasBuyerRoleByDefault() async throws {
        // Given/When
        _ = try await mockAuth.signInWithGoogle(idToken: "google-default-role-token")

        // Then: newly created social users default to .buyer
        XCTAssertEqual(mockAuth.currentUser?.role, .buyer,
            "Social sign-in users should default to the buyer role")
    }

    // MARK: - Role-based Registration Tests

    func testRegistrationWithAgentRoleStoresLicenseNumber() async throws {
        // Given: a profile with agent role and a license number
        let licenseNumber = "RECO-987654"
        let profile = UserProfile(
            name: "Agent Dana",
            email: "dana@brokerage.ca",
            role: .agent,
            licenseNumber: licenseNumber
        )

        // When: signing up
        _ = try await mockAuth.signUp(
            email: "dana@brokerage.ca",
            password: "Password123",
            profile: profile
        )

        // Then: the stored profile retains the license number
        let storedUser = mockAuth.getAllUsers().first { $0.email == "dana@brokerage.ca" }
        XCTAssertNotNil(storedUser, "Agent should be stored after registration")
        XCTAssertEqual(storedUser?.role, .agent)
        XCTAssertEqual(storedUser?.licenseNumber, licenseNumber,
            "The agent's license number should be stored on the profile")
    }

    func testRegistrationWithHomeownerRoleSucceedsWithoutLicenseNumber() async throws {
        // Given: a homeowner profile without a license number
        let profile = UserProfile(
            name: "Eve Owner",
            email: "eve@homeowner.ca",
            role: .homeowner,
            licenseNumber: nil
        )

        // When: signing up
        let token = try await mockAuth.signUp(
            email: "eve@homeowner.ca",
            password: "Password123",
            profile: profile
        )

        // Then: registration succeeds
        XCTAssertFalse(token.accessToken.isEmpty, "Homeowner registration should succeed without a license number")
        XCTAssertEqual(mockAuth.currentUser?.role, .homeowner)
        XCTAssertNil(mockAuth.currentUser?.licenseNumber, "Homeowners should not have a license number stored")
    }
}
