import XCTest
@testable import RealDeal

final class ProfilePhotoValidatorTests: XCTestCase {

    // MARK: - Size validation

    func testTooSmallDataThrows() {
        let tinyData = Data(repeating: 0xFF, count: 100) // 100 bytes < 1KB minimum
        XCTAssertThrowsError(try ProfilePhotoValidator.validate(tinyData))
    }

    func testTooLargeDataThrows() {
        let bigData = Data(repeating: 0xFF, count: 6 * 1024 * 1024) // 6MB > 5MB max
        XCTAssertThrowsError(try ProfilePhotoValidator.validate(bigData))
    }

    // MARK: - Format validation

    func testInvalidFormatThrows() {
        // 2KB of zeroes — not a valid image header
        let invalidData = Data(repeating: 0x00, count: 2048)
        XCTAssertThrowsError(try ProfilePhotoValidator.validate(invalidData)) { error in
            XCTAssertEqual(error as? ValidationError, .invalidImageFormat)
        }
    }

    func testRandomBytesFailFormatCheck() {
        // Random non-image bytes should fail format detection
        var data = Data([0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07])
        data.append(Data(repeating: 0xAB, count: 2048))
        XCTAssertThrowsError(try ProfilePhotoValidator.validate(data)) { error in
            XCTAssertEqual(error as? ValidationError, .invalidImageFormat)
        }
    }

    func testDataShorterThan12BytesFailsFormatCheck() {
        // isValidImageFormat returns false for data < 12 bytes, then validator throws invalidImageFormat
        let shortData = Data([0xFF, 0xD8, 0xFF]) // only 3 bytes
        XCTAssertThrowsError(try ProfilePhotoValidator.validate(shortData))
    }

    // MARK: - Constants

    func testMaxFileSizeIs5MB() {
        XCTAssertEqual(ProfilePhotoValidator.maxFileSize, 5 * 1024 * 1024)
    }

    func testMinFileSizeIs1KB() {
        XCTAssertEqual(ProfilePhotoValidator.minFileSize, 1024)
    }
}
