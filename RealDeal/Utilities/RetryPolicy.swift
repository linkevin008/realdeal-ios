import Foundation

/// Configuration for retry behavior with exponential backoff
struct RetryPolicy {
    /// Maximum number of retry attempts
    let maxAttempts: Int
    
    /// Initial delay before first retry (in seconds)
    let initialDelay: TimeInterval
    
    /// Multiplier for exponential backoff
    let multiplier: Double
    
    /// Maximum delay between retries (in seconds)
    let maxDelay: TimeInterval
    
    /// Jitter factor to randomize delays (0.0 to 1.0)
    let jitter: Double
    
    /// Default retry policy for network requests
    static let `default` = RetryPolicy(
        maxAttempts: 3,
        initialDelay: 1.0,
        multiplier: 2.0,
        maxDelay: 10.0,
        jitter: 0.1
    )
    
    /// Aggressive retry policy for critical operations
    static let aggressive = RetryPolicy(
        maxAttempts: 5,
        initialDelay: 0.5,
        multiplier: 2.0,
        maxDelay: 30.0,
        jitter: 0.2
    )
    
    /// Conservative retry policy for non-critical operations
    static let conservative = RetryPolicy(
        maxAttempts: 2,
        initialDelay: 2.0,
        multiplier: 3.0,
        maxDelay: 15.0,
        jitter: 0.1
    )
    
    /// Calculate delay for a given attempt number
    /// - Parameter attempt: The attempt number (0-based)
    /// - Returns: Delay in seconds before the next retry
    func delay(for attempt: Int) -> TimeInterval {
        let exponentialDelay = initialDelay * pow(multiplier, Double(attempt))
        let cappedDelay = min(exponentialDelay, maxDelay)
        
        // Add jitter to prevent thundering herd
        let jitterAmount = cappedDelay * jitter * Double.random(in: -1...1)
        let finalDelay = max(0, cappedDelay + jitterAmount)
        
        return finalDelay
    }
}

/// Utility for executing operations with retry logic and exponential backoff
@available(iOS 15.0, macOS 12.0, *)
actor RetryExecutor {
    /// Execute an operation with retry logic
    /// - Parameters:
    ///   - policy: The retry policy to use
    ///   - operation: The async operation to execute
    /// - Returns: The result of the operation
    /// - Throws: The last error encountered if all retries fail
    static func execute<T>(
        policy: RetryPolicy = .default,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 0..<policy.maxAttempts {
            do {
                return try await operation()
            } catch let error as AppError {
                lastError = error
                
                // Don't retry if error is not retryable
                guard error.isRetryable else {
                    throw error
                }
                
                // Don't retry on last attempt
                if attempt < policy.maxAttempts - 1 {
                    let delay = policy.delay(for: attempt)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            } catch {
                lastError = error
                
                // For unknown errors, retry anyway
                if attempt < policy.maxAttempts - 1 {
                    let delay = policy.delay(for: attempt)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        // All retries failed, throw the last error
        throw lastError ?? AppError.unknown("All retry attempts failed")
    }
    
    /// Execute an operation with retry logic and a timeout
    /// - Parameters:
    ///   - policy: The retry policy to use
    ///   - timeout: Maximum time to wait for the operation (in seconds)
    ///   - operation: The async operation to execute
    /// - Returns: The result of the operation
    /// - Throws: The last error encountered or a timeout error
    static func executeWithTimeout<T>(
        policy: RetryPolicy = .default,
        timeout: TimeInterval,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            // Add the main operation with retry
            group.addTask {
                try await execute(policy: policy, operation: operation)
            }
            
            // Add timeout task
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw AppError.network(.connectionTimeout)
            }
            
            // Return first result (either success or timeout)
            let result = try await group.next()!
            
            // Cancel remaining tasks
            group.cancelAll()
            
            return result
        }
    }
}
