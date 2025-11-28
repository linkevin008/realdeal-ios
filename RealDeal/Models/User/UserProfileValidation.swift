import Foundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - UserProfile Validation

extension UserProfile {
    /// Validates the user profile data according to requirement 7.1
    func validate() throws {
        // Validate name (must not be empty)
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.missingRequiredField("name")
        }
        
        // Validate email format
        try validateEmail(email)
        
        // Validate phone number format if present
        if let phoneNumber = phoneNumber {
            try validatePhoneNumber(phoneNumber)
        }
        
        // Validate profile photo URL if present
        if let photoURL = profilePhotoURL {
            try validatePhotoURL(photoURL)
        }
    }
    
    private func validateEmail(_ email: String) throws {
        guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.missingRequiredField("email")
        }
        
        // Email format validation
        let emailPattern = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailPattern)
        guard emailPredicate.evaluate(with: email) else {
            throw ValidationError.invalidEmailFormat
        }
    }
    
    private func validatePhoneNumber(_ phoneNumber: String) throws {
        guard !phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return // Phone number is optional, empty is ok
        }
        
        // Basic phone number validation (allows various formats)
        let phonePattern = "^[+]?[(]?[0-9]{1,4}[)]?[-\\s\\.]?[(]?[0-9]{1,4}[)]?[-\\s\\.]?[0-9]{1,9}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phonePattern)
        guard phonePredicate.evaluate(with: phoneNumber) else {
            throw ValidationError.invalidFormat("phoneNumber")
        }
    }
    
    private func validatePhotoURL(_ url: URL) throws {
        // Validate that URL scheme is http or https
        guard let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else {
            throw ValidationError.invalidFormat("profilePhotoURL")
        }
    }
}

// MARK: - Password Validation (for registration - requirement 6.3)

struct PasswordValidator {
    /// Validates password strength according to requirement 6.3
    static func validate(_ password: String) throws {
        // Minimum length
        guard password.count >= 8 else {
            throw ValidationError.weakPassword
        }
        
        // Must contain at least one uppercase letter
        guard password.range(of: "[A-Z]", options: .regularExpression) != nil else {
            throw ValidationError.weakPassword
        }
        
        // Must contain at least one lowercase letter
        guard password.range(of: "[a-z]", options: .regularExpression) != nil else {
            throw ValidationError.weakPassword
        }
        
        // Must contain at least one digit
        guard password.range(of: "[0-9]", options: .regularExpression) != nil else {
            throw ValidationError.weakPassword
        }
    }
}

// MARK: - Profile Photo Validation (requirement 7.4)

struct ProfilePhotoValidator {
    /// Maximum allowed file size in bytes (5 MB)
    static let maxFileSizeBytes: Int = 5 * 1024 * 1024
    
    /// Allowed image formats
    static let allowedFormats: Set<String> = ["jpg", "jpeg", "png", "heic"]
    
    /// Validates profile photo image data according to requirement 7.4
    /// - Parameter imageData: The image data to validate
    /// - Throws: ValidationError if the image is invalid
    static func validate(_ imageData: Data) throws {
        // Validate file size
        guard imageData.count > 0 else {
            throw ValidationError.invalidFormat("profilePhoto")
        }
        
        guard imageData.count <= maxFileSizeBytes else {
            throw ValidationError.imageTooLarge
        }
        
        #if canImport(UIKit)
        // Validate that data can be loaded as an image
        guard let image = UIImage(data: imageData) else {
            throw ValidationError.invalidImageFormat
        }
        
        // Validate image format by checking the data signature
        try validateImageFormat(imageData)
        
        // Validate image dimensions (reasonable size)
        guard image.size.width > 0 && image.size.height > 0 else {
            throw ValidationError.invalidFormat("profilePhoto")
        }
        #else
        // When UIKit is not available, just validate the format
        try validateImageFormat(imageData)
        #endif
    }
    
    /// Validates the image format by checking file signature
    private static func validateImageFormat(_ data: Data) throws {
        guard data.count >= 2 else {
            throw ValidationError.invalidImageFormat
        }
        
        let bytes = [UInt8](data.prefix(12))
        
        // Check for valid image format signatures
        let isJPEG = bytes[0] == 0xFF && bytes[1] == 0xD8
        let isPNG = bytes.count >= 8 && bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47
        let isHEIC = data.count >= 12 && String(data: data.subdata(in: 4..<12), encoding: .ascii)?.contains("ftyp") == true
        
        guard isJPEG || isPNG || isHEIC else {
            throw ValidationError.invalidImageFormat
        }
    }
}
