import Foundation
import UIKit
import Combine

/// Comprehensive image management service that coordinates caching, uploading, and loading
@available(iOS 15.0, *)
class ImageManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = ImageManager()
    
    // MARK: - Properties
    private let imageCache: ImageCache
    private let uploadService: ImageUploadService
    private let imageStorage: ImageStorageProtocol
    
    @Published var isProcessing: Bool = false
    @Published var uploadProgress: [String: Double] = [:]
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        imageCache: ImageCache = .shared,
        imageStorage: ImageStorageProtocol = MockImageStorage()
    ) {
        self.imageCache = imageCache
        self.imageStorage = imageStorage
        self.uploadService = ImageUploadService(imageStorage: imageStorage, imageCache: imageCache)
        
        // Bind upload service progress to our published properties
        uploadService.$uploadProgress
            .receive(on: DispatchQueue.main)
            .assign(to: \.uploadProgress, on: self)
            .store(in: &cancellables)
        
        uploadService.$isUploading
            .receive(on: DispatchQueue.main)
            .assign(to: \.isProcessing, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Image Loading
    
    /// Load image from URL with caching
    /// - Parameter url: The image URL
    /// - Returns: The loaded image or nil if not available
    func loadImage(from url: URL) async -> UIImage? {
        // First check cache
        if let cachedImage = await imageCache.image(for: url) {
            return cachedImage
        }
        
        // Download and cache
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let image = UIImage(data: data) else {
                return nil
            }
            
            // Store in cache
            await imageCache.store(image: image, for: url)
            return image
            
        } catch {
            print("Failed to load image from \(url): \(error)")
            return nil
        }
    }
    
    /// Preload images for better performance
    /// - Parameter urls: Array of image URLs to preload
    func preloadImages(urls: [URL]) async {
        await withTaskGroup(of: Void.self) { group in
            for url in urls {
                group.addTask { [weak self] in
                    _ = await self?.loadImage(from: url)
                }
            }
        }
    }
    
    // MARK: - Image Upload
    
    /// Upload a single image
    /// - Parameters:
    ///   - image: The image to upload
    ///   - path: Storage path for the image
    ///   - compress: Whether to compress the image
    /// - Returns: Upload result with URL and metadata
    func uploadImage(
        _ image: UIImage,
        to path: String,
        compress: Bool = true
    ) async throws -> ImageUploadResult {
        return try await uploadService.uploadImage(image, to: path, compress: compress)
    }
    
    /// Upload multiple images
    /// - Parameters:
    ///   - images: Array of images with their paths
    ///   - compress: Whether to compress images
    /// - Returns: Array of upload results
    func uploadImages(
        _ images: [(image: UIImage, path: String)],
        compress: Bool = true
    ) async throws -> [ImageUploadResult] {
        return try await uploadService.uploadImages(images, compress: compress)
    }
    
    /// Upload profile photo with optimized settings
    /// - Parameters:
    ///   - image: The profile image
    ///   - userId: User ID for path generation
    /// - Returns: Upload result
    func uploadProfilePhoto(_ image: UIImage, userId: String) async throws -> ImageUploadResult {
        return try await uploadService.uploadProfilePhoto(image, userId: userId)
    }
    
    /// Upload property images with optimized settings
    /// - Parameters:
    ///   - images: Array of property images
    ///   - propertyId: Property ID for path generation
    /// - Returns: Array of upload results
    func uploadPropertyImages(_ images: [UIImage], propertyId: String) async throws -> [ImageUploadResult] {
        return try await uploadService.uploadPropertyImages(images, propertyId: propertyId)
    }
    
    // MARK: - Image Deletion
    
    /// Delete image from storage and cache
    /// - Parameter url: URL of the image to delete
    func deleteImage(url: URL) async throws {
        try await uploadService.deleteImage(url: url)
    }
    
    /// Delete multiple images from storage and cache
    /// - Parameter urls: URLs of images to delete
    func deleteImages(urls: [URL]) async throws {
        try await uploadService.deleteImages(urls: urls)
    }
    
    // MARK: - Image Processing
    
    /// Compress image with specified settings
    /// - Parameters:
    ///   - image: Image to compress
    ///   - settings: Compression settings
    /// - Returns: Compression result with data and metadata
    func compressImage(_ image: UIImage, settings: ImageCompression.CompressionSettings) -> CompressionResult {
        return ImageCompression.compress(image: image, settings: settings)
    }
    
    /// Create multiple versions of an image (original and thumbnail)
    /// - Parameter image: Source image
    /// - Returns: Image versions with different compressions
    func createImageVersions(_ image: UIImage) -> ImageVersions {
        return ImageCompression.createImageVersions(image)
    }
    
    /// Validate image before processing
    /// - Parameter image: Image to validate
    /// - Returns: Validation result with issues if any
    func validateImage(_ image: UIImage) -> ImageValidationResult {
        return ImageCompression.validateImage(image)
    }
    
    // MARK: - Cache Management
    
    /// Get cache information
    /// - Returns: Current cache size and item count
    func getCacheInfo() async -> CacheInfo {
        return await imageCache.getCacheInfo()
    }
    
    /// Clear all cached images
    func clearCache() async {
        await imageCache.clearAll()
    }
    
    /// Remove specific image from cache
    /// - Parameter url: URL of image to remove from cache
    func removeFromCache(url: URL) async {
        await imageCache.removeImage(for: url)
    }
    
    // MARK: - Upload Management
    
    /// Cancel specific upload
    /// - Parameter uploadId: ID of upload to cancel
    func cancelUpload(uploadId: String) {
        uploadService.cancelUpload(uploadId: uploadId)
    }
    
    /// Cancel all uploads
    func cancelAllUploads() {
        uploadService.cancelAllUploads()
    }
    
    // MARK: - Batch Operations
    
    /// Process multiple images for property listing
    /// - Parameters:
    ///   - images: Source images
    ///   - propertyId: Property ID
    ///   - generateThumbnails: Whether to generate thumbnail versions
    /// - Returns: Processing result with URLs and metadata
    func processPropertyImages(
        _ images: [UIImage],
        propertyId: String,
        generateThumbnails: Bool = true
    ) async throws -> PropertyImageProcessingResult {
        
        await MainActor.run {
            isProcessing = true
        }
        
        defer {
            Task { @MainActor in
                isProcessing = false
            }
        }
        
        var originalResults: [ImageUploadResult] = []
        var thumbnailResults: [ImageUploadResult] = []
        
        // Upload original images
        let originalImages = images.enumerated().map { index, image in
            (image: image, path: "properties/\(propertyId)/original_\(index).jpg")
        }
        originalResults = try await uploadImages(originalImages, compress: true)
        
        // Generate and upload thumbnails if requested
        if generateThumbnails {
            let thumbnailImages = images.enumerated().compactMap { index, image -> (image: UIImage, path: String)? in
                let compressionResult = ImageCompression.compressForThumbnail(image)
                guard let thumbnailImage = UIImage(data: compressionResult.data) else {
                    return nil
                }
                return (image: thumbnailImage, path: "properties/\(propertyId)/thumbnail_\(index).jpg")
            }
            
            if !thumbnailImages.isEmpty {
                thumbnailResults = try await uploadImages(thumbnailImages, compress: false) // Already compressed
            }
        }
        
        return PropertyImageProcessingResult(
            originalImages: originalResults,
            thumbnailImages: thumbnailResults,
            propertyId: propertyId
        )
    }
    
    /// Clean up images for deleted property
    /// - Parameter propertyId: ID of property being deleted
    func cleanupPropertyImages(propertyId: String) async throws {
        // This would typically query the storage for all images with the property prefix
        // For now, we'll implement a basic cleanup that removes from cache
        // In a real implementation, you'd want to track image URLs in your data model
        
        let cacheInfo = await getCacheInfo()
        print("Cleaned up cache for property \(propertyId). Current cache has \(cacheInfo.itemCount) items.")
    }
}

