import XCTest
@testable import RealDeal

@available(iOS 15.0, macOS 12.0, *)
final class UserRoleTests: XCTestCase {

    // MARK: - UserRole.canCreateListings

    func testBuyerCannotCreateListings() {
        // Given/When: a buyer role
        let role = UserRole.buyer

        // Then: listing creation is not permitted
        XCTAssertFalse(role.canCreateListings, "Buyers should not be allowed to create listings")
    }

    func testAgentCanCreateListings() {
        // Given/When: an agent role
        let role = UserRole.agent

        // Then: listing creation is permitted
        XCTAssertTrue(role.canCreateListings, "Agents should be allowed to create listings")
    }

    func testHomeownerCanCreateListings() {
        // Given/When: a homeowner (FSBO) role
        let role = UserRole.homeowner

        // Then: listing creation is permitted
        XCTAssertTrue(role.canCreateListings, "Homeowners should be allowed to create their own listings")
    }

    // MARK: - UserRole.requiresLicenseNumber

    func testAgentRequiresLicenseNumber() {
        // Given/When: an agent role
        let role = UserRole.agent

        // Then: a license number is required
        XCTAssertTrue(role.requiresLicenseNumber, "Agents must provide a license number")
    }

    func testBuyerDoesNotRequireLicenseNumber() {
        // Given/When: a buyer role
        let role = UserRole.buyer

        // Then: no license number is required
        XCTAssertFalse(role.requiresLicenseNumber, "Buyers do not need a license number")
    }

    func testHomeownerDoesNotRequireLicenseNumber() {
        // Given/When: a homeowner role
        let role = UserRole.homeowner

        // Then: no license number is required
        XCTAssertFalse(role.requiresLicenseNumber, "Homeowners do not need a license number")
    }

    // MARK: - UserRole.displayName

    func testAllRolesHaveNonEmptyDisplayName() {
        // Given: every known role
        for role in UserRole.allCases {
            // Then: displayName must not be empty
            XCTAssertFalse(
                role.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                "\(role.rawValue) must have a non-empty displayName"
            )
        }
    }

    // MARK: - UserRole.allCases

    func testAllCasesHasExactlyThreeCases() {
        // Given/When: the full case list
        let cases = UserRole.allCases

        // Then: there are exactly three roles
        XCTAssertEqual(cases.count, 3, "UserRole should have exactly 3 cases")
    }

    func testAllCasesContainsExpectedRoles() {
        // Given/When: the full case list
        let cases = UserRole.allCases

        // Then: each expected role is present
        XCTAssertTrue(cases.contains(.buyer))
        XCTAssertTrue(cases.contains(.agent))
        XCTAssertTrue(cases.contains(.homeowner))
    }

    // MARK: - AuthViewModel license number validation

    func testAgentWithEmptyLicenseNumberFailsFormValidation() async throws {
        // Given: an AuthViewModel backed by a mock service
        let mockAuth = MockAuthenticationService(simulateNetworkDelay: false)
        let viewModel = await AuthViewModel(authService: mockAuth)

        // When: the form is filled with agent role but no license number
        await MainActor.run {
            viewModel.registerName = "Alice Agent"
            viewModel.registerEmail = "alice@brokerage.ca"
            viewModel.registerPassword = "Password1"
            viewModel.registerConfirmPassword = "Password1"
            viewModel.registerRole = .agent
            viewModel.registerLicenseNumber = ""
        }

        // Then: sign-up should not succeed and licenseNumberValidationError should be set
        await viewModel.signUp()

        await MainActor.run {
            XCTAssertFalse(viewModel.isAuthenticated, "Registration should fail when agent license number is missing")
        }
    }

    func testAgentWithNonEmptyLicenseNumberPassesThatValidation() async throws {
        // Given: an AuthViewModel backed by a mock service
        let mockAuth = MockAuthenticationService(simulateNetworkDelay: false)
        let viewModel = await AuthViewModel(authService: mockAuth)

        // When: the form is filled with agent role and a valid license number
        await MainActor.run {
            viewModel.registerName = "Bob Agent"
            viewModel.registerEmail = "bob@brokerage.ca"
            viewModel.registerPassword = "Password1"
            viewModel.registerConfirmPassword = "Password1"
            viewModel.registerRole = .agent
            viewModel.registerLicenseNumber = "RECO-123456"
        }

        // Then: sign-up should succeed
        await viewModel.signUp()

        await MainActor.run {
            XCTAssertTrue(viewModel.isAuthenticated, "Registration should succeed when agent provides a license number")
            XCTAssertNil(viewModel.licenseNumberValidationError, "No license number error expected")
        }
    }

    func testBuyerRegistrationIgnoresLicenseNumberField() async throws {
        // Given: an AuthViewModel backed by a mock service
        let mockAuth = MockAuthenticationService(simulateNetworkDelay: false)
        let viewModel = await AuthViewModel(authService: mockAuth)

        // When: the form is filled with buyer role and the license field is left empty
        await MainActor.run {
            viewModel.registerName = "Carol Buyer"
            viewModel.registerEmail = "carol@example.ca"
            viewModel.registerPassword = "Password1"
            viewModel.registerConfirmPassword = "Password1"
            viewModel.registerRole = .buyer
            viewModel.registerLicenseNumber = ""
        }

        // Then: sign-up should still succeed — an empty license number must not block buyers
        await viewModel.signUp()

        await MainActor.run {
            XCTAssertTrue(viewModel.isAuthenticated, "Buyers should be able to register without a license number")
        }
    }
}
