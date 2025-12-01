# Error Handling and Network Resilience

This document describes the comprehensive error handling and network resilience system implemented in the RealDeal application.

## Overview

The error handling system provides:
- **Comprehensive error categorization** with user-friendly messages
- **Automatic retry logic** with exponential backoff
- **Network timeout and cancellation** support
- **Offline-first architecture** with graceful degradation
- **Multiple UI patterns** for displaying errors to users

## Components

### 1. AppError Enum (`AppError.swift`)

Central error type that categorizes all application errors:

```swift
enum AppError: Error {
    case network(NetworkError)
    case validation(ValidationError)
    case authentication(AuthError)
    case storage(StorageError)
    case dataCorruption
    case notFound
    case unauthorized
    case conflict
    case unknown(String)
}
```

**Key Features:**
- User-friendly error messages via `userMessage` property
- Retryability indication via `isRetryable` property
- Nested error types for specific domains

### 2. Retry Policy (`RetryPolicy.swift`)

Configurable retry behavior with exponential backoff:

```swift
let policy = RetryPolicy(
    maxAttempts: 3,
    initialDelay: 1.0,
    multiplier: 2.0,
    maxDelay: 10.0,
    jitter: 0.1
)
```

**Predefined Policies:**
- `.default` - Standard retry for most operations (3 attempts)
- `.aggressive` - For critical operations (5 attempts)
- `.conservative` - For non-critical operations (2 attempts)

**Usage:**

```swift
// Simple retry
let result = try await RetryExecutor.execute(policy: .default) {
    try await someNetworkOperation()
}

// Retry with timeout
let result = try await RetryExecutor.executeWithTimeout(
    policy: .default,
    timeout: 30.0
) {
    try await someNetworkOperation()
}
```

### 3. Network Request Management (`NetworkRequest.swift`)

Handles request timeouts and cancellation:

```swift
let request = NetworkRequest()
let result = try await request.execute(timeout: 30.0) {
    try await fetchData()
}

// Cancel if needed
await request.cancel()
```

**NetworkRequestManager** for managing multiple concurrent requests:

```swift
let manager = NetworkRequestManager()

// Execute with unique ID (auto-cancels previous request with same ID)
let result = try await manager.execute(id: "fetchProperties") {
    try await fetchProperties()
}

// Cancel specific request
await manager.cancel(id: "fetchProperties")

// Cancel all requests
await manager.cancelAll()
```

### 4. Network Monitor (`NetworkMonitor.swift`)

Tracks network connectivity and connection type:

```swift
let monitor = NetworkMonitor.shared

// Check connectivity
if monitor.isConnected {
    // Perform network operation
}

// Get connection details
print(monitor.connectionDescription) // "Wi-Fi", "Cellular", etc.

// Detect connection changes
if monitor.wasRecentlyReconnected {
    // Sync pending changes
}

// Require connection (throws if offline)
try monitor.requireConnection()
```

### 5. Error UI Components (`ErrorAlertView.swift`)

Multiple patterns for displaying errors:

#### Alert-Based Errors

```swift
struct MyView: View {
    @State private var error: AppError?
    
    var body: some View {
        content
            .errorAlert(error: $error) {
                // Optional retry action
                retryOperation()
            }
    }
}
```

#### Error Banners

```swift
if let error = viewModel.error {
    ErrorBannerView(
        message: error.userMessage,
        isRetryable: error.isRetryable,
        onRetry: { viewModel.retry() },
        onDismiss: { viewModel.dismissError() }
    )
}
```

#### Inline Errors (for forms)

```swift
if let error = validationError {
    InlineErrorView(message: error)
}
```

#### Network Status Banner

```swift
NetworkStatusBanner(networkMonitor: NetworkMonitor.shared)
```

## Usage Patterns

### Pattern 1: Repository with Retry Logic

```swift
class PropertyRepository: PropertyRepositoryProtocol {
    private let retryPolicy: RetryPolicy
    
    func fetchProperties() async throws -> [Property] {
        if networkMonitor.isConnected {
            do {
                // Use retry logic for network requests
                let properties = try await RetryExecutor.execute(policy: retryPolicy) {
                    try await self.remoteDataSource.fetchProperties()
                }
                
                // Cache results
                try await localDataSource.saveProperties(properties)
                return properties
            } catch {
                // Fall back to cache on error
                return try await localDataSource.fetchProperties()
            }
        } else {
            // Offline: use cache
            return try await localDataSource.fetchProperties()
        }
    }
}
```

### Pattern 2: ViewModel with Error Handling

```swift
@MainActor
class PropertyListViewModel: ObservableObject {
    @Published var error: AppError?
    @Published var isLoading = false
    
    func loadProperties() async {
        isLoading = true
        error = nil
        
        do {
            properties = try await repository.fetchProperties()
        } catch let appError as AppError {
            error = appError
        } catch {
            error = AppError.unknown(error.localizedDescription)
        }
        
        isLoading = false
    }
    
    func retry() async {
        await loadProperties()
    }
}
```

### Pattern 3: View with Multiple Error Display Options