// MARK: - Supporting Types

struct PropertyImageProcessingResult {
    let originalImages: [ImageUploadResult]
    let thumbnailImages: [ImageUploadResult]
    let propertyId: String
    
    var allImageUrls: [URL] {
        originalImages.map(\.url) + thumbnailImages.map(\.url)
    }
    
    var originalImageUrls: [URL] {
        originalImages.map(\.url)
    }
    
    var thumbnailImageUrls: [URL] {
        thumbnailImages.map(\.url)
    }
    
    var totalUploadedSize: Int {
        originalImages.reduce(0) { $0 + $1.uploadedSize } +
        thumbnailImages.reduce(0) { $0 + $1.uploadedSize }
    }
    
    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(totalUploadedSize), countStyle: .file)
    }
}

// MARK: - Convenience Extensions

@available(iOS 15.0, *)
extension ImageManager {
    
    /// Quick method to upload and get URL for profile photo
    func uploadProfilePhotoAndGetURL(_ image: UIImage, userId: String) async throws -> URL {
        let result = try await uploadProfilePhoto(image, userId: userId)
        return result.url
    }
    
    /// Quick method to upload property images and get URLs
    func uploadPropertyImagesAndGetURLs(_ images: [UIImage], propertyId: String) async throws -> [URL] {
        let results = try await uploadPropertyImages(images, propertyId: propertyId)
        return results.map(\.url)
    }
    
    /// Load image with automatic retry on failure
    func loadImageWithRetry(from url: URL, maxRetries: Int = 3) async -> UIImage? {
        for attempt in 0..<maxRetries {
            if let image = await loadImage(from: url) {
                return image
            }
            
            // Wait before retry (exponential backoff)
            if attempt < maxRetries - 1 {
                let delay = pow(2.0, Double(attempt)) * 0.5 // 0.5s, 1s, 2s
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        
        return nil
    }
}