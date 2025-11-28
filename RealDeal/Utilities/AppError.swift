import Foundation

enum AppError: Error, LocalizedError {
    case network(NetworkError)
    case validation(ValidationError)
    case authentication(AuthError)
    case notFound
    case unauthorized
    case unknown(Error)
    
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
        case .notFound:
            return "The requested resource was not found."
        case .unauthorized:
            return "You don't have permission to access this resource."
        case .unknown(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .network(let error):
            return error.isRetryable
        case .authentication(.sessionExpired):
            return true
        default:
            return false
        }
    }
}

enum NetworkError: Error {
    case connectionTimeout
    case noInternetConnection
    case rateLimitExceeded
    case serverError(statusCode: Int)
    case invalidResponse
    case requestCancelled
    
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
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .connectionTimeout, .noInternetConnection, .serverError:
            return true
        default:
            return false
        }
    }
}

enum ValidationError: Error {
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

enum AuthError: Error {
    case invalidCredentials
    case userNotFound
    case emailAlreadyExists
    case sessionExpired
    case tokenRefreshFailed
    
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
        }
    }
}
