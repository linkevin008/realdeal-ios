import Foundation
import UIKit
import Combine

/// Service for uploading images with progress tracking and caching
@available(iOS 15.0, *)
class ImageUploadService: ObservableObject {
    
    // MARK: - Properties
    
    private let imageStorage: ImageStorageProtocol
    private let imageCache: ImageCache
    private let compressionSettings: ImageCompression.CompressionSettings
    
    @Published var uploadProgress: [String: Double] = [:]
    @Published var isUploading: Bool = false
    
    private var uploadTasks: [String: Task<URL, Error>] = [:]
    private let uploadQueue = DispatchQueue(label: "com.realdeal.imageupload", qos: .userInitiated)
    
    // MARK: - Initialization
    
    init(
        imageStorage: ImageStorageProtocol,
        imageCache: ImageCache = .shared,
        compressionSettings: ImageCompression.CompressionSettings = .property
    ) {
        self.imageStorage = imageStorage
        self.imageCache = imageCache
        self.compressionSettings = compressionSettings
    }
    
    // MARK: - Single Image Upload
    
    /// Upload a single image with progress tracking
    /// - Parameters:
    ///   - image: The image to upload
    ///   - path: The storage path for the image
    ///   - compress: Whether to compress the image before upload
    /// - Returns: Upload result with URL and metadata
    func uploadImage(
        _ image: UIImage,
        to path: String,
        compress: Bool = true
    ) async throws -> ImageUploadResult {
        
        let uploadId = UUID().uuidString
        
        await MainActor.run {
            uploadProgress[uploadId] = 0.0
            isUploading = true
        }
        
        defer {
            Task { @MainActor in
                uploadProgress.removeValue(forKey: uploadId)
                isUploading = !uploadProgress.isEmpty
            }
        }
        
        do {
            // Step 1: Validate image (10% progress)
            await updateProgress(uploadId: uploadId, progress: 0.1)
            let validation = ImageCompression.validateImage(image)
            guard validation.isValid else {
                throw ImageUploadError.invalidImage(validation.issues.map(\.description))
            }
            
            // Step 2: Compress image if needed (30% progress)
            await updateProgress(uploadId: uploadId, progress: 0.3)
            let imageData: Data
            let compressionResult: CompressionResult?
            
            if compress {
                let result = ImageCompression.compress(image: image, settings: compressionSettings)
                imageData = result.data
                compressionResult = result
            } else {
                imageData = image.jpegData(compressionQuality: 1.0) ?? Data()
                compressionResult = nil
            }
            
            guard !imageData.isEmpty else {
                throw ImageUploadError.compressionFailed
            }
            
            // Step 3: Upload to storage (70% progress)
            await updateProgress(uploadId: uploadId, progress: 0.7)
            let url = try await imageStorage.uploadImage(imageData, path: path)
            
            // Step 4: Cache the image (90% progress)
            await updateProgress(uploadId: uploadId, progress: 0.9)
            await imageCache.store(image: image, for: url)
            
            // Step 5: Complete (100% progress)
            await updateProgress(uploadId: uploadId, progress: 1.0)
            
            return ImageUploadResult(
                url: url,
                originalImage: image,
                uploadedData: imageData,
                compressionResult: compressionResult,
                uploadId: uploadId
            )
            
        } catch {
            await MainActor.run {
                uploadProgress.removeValue(forKey: uploadId)
            }
            throw error
        }
    }
    
    // MARK: - Batch Upload
    
    /// Upload multiple images with combined progress tracking
    /// - Parameters:
    ///   - images: Array of images with their paths
    ///   - compress: Whether to compress images before upload
    /// - Returns: Array of upload results
    func uploadImages(
        _ images: [(image: UIImage, path: String)],
        compress: Bool = true
    ) async throws -> [ImageUploadResult] {
        
        let batchId = UUID().uuidString
        
        await MainActor.run {
            uploadProgress[batchId] = 0.0
            isUploading = true
        }
        
        defer {
            Task { @MainActor in
                uploadProgress.removeValue(forKey: batchId)
                isUploading = !uploadProgress.isEmpty
            }
        }
        
        var results: [ImageUploadResult] = []
        let totalImages = images.count
        
        for (index, imageInfo) in images.enumerated() {
            do {
                let result = try await uploadSingleImageInBatch(
                    imageInfo.image,
                    to: imageInfo.path,
                    compress: compress,
                    batchProgress: Double(index) / Double(totalImages)
                )
                results.append(result)
                
                // Update batch progress
                let progress = Double(index + 1) / Double(totalImages)
                await updateProgress(uploadId: batchId, progress: progress)
                
            } catch {
                // Continue with other images even if one fails
                print("Failed to upload image at path \(imageInfo.path): \(error)")
                continue
            }
        }
        
        return results
    }
    
