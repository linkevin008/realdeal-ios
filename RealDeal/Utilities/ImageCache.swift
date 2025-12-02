import Foundation
import UIKit

/// A comprehensive image caching system with memory and disk storage
@available(iOS 15.0, *)
class ImageCache {
    
    // MARK: - Singleton
    static let shared = ImageCache()
    
    // MARK: - Properties
    private let memoryCache = NSCache<NSString, UIImage>()
    private let diskCacheURL: URL
    private let fileManager = FileManager.default
    private let cacheQueue = DispatchQueue(label: "com.realdeal.imagecache", qos: .utility)
    
    // MARK: - Configuration
    private let maxMemoryCacheSize: Int = 50 * 1024 * 1024 // 50MB
    private let maxDiskCacheSize: Int = 200 * 1024 * 1024 // 200MB
    private let maxCacheAge: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    
    // MARK: - Initialization
    
    private init() {
        // Setup memory cache
        memoryCache.totalCostLimit = maxMemoryCacheSize
        memoryCache.countLimit = 100
        
        // Setup disk cache directory
        let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        diskCacheURL = cacheDirectory.appendingPathComponent("ImageCache")
        
        // Create cache directory if needed
        try? fileManager.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
        
        // Setup cleanup on memory warnings
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearMemoryCache),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        
        // Setup background cleanup
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(cleanupExpiredImages),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Methods
    
