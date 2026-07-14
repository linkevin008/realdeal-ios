import Foundation

// MARK: - API Error

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int, String, String?)
    case decodingError(Error)
    case notSupported

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid server response"
        case .httpError(let code, let message, _):
            return "Server error \(code): \(message)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .notSupported:
            return "This operation is not supported by the current backend"
        }
    }
}

extension APIError {
    var asAppError: AppError {
        guard case .httpError(let status, _, let code) = self else {
            return .unknown(localizedDescription)
        }
        switch code ?? "" {
        case "EMAIL_TAKEN":         return .authentication(.emailAlreadyExists)
        case "INVALID_CREDENTIALS": return .authentication(.invalidCredentials)
        case "UNAUTHORIZED":        return .authentication(.sessionExpired)
        default: break
        }
        switch status {
        case 400: return .network(.badRequest)
        case 401: return .authentication(.invalidCredentials)
        case 409: return .authentication(.emailAlreadyExists)
        case 503: return .network(.serviceUnavailable)
        default:  return .network(.serverError(statusCode: status))
        }
    }
}

// MARK: - URLSession Protocol

protocol URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}

// MARK: - API Client

@available(iOS 15.0, macOS 12.0, *)
final class APIClient {
    let baseURL: URL
    private let session: any URLSessionProtocol
    let keychainManager: KeychainManager

    static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        // Go encodes time.Time with nanoseconds (e.g. "2026-03-29T17:15:23.143527891Z")
        // which Swift's plain .iso8601 strategy can't parse — use a custom formatter instead
        let withFractional = ISO8601DateFormatter()
        withFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let withoutFractional = ISO8601DateFormatter()
        withoutFractional.formatOptions = [.withInternetDateTime]
        d.dateDecodingStrategy = .custom { decoder in
            let string = try decoder.singleValueContainer().decode(String.self)
            if let date = withFractional.date(from: string) { return date }
            if let date = withoutFractional.date(from: string) { return date }
            throw DecodingError.dataCorruptedError(
                in: try decoder.singleValueContainer(),
                debugDescription: "Cannot parse date: \(string)"
            )
        }
        return d
    }()

    static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        // Go binds date fields into time.Time/*time.Time, which require RFC3339
        // strings on the wire. Without an explicit strategy here, JSONEncoder
        // defaults to .deferredToDate (a Double of seconds since 2001), which
        // the Go backend can't unmarshal — every request body carrying a Date
        // (e.g. viewing-slot start/end times, contract move-in/transfer dates)
        // would 400 against the live server. .iso8601 produces e.g.
        // "2026-07-15T00:00:00Z", which Go's time.Time accepts.
        // (Decoding is unaffected — see `decoder` above, which already uses a
        // custom fractional-seconds RFC3339 strategy to parse Go's responses.)
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    init(baseURL: URL, keychainManager: KeychainManager = .shared) {
        self.baseURL = baseURL
        self.keychainManager = keychainManager
        self.session = URLSession.shared
    }

    /// Initializer that accepts a URLSessionProtocol — intended for unit tests that inject a spy session.
    init(baseURL: URL, keychainManager: KeychainManager = .shared, session: any URLSessionProtocol) {
        self.baseURL = baseURL
        self.keychainManager = keychainManager
        self.session = session
    }

    func get<T: Decodable>(_ path: String, queryItems: [URLQueryItem] = [], requiresAuth: Bool = false) async throws -> T {
        let req = try buildRequest(path: path, method: "GET", queryItems: queryItems, requiresAuth: requiresAuth)
        return try await send(req)
    }

    func post<B: Encodable, T: Decodable>(_ path: String, body: B, requiresAuth: Bool = false) async throws -> T {
        var req = try buildRequest(path: path, method: "POST", requiresAuth: requiresAuth)
        req.httpBody = try Self.encoder.encode(body)
        return try await send(req)
    }

    func postVoid(_ path: String, requiresAuth: Bool = false) async throws {
        let req = try buildRequest(path: path, method: "POST", requiresAuth: requiresAuth)
        try await sendVoid(req)
    }

    func put<B: Encodable, T: Decodable>(_ path: String, body: B, requiresAuth: Bool = false) async throws -> T {
        var req = try buildRequest(path: path, method: "PUT", requiresAuth: requiresAuth)
        req.httpBody = try Self.encoder.encode(body)
        return try await send(req)
    }

    func delete(_ path: String, requiresAuth: Bool = false) async throws {
        let req = try buildRequest(path: path, method: "DELETE", requiresAuth: requiresAuth)
        try await sendVoid(req)
    }

    // MARK: - Private

    private func buildRequest(
        path: String,
        method: String,
        queryItems: [URLQueryItem] = [],
        requiresAuth: Bool
    ) throws -> URLRequest {
        var components = URLComponents(
            url: baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        )!
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if requiresAuth, let token = try? keychainManager.retrieveToken() {
            req.setValue("Bearer \(token.accessToken)", forHTTPHeaderField: "Authorization")
        }
        return req
    }

    private func send<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)
        try checkStatus(data: data, response: response)
        do {
            return try Self.decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    private func sendVoid(_ request: URLRequest) async throws {
        let (data, response) = try await session.data(for: request)
        try checkStatus(data: data, response: response)
    }

    private func checkStatus(data: Data, response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            struct ErrorBody: Decodable { let error: String; let code: String? }
            let body = try? JSONDecoder().decode(ErrorBody.self, from: data)
            throw APIError.httpError(http.statusCode, body?.error ?? "Request failed", body?.code)
        }
    }
}
