import XCTest
@testable import RealDeal

/// Tests for the post-signup profile setup wizard flow.
@available(iOS 15.0, macOS 12.0, *)
@MainActor
final class ProfileSetupFlowTests: XCTestCase {
    var authViewModel: AuthViewModel!

    override func setUp() async throws {
        try await super.setUp()

        let mockAuth = MockAuthenticationService(simulateNetworkDelay: false)
        let persistence = PersistenceController(inMemory: true)
        let userRepo = UserProfileRepository(
            localDataSource: LocalDataSource(persistenceController: persistence),
            remoteDataSource: MockRemoteDataSource(simulateNetworkDelay: false)
        )
        let authService = AuthenticationService(
            backendAuth: mockAuth,
            userProfileRepository: userRepo
        )
        authViewModel = AuthViewModel(authService: authService)
    }

    override func tearDown() async throws {
        authViewModel = nil
        try await super.tearDown()
    }

    private func fillValidRegistrationForm() {
        authViewModel.registerName = "New User"
        authViewModel.registerEmail = "new-user@example.com"
        authViewModel.registerPassword = "password123"
        authViewModel.registerConfirmPassword = "password123"
    }

    func testSignUpSuccessTriggersProfileSetup() async {
        fillValidRegistrationForm()

        await authViewModel.signUp()

        XCTAssertTrue(authViewModel.isAuthenticated)
        XCTAssertTrue(
            authViewModel.needsProfileSetup,
            "A brand-new account should be routed into the profile setup wizard"
        )
    }

    func testSignUpFailureDoesNotTriggerProfileSetup() async {
        // Invalid form (empty fields) — signUp bails before calling the service
        await authViewModel.signUp()

        XCTAssertFalse(authViewModel.isAuthenticated)
        XCTAssertFalse(authViewModel.needsProfileSetup)
    }

    func testCompleteProfileSetupClearsFlagAndSyncsUser() async {
        fillValidRegistrationForm()
        await authViewModel.signUp()
        XCTAssertTrue(authViewModel.needsProfileSetup)

        var updated = authViewModel.currentUser!
        updated.name = "Updated Name"
        updated.phoneNumber = "+15551234567"

        authViewModel.completeProfileSetup(updatedProfile: updated)

        XCTAssertFalse(authViewModel.needsProfileSetup)
        XCTAssertEqual(authViewModel.currentUser?.name, "Updated Name")
        XCTAssertEqual(authViewModel.currentUser?.phoneNumber, "+15551234567")
    }

    func testSkipClearsFlagWithoutTouchingUser() async {
        fillValidRegistrationForm()
        await authViewModel.signUp()
        let userBefore = authViewModel.currentUser

        authViewModel.completeProfileSetup()

        XCTAssertFalse(authViewModel.needsProfileSetup)
        XCTAssertEqual(authViewModel.currentUser, userBefore)
    }

    func testSignInDoesNotTriggerProfileSetup() async {
        // Existing-account sign-in must not show the wizard
        fillValidRegistrationForm()
        await authViewModel.signUp()
        authViewModel.completeProfileSetup()
        await authViewModel.signOut()
        XCTAssertFalse(authViewModel.isAuthenticated)

        authViewModel.loginEmail = "new-user@example.com"
        authViewModel.loginPassword = "password123"
        await authViewModel.signIn()

        XCTAssertTrue(authViewModel.isAuthenticated)
        XCTAssertFalse(
            authViewModel.needsProfileSetup,
            "Signing in to an existing account should not show the setup wizard"
        )
    }
}