    /// Retrieve image from cache (memory first, then disk)
    func image(for url: URL) async -> UIImage? {
        let key = cacheKey(for: url)
        
        // Check memory cache first
        if let cachedImage = memoryCache.object(forKey: key) {
            return cachedImage
        }
        
        // Check disk cache
        return await withCheckedContinuation { continuation in
            cacheQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let diskImage = self.loadImageFromDisk(key: key)
                
                // If found on disk, add to memory cache
                if let image = diskImage {
                    self.memoryCache.setObject(image, forKey: key, cost: self.imageCost(image))
                }
                
                continuation.resume(returning: diskImage)
            }
        }
    }
    
    /// Store image in both memory and disk cache
    func store(image: UIImage, for url: URL) async {
        let key = cacheKey(for: url)
        let cost = imageCost(image)
        
        // Store in memory cache
        memoryCache.setObject(image, forKey: key, cost: cost)
        
        // Store in disk cache
        await withCheckedContinuation { continuation in
            cacheQueue.async { [weak self] in
                self?.saveImageToDisk(image: image, key: key)
                continuation.resume()
            }
        }
    }
    
    /// Remove image from both caches
    func removeImage(for url: URL) async {
        let key = cacheKey(for: url)
        
        // Remove from memory cache
        memoryCache.removeObject(forKey: key)
        
        // Remove from disk cache
        await withCheckedContinuation { continuation in
            cacheQueue.async { [weak self] in
                self?.removeImageFromDisk(key: key)
                continuation.resume()
            }
        }
    }
    
    /// Clear all cached images
    func clearAll() async {
        // Clear memory cache
        memoryCache.removeAllObjects()
        
        // Clear disk cache
        await withCheckedContinuation { continuation in
            cacheQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                try? self.fileManager.removeItem(at: self.diskCacheURL)
                try? self.fileManager.createDirectory(at: self.diskCacheURL, withIntermediateDirectories: true)
                
                continuation.resume()
            }
        }
    }
    
    /// Get current cache size information
    func getCacheInfo() async -> CacheInfo {
        return await withCheckedContinuation { continuation in
            cacheQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: CacheInfo(memorySize: 0, diskSize: 0, itemCount: 0))
                    return
                }
                
                let diskSize = self.calculateDiskCacheSize()
                let itemCount = self.getDiskCacheItemCount()
                
                let info = CacheInfo(
                    memorySize: 0, // NSCache doesn't provide current size
                    diskSize: diskSize,
                    itemCount: itemCount
                )
                
                continuation.resume(returning: info)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func cacheKey(for url: URL) -> NSString {
        return url.absoluteString.sha256 as NSString
    }
    
    private func imageCost(_ image: UIImage) -> Int {
        return Int(image.size.width * image.size.height * 4) // Assuming 4 bytes per pixel
    }
    
    private func diskCacheURL(for key: NSString) -> URL {
        return diskCacheURL.appendingPathComponent(key as String)
    }
    
    private func loadImageFromDisk(key: NSString) -> UIImage? {
        let url = diskCacheURL(for: key)
        
        guard fileManager.fileExists(atPath: url.path) else {
            return nil
        }
        
        // Check if file is expired
        if let attributes = try? fileManager.attributesOfItem(atPath: url.path),
           let modificationDate = attributes[.modificationDate] as? Date,
           Date().timeIntervalSince(modificationDate) > maxCacheAge {
            // File is expired, remove it
            try? fileManager.removeItem(at: url)
            return nil
        }
        
        guard let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else {
            return nil
        }
        
        return image
    }
    
    private func saveImageToDisk(image: UIImage, key: NSString) {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            return
        }
        
        let url = diskCacheURL(for: key)
        
        do {
            try data.write(to: url)
        } catch {
            print("Failed to save image to disk: \(error)")
        }
        
        // Cleanup if cache is too large
        cleanupDiskCacheIfNeeded()
    }
    
    private func removeImageFromDisk(key: NSString) {
        let url = diskCacheURL(for: key)
        try? fileManager.removeItem(at: url)
    }
    
    private func calculateDiskCacheSize() -> Int {
        guard let enumerator = fileManager.enumerator(at: diskCacheURL, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        
        var totalSize = 0
        
        for case let fileURL as URL in enumerator {
            if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
               let fileSize = resourceValues.fileSize {
                totalSize += fileSize
            }
        }
        
        return totalSize
    }
    
    private func getDiskCacheItemCount() -> Int {
        guard let contents = try? fileManager.contentsOfDirectory(at: diskCacheURL, includingPropertiesForKeys: nil) else {
            return 0
        }
        return contents.count
    }
    
    private func cleanupDiskCacheIfNeeded() {
        let currentSize = calculateDiskCacheSize()
        
        guard currentSize > maxDiskCacheSize else {
            return
        }
        
        // Get all files with their modification dates
        guard let enumerator = fileManager.enumerator(
            at: diskCacheURL,
            includingPropertiesForKeys: [.contentModificationDateKey]
        ) else {
            return
        }
        
        var files: [(url: URL, date: Date)] = []
        
        for case let fileURL as URL in enumerator {
            if let resourceValues = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]),
               let modificationDate = resourceValues.contentModificationDate {
                files.append((url: fileURL, date: modificationDate))
            }
        }
        
        // Sort by modification date (oldest first)
        files.sort { $0.date < $1.date }
        
        // Remove oldest files until we're under the limit
        var sizeToRemove = currentSize - maxDiskCacheSize
        
        for file in files {
            guard sizeToRemove > 0 else { break }
            
            if let attributes = try? fileManager.attributesOfItem(atPath: file.url.path),
               let fileSize = attributes[.size] as? Int {
                try? fileManager.removeItem(at: file.url)
                sizeToRemove -= fileSize
            }
        }
    }
    
    @objc private func clearMemoryCache() {
        memoryCache.removeAllObjects()
    }
    
    @objc private func cleanupExpiredImages() {
        cacheQueue.async { [weak self] in
            self?.performExpiredImageCleanup()
        }
    }
    
    private func performExpiredImageCleanup() {
        guard let enumerator = fileManager.enumerator(
            at: diskCacheURL,
            includingPropertiesForKeys: [.contentModificationDateKey]
        ) else {
            return
        }
        
        let now = Date()
        
        for case let fileURL as URL in enumerator {
            if let resourceValues = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]),
               let modificationDate = resourceValues.contentModificationDate,
               now.timeIntervalSince(modificationDate) > maxCacheAge {
                try? fileManager.removeItem(at: fileURL)
            }
        }
    }
}

// MARK: - Supporting Types

struct CacheInfo {
    let memorySize: Int
    let diskSize: Int
    let itemCount: Int
    
    var formattedDiskSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(diskSize), countStyle: .file)
    }
}

// MARK: - String Extension for SHA256

extension String {
    var sha256: String {
        let data = Data(self.utf8)
        let hash = data.withUnsafeBytes { bytes in
            var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
            CC_SHA256(bytes.bindMemory(to: UInt8.self).baseAddress, CC_LONG(data.count), &hash)
            return hash
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

import CommonCrypto