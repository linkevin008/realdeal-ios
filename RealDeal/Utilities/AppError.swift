import Foundation

enum AppError: Error, LocalizedError, Equatable {
    case network(NetworkError)
    case validation(ValidationError)
    case authentication(AuthError)
    case storage(StorageError)
    case dataCorruption
    case notFound
    case unauthorized
    case conflict
    case unknown(String)
    
    var errorDescription: String? {
        userMessage
    }
    
    var userMessage: String {
        switch self {
        case .network(let error):
            return error.userMessage
        case .validation(let error):
            return error.userMessage
        case .authentication(let error):
            return error.userMessage
        case .storage(let error):
            return error.userMessage
        case .dataCorruption:
            return "Data corruption detected. Please try refreshing."
        case .notFound:
            return "The requested resource was not found."
        case .unauthorized:
            return "You don't have permission to access this resource."
        case .conflict:
            return "A conflict occurred. The resource may have been modified."
        case .unknown(let message):
            return "An unexpected error occurred: \(message)"
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .network(let error):
            return error.isRetryable
        case .authentication(.sessionExpired):
            return true
        case .storage(.diskFull), .storage(.permissionDenied):
            return false
        case .storage:
            return true
        case .dataCorruption:
            return true
        case .conflict:
            return true
        default:
            return false
        }
    }
    
    static func == (lhs: AppError, rhs: AppError) -> Bool {
        switch (lhs, rhs) {
        case (.network(let l), .network(let r)):
            return l == r
        case (.validation(let l), .validation(let r)):
            return l == r
        case (.authentication(let l), .authentication(let r)):
            return l == r
        case (.storage(let l), .storage(let r)):
            return l == r
        case (.dataCorruption, .dataCorruption),
             (.notFound, .notFound),
             (.unauthorized, .unauthorized),
             (.conflict, .conflict):
            return true
        case (.unknown(let l), .unknown(let r)):
            return l == r
        default:
            return false
        }
    }
}

enum NetworkError: Error, Equatable {
    case connectionTimeout
    case noInternetConnection
    case rateLimitExceeded
    case serverError(statusCode: Int)
    case invalidResponse
    case requestCancelled
    case badRequest
    case serviceUnavailable
    
    var userMessage: String {
        switch self {
        case .connectionTimeout:
            return "The connection timed out. Please try again."
        case .noInternetConnection:
            return "No internet connection. Please check your network settings."
        case .rateLimitExceeded:
            return "Too many requests. Please wait a moment and try again."
        case .serverError(let code):
            return "Server error (\(code)). Please try again later."
        case .invalidResponse:
            return "Received an invalid response from the server."
        case .requestCancelled:
            return "The request was cancelled."
        case .badRequest:
            return "Invalid request. Please check your input and try again."
        case .serviceUnavailable:
            return "Service temporarily unavailable. Please try again later."
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .connectionTimeout, .noInternetConnection, .serverError, .serviceUnavailable:
            return true
        case .rateLimitExceeded:
            return true // Will retry with backoff
        default:
            return false
        }
    }
}

enum ValidationError: Error, Equatable {
    case missingRequiredField(String)
    case invalidFormat(String)
    case invalidImageFormat
    case imageSizeExceeded
    case imageTooLarge
    case invalidEmailFormat
    case weakPassword
    case invalidPriceRange
    case invalidLocation
    
    var userMessage: String {
        switch self {
        case .missingRequiredField(let field):
            return "\(field) is required."
        case .invalidFormat(let field):
            return "\(field) has an invalid format."
        case .invalidImageFormat:
            return "Please upload a valid image file (JPEG, PNG, or HEIC)."
        case .imageSizeExceeded, .imageTooLarge:
            return "Image size exceeds the maximum allowed size (5 MB)."
        case .invalidEmailFormat:
            return "Please enter a valid email address."
        case .weakPassword:
            return "Password must be at least 8 characters with letters and numbers."
        case .invalidPriceRange:
            return "Please enter a valid price range."
        case .invalidLocation:
            return "Please enter a valid location."
        }
    }
}

enum AuthError: Error, Equatable {
    case invalidCredentials
    case userNotFound
    case emailAlreadyExists
    case sessionExpired
    case tokenRefreshFailed
    case accountDisabled
    case tooManyAttempts
    
    var userMessage: String {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password."
        case .userNotFound:
            return "User account not found."
        case .emailAlreadyExists:
            return "An account with this email already exists."
        case .sessionExpired:
            return "Your session has expired. Please sign in again."
        case .tokenRefreshFailed:
            return "Failed to refresh authentication. Please sign in again."
        case .accountDisabled:
            return "This account has been disabled. Please contact support."
        case .tooManyAttempts:
            return "Too many login attempts. Please try again later."
        }
    }
}

enum StorageError: Error, Equatable {
    case diskFull
    case permissionDenied
    case fileNotFound
    case corruptedData
    case saveFailed
    case deleteFailed
    case uploadFailed
    
    var userMessage: String {
        switch self {
        case .diskFull:
            return "Not enough storage space available."
        case .permissionDenied:
            return "Permission denied to access storage."
        case .fileNotFound:
            return "The requested file was not found."
        case .corruptedData:
            return "The data is corrupted and cannot be read."
        case .saveFailed:
            return "Failed to save data. Please try again."
        case .deleteFailed:
            return "Failed to delete data. Please try again."
        case .uploadFailed:
            return "Failed to upload file. Please check your connection and try again."
        }
    }
}