```swift
struct PropertyListView: View {
    @StateObject private var viewModel = PropertyListViewModel()
    @ObservedObject var networkMonitor = NetworkMonitor.shared
    
    var body: some View {
        VStack {
            // Network status banner
            NetworkStatusBanner(networkMonitor: networkMonitor)
            
            // Persistent error banner
            if let error = viewModel.error {
                ErrorBannerView(
                    message: error.userMessage,
                    isRetryable: error.isRetryable,
                    onRetry: { Task { await viewModel.retry() } },
                    onDismiss: { viewModel.error = nil }
                )
            }
            
            // Content
            List(viewModel.properties) { property in
                PropertyRow(property: property)
            }
        }
        .errorAlert(error: $viewModel.error) {
            Task { await viewModel.retry() }
        }
    }
}
```

## Error Categories

### Network Errors
- `connectionTimeout` - Request took too long (retryable)
- `noInternetConnection` - Device is offline (retryable)
- `rateLimitExceeded` - Too many requests (retryable with backoff)
- `serverError` - Server returned 5xx (retryable)
- `invalidResponse` - Malformed response (not retryable)
- `requestCancelled` - User or system cancelled (not retryable)
- `badRequest` - Invalid request (not retryable)
- `serviceUnavailable` - Service temporarily down (retryable)

### Validation Errors
- `missingRequiredField` - Required field is empty
- `invalidFormat` - Field format is incorrect
- `invalidImageFormat` - Image type not supported
- `imageSizeExceeded` - Image too large
- `invalidEmailFormat` - Email format invalid
- `weakPassword` - Password doesn't meet requirements
- `invalidPriceRange` - Price range is invalid
- `invalidLocation` - Location data is invalid

### Authentication Errors
- `invalidCredentials` - Wrong email/password
- `userNotFound` - User doesn't exist
- `emailAlreadyExists` - Email already registered
- `sessionExpired` - Session timed out (retryable)
- `tokenRefreshFailed` - Token refresh failed
- `accountDisabled` - Account has been disabled
- `tooManyAttempts` - Too many login attempts

### Storage Errors
- `diskFull` - Not enough storage space
- `permissionDenied` - No permission to access storage
- `fileNotFound` - File doesn't exist
- `corruptedData` - Data is corrupted (retryable)
- `saveFailed` - Failed to save (retryable)
- `deleteFailed` - Failed to delete (retryable)
- `uploadFailed` - Failed to upload (retryable)

## Best Practices

### 1. Always Categorize Errors

Convert all errors to `AppError` for consistent handling:

```swift
do {
    try await operation()
} catch let error as AppError {
    throw error
} catch let urlError as URLError {
    throw AppError.network(.connectionTimeout)
} catch {
    throw AppError.unknown(error.localizedDescription)
}
```

### 2. Use Appropriate Retry Policies

- **Critical operations** (user data): Use `.aggressive`
- **Standard operations** (browsing): Use `.default`
- **Background operations** (analytics): Use `.conservative`

### 3. Implement Offline-First

Always try to serve from cache when network fails:

```swift
if networkMonitor.isConnected {
    do {
        return try await fetchFromRemote()
    } catch {
        return try await fetchFromCache()
    }
} else {
    return try await fetchFromCache()
}
```

### 4. Provide Retry Options

For retryable errors, always offer a retry button:

```swift
.errorAlert(error: $error) {
    Task { await retry() }
}
```

### 5. Handle Timeouts

Use timeouts for all network operations:

```swift
try await RetryExecutor.executeWithTimeout(
    policy: .default,
    timeout: 30.0
) {
    try await networkOperation()
}
```

### 6. Monitor Network State

React to connectivity changes:

```swift
if networkMonitor.wasRecentlyReconnected {
    // Sync pending changes
    await syncPendingChanges()
}
```

## Testing

### Testing Retry Logic

```swift
func testRetryOnFailure() async throws {
    var attempts = 0
    
    do {
        try await RetryExecutor.execute(policy: .default) {
            attempts += 1
            if attempts < 3 {
                throw AppError.network(.connectionTimeout)
            }
        }
    } catch {
        XCTFail("Should have succeeded after retries")
    }
    
    XCTAssertEqual(attempts, 3)
}
```

### Testing Error Handling

```swift
func testErrorHandling() async {
    let viewModel = PropertyListViewModel()
    
    // Trigger error
    await viewModel.loadProperties()
    
    // Verify error is set
    XCTAssertNotNil(viewModel.error)
    XCTAssertTrue(viewModel.error?.isRetryable ?? false)
}
```

## Requirements Validation

This implementation satisfies the following requirements:

- **Requirement 10.1**: Network connectivity loss displays clear error messages
- **Requirement 10.2**: Network request failures provide retry options
- **Requirement 10.5**: Network timeouts notify users and allow cancellation

The system provides:
- ✅ Comprehensive error categorization
- ✅ Exponential backoff retry logic
- ✅ User-friendly error messages
- ✅ Multiple error display patterns (alerts, banners, inline)
- ✅ Request timeout and cancellation support
- ✅ Network monitoring and offline support
- ✅ Graceful degradation with cache fallback
