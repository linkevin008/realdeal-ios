import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Validator for profile photo uploads
@available(iOS 15.0, macOS 12.0, *)
struct ProfilePhotoValidator {
    
    /// Maximum file size in bytes (5MB)
    static let maxFileSize: Int = 5 * 1024 * 1024
    
    /// Minimum file size in bytes (1KB)
    static let minFileSize: Int = 1024
    
    /// Supported image formats
    static let supportedFormats: Set<String> = ["image/jpeg", "image/png", "image/heic"]
    
    /// Validates profile photo data
    /// - Parameter imageData: The image data to validate
    /// - Throws: ValidationError if the image is invalid
    static func validate(_ imageData: Data) throws {
        // Check file size
        guard imageData.count >= minFileSize else {
            throw ValidationError.fileTooSmall
        }
        
        guard imageData.count <= maxFileSize else {
            throw ValidationError.fileTooLarge
        }
        
        // Check if it's a valid image format
        guard isValidImageFormat(imageData) else {
            throw ValidationError.invalidFormat
        }
        
        #if canImport(UIKit)
        // Try to create UIImage to verify it's actually an image
        guard UIImage(data: imageData) != nil else {
            throw ValidationError.corruptedImage
        }
        #endif
    }
    
    /// Checks if the data represents a valid image format
    private static func isValidImageFormat(_ data: Data) -> Bool {
        guard data.count >= 12 else { return false }
        
        // Check for JPEG magic bytes (FF D8 FF)
        if data[0] == 0xFF && data[1] == 0xD8 && data[2] == 0xFF {
            return true
        }
        
        // Check for PNG magic bytes (89 50 4E 47)
        if data[0] == 0x89 && data[1] == 0x50 && data[2] == 0x4E && data[3] == 0x47 {
            return true
        }
        
        // Check for HEIC/HEIF (more complex, simplified check)
        // HEIC files start with various patterns, checking for "ftyp" at offset 4
        if data.count >= 12 {
            let ftypRange = 4..<8
            if let ftypString = String(data: data[ftypRange], encoding: .ascii),
               ftypString == "ftyp" {
                return true
            }
        }
        
        return false
    }
    
    enum ValidationError: Error, LocalizedError {
        case fileTooSmall
        case fileTooLarge
        case invalidFormat
        case corruptedImage
        
        var errorDescription: String? {
            switch self {
            case .fileTooSmall:
                return "Image file is too small. Minimum size is 1KB."
            case .fileTooLarge:
                return "Image file is too large. Maximum size is 5MB."
            case .invalidFormat:
                return "Invalid image format. Supported formats: JPEG, PNG, HEIC."
            case .corruptedImage:
                return "Image file is corrupted or cannot be read."
            }
        }
    }
}
