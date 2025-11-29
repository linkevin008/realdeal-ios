import Foundation

/// Mock implementation of ImageStorageProtocol for testing and development
@available(iOS 15.0, macOS 12.0, *)
class MockImageStorage: ImageStorageProtocol {
    // MARK: - Storage
    private var images: [URL: Data] = [:]
    
    // MARK: - Configuration
    private let simulateNetworkDelay: Bool
    private let networkDelayRange: ClosedRange<TimeInterval>
    private let baseURL: String
    
    init(
        simulateNetworkDelay: Bool = true,
        networkDelayRange: ClosedRange<TimeInterval> = 0.1...0.5,
        baseURL: String = "https://mock-storage.example.com"
    ) {
        self.simulateNetworkDelay = simulateNetworkDelay
        self.networkDelayRange = networkDelayRange
        self.baseURL = baseURL
    }
    
    // MARK: - Private Helpers
    
    private func simulateDelay() async {
        guard simulateNetworkDelay else { return }
        let delay = TimeInterval.random(in: networkDelayRange)
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
    }
    
    private func generateURL(for path: String) -> URL {
        let sanitizedPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        return URL(string: "\(baseURL)/\(sanitizedPath)")!
    }
    
    // MARK: - ImageStorageProtocol
    
    func uploadImage(_ imageData: Data, path: String) async throws -> URL {
        await simulateDelay()
        
        // Validate image data
        guard !imageData.isEmpty else {
            throw MockImageStorageError.invalidImageData
        }
        
        // Generate URL
        let url = generateURL(for: path)
        
        // Store image
        images[url] = imageData
        
        return url
    }
    
    func deleteImage(url: URL) async throws {
        await simulateDelay()
        
        guard images[url] != nil else {
            throw MockImageStorageError.imageNotFound
        }
        
        images.removeValue(forKey: url)
    }
    
    func uploadImages(_ images: [(data: Data, path: String)]) async throws -> [URL] {
        await simulateDelay()
        
        var urls: [URL] = []
        
        for (data, path) in images {
            // Validate image data
            guard !data.isEmpty else {
                throw MockImageStorageError.invalidImageData
            }
            
            // Generate URL
            let url = generateURL(for: path)
            
            // Store image
            self.images[url] = data
            urls.append(url)
        }
        
        return urls
    }
    
    func deleteImages(urls: [URL]) async throws {
        await simulateDelay()
        
        for url in urls {
            guard images[url] != nil else {
                throw MockImageStorageError.imageNotFound
            }
            
            images.removeValue(forKey: url)
        }
    }
    
    // MARK: - Test Helpers
    
    /// Get stored image data (for testing)
    func getImageData(url: URL) -> Data? {
        images[url]
    }
    
    /// Get all stored image URLs (for testing)
    func getAllImageURLs() -> [URL] {
        Array(images.keys)
    }
    
    /// Clear all stored images
    func clearAll() {
        images.removeAll()
    }
    
    /// Get count of stored images (for testing)
    func getImageCount() -> Int {
        images.count
    }
}

// MARK: - Errors

enum MockImageStorageError: Error, LocalizedError {
    case invalidImageData
    case imageNotFound
    case uploadFailed
    case deleteFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "Invalid or empty image data"
        case .imageNotFound:
            return "Image not found in storage"
        case .uploadFailed:
            return "Failed to upload image"
        case .deleteFailed:
            return "Failed to delete image"
        }
    }
}
