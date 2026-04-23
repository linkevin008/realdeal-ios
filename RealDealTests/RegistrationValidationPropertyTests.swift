import XCTest
import SwiftCheck
@testable import RealDeal

// MARK: - Registration Validation Property Tests (Requirement 6.3)
//
// Property-based tests verify that PasswordValidator enforces its rules universally
// across hundreds of randomly generated inputs — not just a handful of hand-picked
// examples. SwiftCheck automatically shrinks any failing case to the smallest
// counterexample, making failures easy to diagnose.
//
// Four invariants are tested, one per PasswordValidator rule:
//   1. Passwords satisfying all rules always pass.
//   2. Passwords shorter than 8 characters always fail.
//   3. Passwords without an uppercase letter always fail.
//   4. Passwords without a lowercase letter always fail.
//   5. Passwords without a digit always fail.

final class RegistrationValidationPropertyTests: XCTestCase {

    // MARK: - Character Sets

    private static let uppercase: [Character] = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    private static let lowercase: [Character] = Array("abcdefghijklmnopqrstuvwxyz")
    private static let digits: [Character]    = Array("0123456789")
    private static let alphanum: [Character]  = uppercase + lowercase + digits

    // MARK: - Generators

    /// Produces passwords that satisfy every PasswordValidator rule:
    /// at least one uppercase, one lowercase, one digit, and ≥ 8 characters total.
    private static var validPasswordGen: Gen<String> {
        Gen.compose { c in
            let u = c.generate(using: Gen.fromElements(of: uppercase))
            let l = c.generate(using: Gen.fromElements(of: lowercase))
            let d = c.generate(using: Gen.fromElements(of: digits))
            // 5 extra alphanumeric chars guarantee the 8-char minimum is always met.
            let filler = (0..<5).map { _ in c.generate(using: Gen.fromElements(of: alphanum)) }
            return String(([u, l, d] + filler).shuffled())
        }
    }

    /// Produces strings strictly shorter than 8 characters (0–7 chars, alphanumeric).
    private static var tooShortGen: Gen<String> {
        Gen.compose { c in
            let length = c.generate(using: Gen<Int>.choose((0, 7)))
            let chars  = (0..<length).map { _ in c.generate(using: Gen.fromElements(of: alphanum)) }
            return String(chars)
        }
    }

    /// Produces passwords that are ≥ 8 chars and contain a lowercase + digit,
    /// but deliberately contain NO uppercase letter.
    private static var missingUppercaseGen: Gen<String> {
        let lowerAndDigit = lowercase + digits
        return Gen.compose { c in
            let l      = c.generate(using: Gen.fromElements(of: lowercase))
            let d      = c.generate(using: Gen.fromElements(of: digits))
            let filler = (0..<6).map { _ in c.generate(using: Gen.fromElements(of: lowerAndDigit)) }
            return String(([l, d] + filler).shuffled())
        }
    }

    /// Produces passwords that are ≥ 8 chars and contain an uppercase + digit,
    /// but deliberately contain NO lowercase letter.
    private static var missingLowercaseGen: Gen<String> {
        let upperAndDigit = uppercase + digits
        return Gen.compose { c in
            let u      = c.generate(using: Gen.fromElements(of: uppercase))
            let d      = c.generate(using: Gen.fromElements(of: digits))
            let filler = (0..<6).map { _ in c.generate(using: Gen.fromElements(of: upperAndDigit)) }
            return String(([u, d] + filler).shuffled())
        }
    }

    /// Produces passwords that are ≥ 8 chars and contain an uppercase + lowercase,
    /// but deliberately contain NO digit.
    private static var missingDigitGen: Gen<String> {
        let letters = uppercase + lowercase
        return Gen.compose { c in
            let u      = c.generate(using: Gen.fromElements(of: uppercase))
            let l      = c.generate(using: Gen.fromElements(of: lowercase))
            let filler = (0..<6).map { _ in c.generate(using: Gen.fromElements(of: letters)) }
            return String(([u, l] + filler).shuffled())
        }
    }

    // MARK: - Properties

    /// Every password that satisfies all four rules must pass validation.
    func testValidPasswordsAlwaysPass() {
        property("Any password with ≥8 chars, uppercase, lowercase, and digit passes validation") <-
            forAll(Self.validPasswordGen) { password in
                (try? PasswordValidator.validate(password)) != nil
            }
    }

    /// Every password shorter than 8 characters must fail validation,
    /// regardless of which characters it contains.
    func testTooShortPasswordsAlwaysFail() {
        property("Any password shorter than 8 characters fails validation") <-
            forAll(Self.tooShortGen) { password in
                (try? PasswordValidator.validate(password)) == nil
            }
    }

    /// Every password lacking an uppercase letter must fail validation,
    /// even when it otherwise meets the length, lowercase, and digit rules.
    func testPasswordsWithoutUppercaseAlwaysFail() {
        property("Any password without an uppercase letter fails validation") <-
            forAll(Self.missingUppercaseGen) { password in
                (try? PasswordValidator.validate(password)) == nil
            }
    }

    /// Every password lacking a lowercase letter must fail validation,
    /// even when it otherwise meets the length, uppercase, and digit rules.
    func testPasswordsWithoutLowercaseAlwaysFail() {
        property("Any password without a lowercase letter fails validation") <-
            forAll(Self.missingLowercaseGen) { password in
                (try? PasswordValidator.validate(password)) == nil
            }
    }

    /// Every password lacking a digit must fail validation,
    /// even when it otherwise meets the length, uppercase, and lowercase rules.
    func testPasswordsWithoutDigitAlwaysFail() {
        property("Any password without a digit fails validation") <-
            forAll(Self.missingDigitGen) { password in
                (try? PasswordValidator.validate(password)) == nil
            }
    }
}
