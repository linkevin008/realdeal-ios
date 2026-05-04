import XCTest
@testable import RealDeal

/// Tests for APIImageStorage — verifies path-to-upload_type mapping and the two-step presign + PUT flow.
@available(iOS 15.0, *)
final class APIImageStorageTests: XCTestCase {

    // MARK: - Path-to-upload_type mapping

    /// Tests that each known path prefix maps to the expected upload_type in the presign request body.
    func testPathToUploadTypeMappingProperty() async throws {
        let (storage, session) = makeStorage(responses: [presignResponse(), s3Response()])
        _ = try? await storage.uploadImage(Data([0xFF, 0xD8]), path: "properties/p1/img.jpg")
        let uploadType = extractUploadType(from: session.requests.first)
        XCTAssertEqual(uploadType, "property")
    }

    func testPathToUploadTypeMappingProfile() async throws {
        let (storage, session) = makeStorage(responses: [presignResponse(), s3Response()])
        _ = try? await storage.uploadImage(Data([0xFF, 0xD8]), path: "profiles/u1/photo.jpg")
        let uploadType = extractUploadType(from: session.requests.first)
        XCTAssertEqual(uploadType, "profile")
    }

    func testPathToUploadTypeMappingIDVerification() async throws {
        let (storage, session) = makeStorage(responses: [presignResponse(), s3Response()])
        _ = try? await storage.uploadImage(Data([0xFF, 0xD8]), path: "id_verification/u2/doc.jpg")
        let uploadType = extractUploadType(from: session.requests.first)
        XCTAssertEqual(uploadType, "id_verification")
    }

    func testPathToUploadTypeMappingDefault() async throws {
        let (storage, session) = makeStorage(responses: [presignResponse(), s3Response()])
        _ = try? await storage.uploadImage(Data([0xFF, 0xD8]), path: "unknown/something.jpg")
        let uploadType = extractUploadType(from: session.requests.first)
        XCTAssertEqual(uploadType, "property")
    }

    // MARK: - Presign + S3 PUT flow

    /// Successful upload: calls presign endpoint then PUTs to returned upload_url, returns public_url.
    func testUploadCallsPresignThenS3Put() async throws {
        let (storage, session) = makeStorage(responses: [presignResponse(), s3Response()])
        let url = try await storage.uploadImage(Data([0xFF, 0xD8]), path: "properties/p1/img.jpg")

        // Two requests: presign POST + S3 PUT
        XCTAssertEqual(session.requests.count, 2)
        XCTAssertEqual(session.requests[0].httpMethod, "POST")
        XCTAssertEqual(session.requests[1].httpMethod, "PUT")

        // Returned URL is the CloudFront public URL
        XCTAssertEqual(url.absoluteString, "https://cdn.example.com/property/user1/abc.jpg")
    }

    /// The S3 PUT must NOT include an Authorization header (would break S3 signature validation).
    func testS3PutHasNoAuthorizationHeader() async throws {
        let (storage, session) = makeStorage(responses: [presignResponse(), s3Response()])
        _ = try await storage.uploadImage(Data([0xFF, 0xD8]), path: "properties/p1/img.jpg")

        guard session.requests.count >= 2 else {
            XCTFail("Expected 2 requests, got \(session.requests.count)")
            return
        }
        let s3Req = session.requests[1]
        XCTAssertNil(s3Req.value(forHTTPHeaderField: "Authorization"),
                     "S3 presigned PUT must NOT contain an Authorization header")
    }

    // MARK: - Unsupported operations

    func testDeleteImageThrowsNotSupported() async {
        let (storage, _) = makeStorage()
        do {
            try await storage.deleteImage(url: URL(string: "https://cdn.example.com/img.jpg")!)
            XCTFail("Expected notSupported")
        } catch APIError.notSupported { /* expected */ }
          catch { XCTFail("Unexpected error: \(error)") }
    }

    func testDeleteImagesThrowsNotSupported() async {
        let (storage, _) = makeStorage()
        do {
            try await storage.deleteImages(urls: [URL(string: "https://cdn.example.com/img.jpg")!])
            XCTFail("Expected notSupported")
        } catch APIError.notSupported { /* expected */ }
          catch { XCTFail("Unexpected error: \(error)") }
    }

    // MARK: - Helpers

    private func makeStorage(
        responses: [(Data, URLResponse)] = []
    ) -> (APIImageStorage, SpyURLSession) {
        let session = SpyURLSession(responses: responses)
        let client = APIClient(
            baseURL: URL(string: "https://api.example.com")!,
            session: session
        )
        return (APIImageStorage(client: client, session: session), session)
    }

    private func presignResponse() -> (Data, URLResponse) {
        let json = """
        {"upload_url":"https://s3.amazonaws.com/bucket/property/user1/abc.jpg?sig=x",
         "public_url":"https://cdn.example.com/property/user1/abc.jpg",
         "key":"property/user1/abc.jpg"}
        """.data(using: .utf8)!
        let resp = HTTPURLResponse(
            url: URL(string: "https://api.example.com/api/v1/upload/presign")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        return (json, resp)
    }

    private func s3Response() -> (Data, URLResponse) {
        let resp = HTTPURLResponse(
            url: URL(string: "https://s3.amazonaws.com/bucket/property/user1/abc.jpg?sig=x")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        return (Data(), resp)
    }

    /// Extracts `upload_type` from the JSON body of a URLRequest.
    private func extractUploadType(from request: URLRequest?) -> String? {
        guard let body = request?.httpBody,
              let json = try? JSONDecoder().decode([String: String].self, from: body) else {
            return nil
        }
        return json["upload_type"]
    }
}

// MARK: - SpyURLSession

/// Records all requests and returns pre-configured responses without subclassing URLSession.
@available(iOS 15.0, *)
final class SpyURLSession: URLSessionProtocol {
    private(set) var requests: [URLRequest] = []
    private var responseQueue: [(Data, URLResponse)]

    init(responses: [(Data, URLResponse)] = []) {
        self.responseQueue = responses
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        guard !responseQueue.isEmpty else {
            throw URLError(.notConnectedToInternet)
        }
        return responseQueue.removeFirst()
    }
}
