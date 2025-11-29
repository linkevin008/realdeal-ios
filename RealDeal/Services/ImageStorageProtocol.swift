import Foundation

/// Protocol for image storage operations
/// Supports uploading, deleting, and managing property and profile photos
protocol ImageStorageProtocol {
    /// Upload an image to storage
    /// - Parameters:
    ///   - imageData: The image data to upload
    ///   - path: The storage path (e.g., "properties/123/image1.jpg")
    /// - Returns: The URL where the image is accessible
    func uploadImage(_ imageData: Data, path: String) async throws -> URL
    
    /// Delete an image from storage
    /// - Parameter url: The URL of the image to delete
    func deleteImage(url: URL) async throws
    
    /// Upload multiple images in batch
    /// - Parameters:
    ///   - images: Array of tuples containing image data and their paths
    /// - Returns: Array of URLs where the images are accessible
    func uploadImages(_ images: [(data: Data, path: String)]) async throws -> [URL]
    
    /// Delete multiple images in batch
    /// - Parameter urls: Array of image URLs to delete
    func deleteImages(urls: [URL]) async throws
}
