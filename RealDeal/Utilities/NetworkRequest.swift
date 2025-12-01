import Foundation

/// Wrapper for network requests with timeout and cancellation support
@available(iOS 15.0, macOS 12.0, *)
actor NetworkRequest {
    private var task: Task<Void, Never>?
    private var isCancelled = false
    
    /// Execute a network request with timeout support
    /// - Parameters:
    ///   - timeout: Maximum time to wait for the request (in seconds)
    ///   - request: The async request operation to execute
    /// - Returns: The result of the request
    /// - Throws: AppError if the request fails or times out
    func execute<T>(
        timeout: TimeInterval = 30.0,
        request: @escaping () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            // Add the main request task
            group.addTask { [weak self] in
                guard let self = self else {
                    throw AppError.network(.requestCancelled)
                }
                
                // Check if already cancelled
                if await self.isCancelled {
                    throw AppError.network(.requestCancelled)
                }
                
                return try await request()
            }
            
            // Add timeout task
            group.addTask { [weak self] in
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                
                // Cancel the request if it hasn't completed
                await self?.cancel()
                
                throw AppError.network(.connectionTimeout)
            }
            
            // Return first result (either success or timeout)
            let result = try await group.next()!
            
            // Cancel remaining tasks
            group.cancelAll()
            
            return result
        }
    }
    
    /// Cancel the current request
    func cancel() {
        isCancelled = true
        task?.cancel()
    }
    
    /// Reset cancellation state
    func reset() {
        isCancelled = false
    }
}

/// Manager for handling multiple concurrent network requests
@available(iOS 15.0, macOS 12.0, *)
actor NetworkRequestManager {
    private var requests: [String: NetworkRequest] = [:]
    
    /// Execute a network request with a unique identifier
    /// - Parameters:
    ///   - id: Unique identifier for the request
    ///   - timeout: Maximum time to wait for the request
    ///   - request: The async request operation to execute
    /// - Returns: The result of the request
    func execute<T>(
        id: String,
        timeout: TimeInterval = 30.0,
        request: @escaping () async throws -> T
    ) async throws -> T {
        // Cancel any existing request with the same ID
        if let existingRequest = requests[id] {
            await existingRequest.cancel()
        }
        
        // Create new request
        let networkRequest = NetworkRequest()
        requests[id] = networkRequest
        
        do {
            let result = try await networkRequest.execute(timeout: timeout, request: request)
            requests.removeValue(forKey: id)
            return result
        } catch {
            requests.removeValue(forKey: id)
            throw error
        }
    }
    
    /// Cancel a specific request by ID
    func cancel(id: String) async {
        if let request = requests[id] {
            await request.cancel()
            requests.removeValue(forKey: id)
        }
    }
    
    /// Cancel all active requests
    func cancelAll() async {
        for (_, request) in requests {
            await request.cancel()
        }
        requests.removeAll()
    }
}

/// Extension to URLSession for handling network errors
@available(iOS 15.0, macOS 12.0, *)
extension URLSession {
    /// Perform a data task with proper error handling
    /// - Parameter request: The URL request to execute
    /// - Returns: Data and response tuple
    /// - Throws: AppError with appropriate network error
    func dataTask(for request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            let (data, response) = try await data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AppError.network(.invalidResponse)
            }
            
            // Handle HTTP status codes
            switch httpResponse.statusCode {
            case 200...299:
                return (data, response)
            case 400:
                throw AppError.network(.badRequest)
            case 401:
                throw AppError.unauthorized
            case 404:
                throw AppError.notFound
            case 409:
                throw AppError.conflict
            case 429:
                throw AppError.network(.rateLimitExceeded)
            case 500...599:
                throw AppError.network(.serverError(statusCode: httpResponse.statusCode))
            case 503:
                throw AppError.network(.serviceUnavailable)
            default:
                throw AppError.network(.invalidResponse)
            }
        } catch let error as AppError {
            throw error
        } catch let urlError as URLError {
            // Convert URLError to AppError
            switch urlError.code {
            case .timedOut:
                throw AppError.network(.connectionTimeout)
            case .notConnectedToInternet, .networkConnectionLost:
                throw AppError.network(.noInternetConnection)
            case .cancelled:
                throw AppError.network(.requestCancelled)
            default:
                throw AppError.unknown(urlError.localizedDescription)
            }
        } catch {
            throw AppError.unknown(error.localizedDescription)
        }
    }
}
