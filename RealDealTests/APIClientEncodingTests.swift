import XCTest
@testable import RealDeal

// APIRemoteDataSource's request-body DTOs (createViewingSlot's Body,
// proposeTerms's Body) are declared as local `struct Body: Encodable` inside
// their respective functions, so we can't reference them by name here.
// Instead we mirror their shape with local structs and encode through the
// *actual* `APIClient.encoder` (same static instance production code uses:
// .convertToSnakeCase key strategy). This guards the bug the evaluator found
// during the contract-wizard review: the encoder had no dateEncodingStrategy,
// so it defaulted to .deferredToDate and emitted Dates as raw numbers
// (seconds since 2001) instead of RFC3339 strings. The Go backend binds date
// fields into time.Time/*time.Time, which only unmarshal RFC3339 strings —
// so every request body carrying a Date (viewing-slot start/end times,
// contract move-in/transfer dates) would 400 against the live server.
final class APIClientEncodingTests: XCTestCase {

    private struct WireCreateViewingSlotBody: Encodable {
        let startTime: Date
        let endTime: Date
    }

    private struct WireProposeTermsBody: Encodable {
        let moveInDate: Date?
        let transferDate: Date?
        let conditions: String
    }

    /// Matches an RFC3339/ISO8601 string such as "2026-07-15T00:00:00Z".
    private func isRFC3339String(_ value: Any?) -> Bool {
        guard let string = value as? String else { return false }
        let pattern = #"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?Z$"#
        return string.range(of: pattern, options: .regularExpression) != nil
    }

    private func decodeJSONObject(_ data: Data) throws -> [String: Any] {
        try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    func testEncodesViewingSlotBodyDatesAsRFC3339StringsUnderSnakeCaseKeys() throws {
        let start = Date(timeIntervalSince1970: 1_784_160_000) // 2026-07-16T00:00:00Z
        let end = Date(timeIntervalSince1970: 1_784_163_600)   // 2026-07-16T01:00:00Z
        let body = WireCreateViewingSlotBody(startTime: start, endTime: end)

        let data = try APIClient.encoder.encode(body)
        let json = try decodeJSONObject(data)

        XCTAssertNotNil(json["start_time"], "expected snake_case key start_time")
        XCTAssertNotNil(json["end_time"], "expected snake_case key end_time")
        XCTAssertTrue(isRFC3339String(json["start_time"]), "start_time should be an RFC3339 string, got \(String(describing: json["start_time"]))")
        XCTAssertTrue(isRFC3339String(json["end_time"]), "end_time should be an RFC3339 string, got \(String(describing: json["end_time"]))")
        XCTAssertFalse(json["start_time"] is NSNumber, "start_time must not encode as a number")
    }

    func testEncodesProposeTermsBodyDatesAsRFC3339StringsUnderSnakeCaseKeys() throws {
        let moveIn = Date(timeIntervalSince1970: 1_784_160_000)
        let transfer = Date(timeIntervalSince1970: 1_784_246_400)
        let body = WireProposeTermsBody(moveInDate: moveIn, transferDate: transfer, conditions: "As-is")

        let data = try APIClient.encoder.encode(body)
        let json = try decodeJSONObject(data)

        XCTAssertNotNil(json["move_in_date"], "expected snake_case key move_in_date")
        XCTAssertNotNil(json["transfer_date"], "expected snake_case key transfer_date")
        XCTAssertTrue(isRFC3339String(json["move_in_date"]), "move_in_date should be an RFC3339 string, got \(String(describing: json["move_in_date"]))")
        XCTAssertTrue(isRFC3339String(json["transfer_date"]), "transfer_date should be an RFC3339 string, got \(String(describing: json["transfer_date"]))")
        XCTAssertEqual(json["conditions"] as? String, "As-is")
    }

    func testEncodesProposeTermsBodyWithNilDatesOmitsThemButKeepsConditions() throws {
        let body = WireProposeTermsBody(moveInDate: nil, transferDate: nil, conditions: "Vacant possession")

        let data = try APIClient.encoder.encode(body)
        let json = try decodeJSONObject(data)

        XCTAssertNil(json["move_in_date"])
        XCTAssertNil(json["transfer_date"])
        XCTAssertEqual(json["conditions"] as? String, "Vacant possession")
    }

    func testDecoderStillParsesGosFractionalSecondsAfterEncoderChange() throws {
        // Guard against the encoder change accidentally affecting decode behavior:
        // the decoder must still accept Go's nanosecond-fractional RFC3339 output.
        struct Wrapper: Decodable { let value: Date }
        let json = #"{"value": "2026-07-16T00:00:00.123456789Z"}"#.data(using: .utf8)!

        let decoded = try APIClient.decoder.decode(Wrapper.self, from: json)

        XCTAssertEqual(decoded.value.timeIntervalSince1970, 1_784_160_000.123456789, accuracy: 0.001)
    }
}
