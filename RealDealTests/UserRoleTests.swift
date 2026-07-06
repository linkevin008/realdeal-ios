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

    func testHomeownerCanCreateListings() {
        // Given/When: a homeowner (FSBO) role
        let role = UserRole.homeowner

        // Then: listing creation is permitted
        XCTAssertTrue(role.canCreateListings, "Homeowners should be allowed to create their own listings")
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

    func testAllCasesHasExactlyTwoCases() {
        // Given/When: the full case list
        let cases = UserRole.allCases

        // Then: there are exactly two roles
        XCTAssertEqual(cases.count, 2, "UserRole should have exactly 2 cases")
    }

    func testAllCasesContainsExpectedRoles() {
        // Given/When: the full case list
        let cases = UserRole.allCases

        // Then: each expected role is present
        XCTAssertTrue(cases.contains(.buyer))
        XCTAssertTrue(cases.contains(.homeowner))
    }
}
