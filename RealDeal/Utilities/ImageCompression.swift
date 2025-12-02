import Foundation
import UIKit

/// Utility for compressing images for upload and storage
struct ImageCompression {
    
    // MARK: - Configuration
    
    struct CompressionSettings {
        let maxFileSize: Int // in bytes
        let maxDimension: CGFloat // max width or height
        let jpegQuality: CGFloat // 0.0 to 1.0
        
        static let profile = CompressionSettings(
            maxFileSize: 2 * 1024 * 1024, // 2MB
            maxDimension: 1024,
            jpegQuality: 0.8
        )
        
        static let property = CompressionSettings(
            maxFileSize: 5 * 1024 * 1024, // 5MB
            maxDimension: 2048,
            jpegQuality: 0.85
        )
        
        static let thumbnail = CompressionSettings(
            maxFileSize: 500 * 1024, // 500KB
            maxDimension: 300,
            jpegQuality: 0.7
        )
    }
    
    // MARK: - Compression Methods
    
    /// Compress image according to the specified settings
    /// - Parameters:
    ///   - image: The original image to compress
    ///   - settings: Compression settings to apply
    /// - Returns: Compressed image data and metadata
    static func compress(image: UIImage, settings: CompressionSettings) -> CompressionResult {
        let startTime = Date()
        let originalSize = image.jpegData(compressionQuality: 1.0)?.count ?? 0
        
        // Step 1: Resize if needed
        let resizedImage = resizeImage(image, maxDimension: settings.maxDimension)
        
        // Step 2: Compress with initial quality
        var quality = settings.jpegQuality
        var compressedData = resizedImage.jpegData(compressionQuality: quality)
        
        // Step 3: Iteratively reduce quality if still too large
        while let data = compressedData,
              data.count > settings.maxFileSize && quality > 0.1 {
            quality -= 0.1
            compressedData = resizedImage.jpegData(compressionQuality: quality)
        }
        
        let processingTime = Date().timeIntervalSince(startTime)
        
        return CompressionResult(
            data: compressedData ?? Data(),
            originalSize: originalSize,
            compressedSize: compressedData?.count ?? 0,
            finalQuality: quality,
            processingTime: processingTime,
            finalDimensions: resizedImage.size
        )
    }
    
    /// Compress image for profile photo use
    static func compressForProfile(_ image: UIImage) -> CompressionResult {
        return compress(image: image, settings: .profile)
    }
    
    /// Compress image for property listing use
    static func compressForProperty(_ image: UIImage) -> CompressionResult {
        return compress(image: image, settings: .property)
    }
    
    /// Compress image for thumbnail use
    static func compressForThumbnail(_ image: UIImage) -> CompressionResult {
        return compress(image: image, settings: .thumbnail)
    }
    
    /// Create multiple versions of an image (original, compressed, thumbnail)
    static func createImageVersions(_ image: UIImage) -> ImageVersions {
        let original = compress(image: image, settings: .property)
        let thumbnail = compress(image: image, settings: .thumbnail)
        
        return ImageVersions(
            original: original,
            thumbnail: thumbnail
        )
    }
    
    // MARK: - Helper Methods
    
    private static func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        
        // Check if resizing is needed
        guard size.width > maxDimension || size.height > maxDimension else {
            return image
        }
        
        // Calculate new size maintaining aspect ratio
        let aspectRatio = size.width / size.height
        let newSize: CGSize
        
        if size.width > size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
        
        // Create resized image
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    /// Calculate compression ratio
    static func compressionRatio(original: Int, compressed: Int) -> Double {
        guard original > 0 else { return 0 }
        return Double(compressed) / Double(original)
    }
    
    /// Format file size for display
    static func formatFileSize(_ bytes: Int) -> String {
        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }
}

// MARK: - Supporting Types

struct CompressionResult {
    let data: Data
    let originalSize: Int
    let compressedSize: Int
    let finalQuality: CGFloat
    let processingTime: TimeInterval
    let finalDimensions: CGSize
    
    var compressionRatio: Double {
        ImageCompression.compressionRatio(original: originalSize, compressed: compressedSize)
    }
    
    var spaceSaved: Int {
        originalSize - compressedSize
    }
    
    var formattedOriginalSize: String {
        ImageCompression.formatFileSize(originalSize)
    }
    
    var formattedCompressedSize: String {
        ImageCompression.formatFileSize(compressedSize)
    }
    
    var formattedSpaceSaved: String {
        ImageCompression.formatFileSize(spaceSaved)
    }
}

struct ImageVersions {
    let original: CompressionResult
    let thumbnail: CompressionResult
}

// MARK: - Validation

extension ImageCompression {
    
    /// Validate image before compression
    static func validateImage(_ image: UIImage) -> ImageValidationResult {
        var issues: [ImageValidationIssue] = []
        
        // Check dimensions
        let size = image.size
        if size.width < 100 || size.height < 100 {
            issues.append(.tooSmall)
        }
        
        if size.width > 10000 || size.height > 10000 {
            issues.append(.tooLarge)
        }
        
        // Check aspect ratio (should be reasonable)
        let aspectRatio = size.width / size.height
        if aspectRatio > 5 || aspectRatio < 0.2 {
            issues.append(.extremeAspectRatio)
        }
        
        // Check if image data exists
        if image.jpegData(compressionQuality: 1.0) == nil {
            issues.append(.invalidImageData)
        }
        
        return ImageValidationResult(
            isValid: issues.isEmpty,
            issues: issues,
            dimensions: size
        )
    }
}

struct ImageValidationResult {
    let isValid: Bool
    let issues: [ImageValidationIssue]
    let dimensions: CGSize
}

enum ImageValidationIssue {
    case tooSmall
    case tooLarge
    case extremeAspectRatio
    case invalidImageData
    
    var description: String {
        switch self {
        case .tooSmall:
            return "Image is too small (minimum 100x100 pixels)"
        case .tooLarge:
            return "Image is too large (maximum 10000x10000 pixels)"
        case .extremeAspectRatio:
            return "Image has extreme aspect ratio"
        case .invalidImageData:
            return "Invalid image data"
        }
    }
}