    // MARK: - Image Deletion
    
    /// Delete image from storage and cache
    /// - Parameter url: URL of the image to delete
    func deleteImage(url: URL) async throws {
        // Remove from storage
        try await imageStorage.deleteImage(url: url)
        
        // Remove from cache
        await imageCache.removeImage(for: url)
    }
    
    /// Delete multiple images from storage and cache
    /// - Parameter urls: URLs of images to delete
    func deleteImages(urls: [URL]) async throws {
        // Remove from storage
        try await imageStorage.deleteImages(urls: urls)
        
        // Remove from cache
        for url in urls {
            await imageCache.removeImage(for: url)
        }
    }
    
    // MARK: - Upload Management
    
    /// Cancel upload by ID
    func cancelUpload(uploadId: String) {
        uploadTasks[uploadId]?.cancel()
        uploadTasks.removeValue(forKey: uploadId)
        
        Task { @MainActor in
            uploadProgress.removeValue(forKey: uploadId)
            isUploading = !uploadProgress.isEmpty
        }
    }
    
    /// Cancel all uploads
    func cancelAllUploads() {
        for task in uploadTasks.values {
            task.cancel()
        }
        uploadTasks.removeAll()
        
        Task { @MainActor in
            uploadProgress.removeAll()
            isUploading = false
        }
    }
    
    // MARK: - Private Methods
    
    private func uploadSingleImageInBatch(
        _ image: UIImage,
        to path: String,
        compress: Bool,
        batchProgress: Double
    ) async throws -> ImageUploadResult {
        
        // Validate image
        let validation = ImageCompression.validateImage(image)
        guard validation.isValid else {
            throw ImageUploadError.invalidImage(validation.issues.map(\.description))
        }
        
        // Compress image if needed
        let imageData: Data
        let compressionResult: CompressionResult?
        
        if compress {
            let result = ImageCompression.compress(image: image, settings: compressionSettings)
            imageData = result.data
            compressionResult = result
        } else {
            imageData = image.jpegData(compressionQuality: 1.0) ?? Data()
            compressionResult = nil
        }
        
        guard !imageData.isEmpty else {
            throw ImageUploadError.compressionFailed
        }
        
        // Upload to storage
        let url = try await imageStorage.uploadImage(imageData, path: path)
        
        // Cache the image
        await imageCache.store(image: image, for: url)
        
        return ImageUploadResult(
            url: url,
            originalImage: image,
            uploadedData: imageData,
            compressionResult: compressionResult,
            uploadId: UUID().uuidString
        )
    }
    
    @MainActor
    private func updateProgress(uploadId: String, progress: Double) {
        uploadProgress[uploadId] = progress
    }
}

// MARK: - Supporting Types

struct ImageUploadResult {
    let url: URL
    let originalImage: UIImage
    let uploadedData: Data
    let compressionResult: CompressionResult?
    let uploadId: String
    
    var uploadedSize: Int {
        uploadedData.count
    }
    
    var formattedUploadedSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(uploadedSize), countStyle: .file)
    }
}

enum ImageUploadError: Error, LocalizedError {
    case invalidImage([String])
    case compressionFailed
    case uploadFailed(Error)
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .invalidImage(let issues):
            return "Invalid image: \(issues.joined(separator: ", "))"
        case .compressionFailed:
            return "Failed to compress image"
        case .uploadFailed(let error):
            return "Upload failed: \(error.localizedDescription)"
        case .cancelled:
            return "Upload was cancelled"
        }
    }
}

// MARK: - Convenience Extensions

extension ImageUploadService {
    
    /// Upload profile photo with appropriate compression
    func uploadProfilePhoto(_ image: UIImage, userId: String) async throws -> ImageUploadResult {
        let path = "profiles/\(userId)/photo.jpg"
        let service = ImageUploadService(
            imageStorage: imageStorage,
            imageCache: imageCache,
            compressionSettings: .profile
        )
        return try await service.uploadImage(image, to: path, compress: true)
    }
    
    /// Upload property images with appropriate compression
    func uploadPropertyImages(_ images: [UIImage], propertyId: String) async throws -> [ImageUploadResult] {
        let imagesWithPaths = images.enumerated().map { index, image in
            (image: image, path: "properties/\(propertyId)/image_\(index).jpg")
        }
        return try await uploadImages(imagesWithPaths, compress: true)
    }
}