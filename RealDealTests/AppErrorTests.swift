import XCTest
@testable import RealDeal

final class AppErrorTests: XCTestCase {

    // MARK: - User messages

    func testNetworkErrorMessages() {
        XCTAssertTrue(AppError.network(.connectionTimeout).userMessage.contains("timed out"))
        XCTAssertTrue(AppError.network(.noInternetConnection).userMessage.contains("internet"))
        XCTAssertTrue(AppError.network(.serverError(statusCode: 500)).userMessage.contains("500"))
    }

    func testValidationErrorMessages() {
        XCTAssertTrue(AppError.validation(.missingRequiredField("email")).userMessage.contains("email"))
        XCTAssertTrue(AppError.validation(.weakPassword).userMessage.contains("Password"))
        XCTAssertTrue(AppError.validation(.invalidLocation).userMessage.contains("location"))
    }

    func testAuthErrorMessages() {
        XCTAssertTrue(AppError.authentication(.invalidCredentials).userMessage.contains("Invalid"))
        XCTAssertTrue(AppError.authentication(.sessionExpired).userMessage.contains("expired"))
        XCTAssertTrue(AppError.authentication(.emailAlreadyExists).userMessage.contains("already exists"))
    }

    func testStorageErrorMessages() {
        XCTAssertTrue(AppError.storage(.diskFull).userMessage.contains("storage"))
        XCTAssertTrue(AppError.storage(.uploadFailed).userMessage.contains("upload"))
    }

    func testSimpleErrorMessages() {
        XCTAssertTrue(AppError.dataCorruption.userMessage.contains("corruption"))
        XCTAssertTrue(AppError.notFound.userMessage.contains("not found"))
        XCTAssertTrue(AppError.unauthorized.userMessage.contains("permission"))
        XCTAssertTrue(AppError.conflict.userMessage.contains("conflict"))
        XCTAssertTrue(AppError.unknown("boom").userMessage.contains("boom"))
    }

    // MARK: - isRetryable

    func testRetryableNetworkErrors() {
        XCTAssertTrue(AppError.network(.connectionTimeout).isRetryable)
        XCTAssertTrue(AppError.network(.noInternetConnection).isRetryable)
        XCTAssertTrue(AppError.network(.serverError(statusCode: 503)).isRetryable)
        XCTAssertFalse(AppError.network(.badRequest).isRetryable)
        XCTAssertFalse(AppError.network(.invalidResponse).isRetryable)
    }

    func testRetryableStorageErrors() {
        XCTAssertFalse(AppError.storage(.diskFull).isRetryable)
        XCTAssertFalse(AppError.storage(.permissionDenied).isRetryable)
        XCTAssertTrue(AppError.storage(.saveFailed).isRetryable)
        XCTAssertTrue(AppError.storage(.uploadFailed).isRetryable)
    }

    func testRetryableAuthErrors() {
        XCTAssertTrue(AppError.authentication(.sessionExpired).isRetryable)
        XCTAssertFalse(AppError.authentication(.invalidCredentials).isRetryable)
    }

    func testOtherRetryable() {
        XCTAssertTrue(AppError.dataCorruption.isRetryable)
        XCTAssertTrue(AppError.conflict.isRetryable)
        XCTAssertFalse(AppError.notFound.isRetryable)
        XCTAssertFalse(AppError.unauthorized.isRetryable)
    }

    // MARK: - Equatable

    func testEquality() {
        XCTAssertEqual(AppError.notFound, AppError.notFound)
        XCTAssertEqual(AppError.unknown("x"), AppError.unknown("x"))
        XCTAssertNotEqual(AppError.unknown("x"), AppError.unknown("y"))
        XCTAssertNotEqual(AppError.notFound, AppError.unauthorized)
        XCTAssertEqual(AppError.network(.badRequest), AppError.network(.badRequest))
        XCTAssertNotEqual(AppError.network(.badRequest), AppError.network(.connectionTimeout))
    }

    // MARK: - errorDescription (LocalizedError)

    func testErrorDescriptionMatchesUserMessage() {
        let error = AppError.unauthorized
        XCTAssertEqual(error.errorDescription, error.userMessage)
    }
}
