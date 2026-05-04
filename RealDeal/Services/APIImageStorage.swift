import Foundation

/// APIImageStorage uploads images via the presign flow:
/// 1. Request a presigned S3 PUT URL from the API.
/// 2. PUT image bytes directly to S3 (no auth header — the presigned URL is self-authenticating).
/// 3. Return the CloudFront public URL.
@available(iOS 15.0, macOS 12.0, *)
final class APIImageStorage: ImageStorageProtocol {
    private let client: APIClient
    private let session: any URLSessionProtocol

    init(client: APIClient, session: any URLSessionProtocol = URLSession.shared) {
        self.client = client
        self.session = session
    }

    // MARK: - ImageStorageProtocol

    func uploadImage(_ imageData: Data, path: String) async throws -> URL {
        let uploadType = uploadType(for: path)
        let filename = (path as NSString).lastPathComponent.isEmpty
            ? "image.jpg"
            : (path as NSString).lastPathComponent

        // Step 1: Request presigned URL from the API.
        let presignReq = PresignRequest(
            filename: filename,
            contentType: "image/jpeg",
            uploadType: uploadType
        )
        let presignResp: PresignResponse = try await client.post(
            "api/v1/upload/presign",
            body: presignReq,
            requiresAuth: true
        )

        // Step 2: PUT image data directly to S3 using the presigned URL.
        // No Authorization header — the presigned URL is self-authenticating.
        guard let s3URL = URL(string: presignResp.uploadUrl) else {
            throw APIError.invalidURL
        }
        var s3Request = URLRequest(url: s3URL)
        s3Request.httpMethod = "PUT"
        s3Request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        s3Request.httpBody = imageData

        let (_, s3Response) = try await session.data(for: s3Request)
        guard let http = s3Response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.invalidResponse
        }

        // Step 3: Return the CloudFront public URL.
        guard let publicURL = URL(string: presignResp.publicUrl) else {
            throw APIError.invalidURL
        }
        return publicURL
    }

    func deleteImage(url: URL) async throws {
        // Remote deletion via presigned URLs is not supported yet.
        throw APIError.notSupported
    }

    func uploadImages(_ images: [(data: Data, path: String)]) async throws -> [URL] {
        var urls: [URL] = []
        for (data, path) in images {
            let url = try await uploadImage(data, path: path)
            urls.append(url)
        }
        return urls
    }

    func deleteImages(urls: [URL]) async throws {
        // Remote deletion via presigned URLs is not supported yet.
        throw APIError.notSupported
    }

    // MARK: - Private

    /// Derives the upload_type from a storage path prefix.
    ///   "properties/..." -> "property"
    ///   "profiles/..."   -> "profile"
    ///   "id_verification/..." -> "id_verification"
    ///   default -> "property"
    private func uploadType(for path: String) -> String {
        if path.hasPrefix("properties/") { return "property" }
        if path.hasPrefix("profiles/")   { return "profile" }
        if path.hasPrefix("id_verification/") { return "id_verification" }
        return "property"
    }
}

// MARK: - Private DTOs

private struct PresignRequest: Encodable {
    let filename: String
    let contentType: String
    let uploadType: String
}

private struct PresignResponse: Decodable {
    let uploadUrl: String
    let publicUrl: String
    let key: String
}
