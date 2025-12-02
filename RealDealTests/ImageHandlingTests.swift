import XCTest
import UIKit
@testable import RealDeal

@available(iOS 15.0, *)
final class ImageHandlingTests: XCTestCase {
    
    var imageCache: ImageCache!
    var mockImageStorage: MockImageStorage!
    var imageUploadService: ImageUploadService!
    var imageManager: ImageManager!
    
    override func setUp() async throws {
        try await super.setUp()
        
        imageCache = ImageCache.shared
        mockImageStorage = MockImageStorage(simulateNetworkDelay: false)
        imageUploadService = ImageUploadService(
            imageStorage: mockImageStorage,
            imageCache: imageCache,
            compressionSettings: .property
        )
        imageManager = ImageManager(imageCache: imageCache, imageStorage: mockImageStorage)
        
        // Clear cache before each test
        await imageCache.clearAll()
        mockImageStorage.clearAll()
    }
    
    override func tearDown() async throws {
        await imageCache.clearAll()
        mockImageStorage.clearAll()
        try await super.tearDown()
    }
    
    // MARK: - Image Cache Tests
    
    func testImageCacheStoreAndRetrieve() async throws {
        // Create test image
        let testImage = createTestImage(size: CGSize(width: 100, height: 100), color: .red)
        let testURL = URL(string: "https://example.com/test.jpg")!
        
        // Store image in cache
        await imageCache.store(image: testImage, for: testURL)
        
        // Retrieve image from cache
        let cachedImage = await imageCache.image(for: testURL)
        
        XCTAssertNotNil(cachedImage)
        XCTAssertEqual(cachedImage?.size, testImage.size)
    }
    
    func testImageCacheRemoval() async throws {
        // Create and store test image
        let testImage = createTestImage(size: CGSize(width: 100, height: 100), color: .blue)
        let testURL = URL(string: "https://example.com/test2.jpg")!
        
        await imageCache.store(image: testImage, for: testURL)
        
        // Verify it's cached
        let cachedImage = await imageCache.image(for: testURL)
        XCTAssertNotNil(cachedImage)
        
        // Remove from cache
        await imageCache.removeImage(for: testURL)
        
        // Verify it's removed
        let removedImage = await imageCache.image(for: testURL)
        XCTAssertNil(removedImage)
    }
    
    func testImageCacheClearAll() async throws {
        // Store multiple images
        let image1 = createTestImage(size: CGSize(width: 50, height: 50), color: .red)
        let image2 = createTestImage(size: CGSize(width: 60, height: 60), color: .green)
        
        let url1 = URL(string: "https://example.com/image1.jpg")!
        let url2 = URL(string: "https://example.com/image2.jpg")!
        
        await imageCache.store(image: image1, for: url1)
        await imageCache.store(image: image2, for: url2)
        
        // Verify both are cached
        XCTAssertNotNil(await imageCache.image(for: url1))
        XCTAssertNotNil(await imageCache.image(for: url2))
        
        // Clear all
        await imageCache.clearAll()
        
        // Verify both are removed
        XCTAssertNil(await imageCache.image(for: url1))
        XCTAssertNil(await imageCache.image(for: url2))
    }
    
    // MARK: - Image Compression Tests
    
    func testImageCompressionBasic() throws {
        let testImage = createTestImage(size: CGSize(width: 1000, height: 1000), color: .blue)
        let settings = ImageCompression.CompressionSettings.property
        
        let result = ImageCompression.compress(image: testImage, settings: settings)
        
        XCTAssertFalse(result.data.isEmpty)
        XCTAssertGreaterThan(result.originalSize, result.compressedSize)
        XCTAssertLessThanOrEqual(result.compressedSize, settings.maxFileSize)
        XCTAssertLessThanOrEqual(result.finalDimensions.width, settings.maxDimension)
        XCTAssertLessThanOrEqual(result.finalDimensions.height, settings.maxDimension)
    }
    
    func testImageCompressionForProfile() throws {
        let testImage = createTestImage(size: CGSize(width: 2000, height: 2000), color: .green)
        
        let result = ImageCompression.compressForProfile(testImage)
        
        XCTAssertFalse(result.data.isEmpty)
        XCTAssertLessThanOrEqual(result.compressedSize, ImageCompression.CompressionSettings.profile.maxFileSize)
        XCTAssertLessThanOrEqual(result.finalDimensions.width, ImageCompression.CompressionSettings.profile.maxDimension)
    }
    
    func testImageCompressionForThumbnail() throws {
        let testImage = createTestImage(size: CGSize(width: 1500, height: 1500), color: .orange)
        
        let result = ImageCompression.compressForThumbnail(testImage)
        
        XCTAssertFalse(result.data.isEmpty)
        XCTAssertLessThanOrEqual(result.compressedSize, ImageCompression.CompressionSettings.thumbnail.maxFileSize)
        XCTAssertLessThanOrEqual(result.finalDimensions.width, ImageCompression.CompressionSettings.thumbnail.maxDimension)
    }
    
    func testImageValidation() throws {
        // Valid image
        let validImage = createTestImage(size: CGSize(width: 500, height: 500), color: .purple)
        let validResult = ImageCompression.validateImage(validImage)
        XCTAssertTrue(validResult.isValid)
        XCTAssertTrue(validResult.issues.isEmpty)
        
        // Too small image
        let smallImage = createTestImage(size: CGSize(width: 50, height: 50), color: .yellow)
        let smallResult = ImageCompression.validateImage(smallImage)
        XCTAssertFalse(smallResult.isValid)
        XCTAssertTrue(smallResult.issues.contains(.tooSmall))
    }
    
    // MARK: - Image Upload Tests
    
    func testSingleImageUpload() async throws {
        let testImage = createTestImage(size: CGSize(width: 200, height: 200), color: .cyan)
        let testPath = "test/image.jpg"
        
        let result = try await imageUploadService.uploadImage(testImage, to: testPath, compress: true)
        
        XCTAssertFalse(result.uploadedData.isEmpty)
        XCTAssertEqual(result.url.lastPathComponent, "image.jpg")
        
        // Verify image was stored in mock storage
        let storedData = mockImageStorage.getImageData(url: result.url)
        XCTAssertNotNil(storedData)
        XCTAssertEqual(storedData, result.uploadedData)
    }
    
    func testBatchImageUpload() async throws {
        let image1 = createTestImage(size: CGSize(width: 150, height: 150), color: .red)
        let image2 = createTestImage(size: CGSize(width: 160, height: 160), color: .blue)
        
        let images = [
            (image: image1, path: "batch/image1.jpg"),
            (image: image2, path: "batch/image2.jpg")
        ]
        
        let results = try await imageUploadService.uploadImages(images, compress: true)
        
        XCTAssertEqual(results.count, 2)
        
        for result in results {
            XCTAssertFalse(result.uploadedData.isEmpty)
            let storedData = mockImageStorage.getImageData(url: result.url)
            XCTAssertNotNil(storedData)
        }
    }
    
    func testProfilePhotoUpload() async throws {
        let profileImage = createTestImage(size: CGSize(width: 800, height: 800), color: .magenta)
        let userId = "user123"
        
        let result = try await imageUploadService.uploadProfilePhoto(profileImage, userId: userId)
        
        XCTAssertTrue(result.url.absoluteString.contains("profiles/\(userId)"))
        XCTAssertFalse(result.uploadedData.isEmpty)
        
        // Verify compression was applied (profile settings)
        XCTAssertLessThanOrEqual(result.uploadedData.count, ImageCompression.CompressionSettings.profile.maxFileSize)
    }
    
    func testPropertyImagesUpload() async throws {
        let image1 = createTestImage(size: CGSize(width: 1200, height: 800), color: .brown)
        let image2 = createTestImage(size: CGSize(width: 1000, height: 1000), color: .gray)
        let propertyId = "property456"
        
        let results = try await imageUploadService.uploadPropertyImages([image1, image2], propertyId: propertyId)
        
        XCTAssertEqual(results.count, 2)
        
        for result in results {
            XCTAssertTrue(result.url.absoluteString.contains("properties/\(propertyId)"))
            XCTAssertFalse(result.uploadedData.isEmpty)
        }
    }
    
    // MARK: - Image Deletion Tests
    
    func testImageDeletion() async throws {
        // Upload an image first
        let testImage = createTestImage(size: CGSize(width: 100, height: 100), color: .black)
        let result = try await imageUploadService.uploadImage(testImage, to: "delete/test.jpg", compress: false)
        
        // Verify it exists
        XCTAssertNotNil(mockImageStorage.getImageData(url: result.url))
        
        // Delete the image
        try await imageUploadService.deleteImage(url: result.url)
        
        // Verify it's deleted
        XCTAssertNil(mockImageStorage.getImageData(url: result.url))
    }
    
    func testBatchImageDeletion() async throws {
        // Upload multiple images
        let image1 = createTestImage(size: CGSize(width: 100, height: 100), color: .red)
        let image2 = createTestImage(size: CGSize(width: 100, height: 100), color: .blue)
        
        let result1 = try await imageUploadService.uploadImage(image1, to: "delete/batch1.jpg", compress: false)
        let result2 = try await imageUploadService.uploadImage(image2, to: "delete/batch2.jpg", compress: false)
        
        let urls = [result1.url, result2.url]
        
        // Verify they exist
        for url in urls {
            XCTAssertNotNil(mockImageStorage.getImageData(url: url))
        }
        
        // Delete all
        try await imageUploadService.deleteImages(urls: urls)
        
        // Verify they're deleted
        for url in urls {
            XCTAssertNil(mockImageStorage.getImageData(url: url))
        }
    }
    
    // MARK: - Image Manager Integration Tests
    
    func testImageManagerUploadAndLoad() async throws {
        let testImage = createTestImage(size: CGSize(width: 300, height: 300), color: .systemBlue)
        
        // Upload through manager
        let result = try await imageManager.uploadImage(testImage, to: "manager/test.jpg", compress: true)
        
        // Load through manager (should come from cache)
        let loadedImage = await imageManager.loadImage(from: result.url)
        
        XCTAssertNotNil(loadedImage)
        XCTAssertEqual(loadedImage?.size.width, testImage.size.width, accuracy: 1.0)
    }
    
    func testImageManagerPropertyImageProcessing() async throws {
        let images = [
            createTestImage(size: CGSize(width: 800, height: 600), color: .red),
            createTestImage(size: CGSize(width: 1000, height: 800), color: .green)
        ]
        let propertyId = "property789"
        
        let result = try await imageManager.processPropertyImages(
            images,
            propertyId: propertyId,
            generateThumbnails: true
        )
        
        XCTAssertEqual(result.originalImages.count, 2)
        XCTAssertEqual(result.thumbnailImages.count, 2)
        XCTAssertEqual(result.propertyId, propertyId)
        XCTAssertGreaterThan(result.totalUploadedSize, 0)
    }
    
    // MARK: - Helper Methods
    
    private func createTestImage(size: CGSize, color: UIColor) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}

// MARK: - Performance Tests

@available(iOS 15.0, *)
extension ImageHandlingTests {
    
    func testImageCompressionPerformance() throws {
        let largeImage = createTestImage(size: CGSize(width: 4000, height: 3000), color: .blue)
        
        measure {
            _ = ImageCompression.compressForProperty(largeImage)
        }
    }
    
    func testImageCachePerformance() async throws {
        let images = (0..<10).map { index in
            createTestImage(size: CGSize(width: 200, height: 200), color: .random)
        }
        
        let urls = (0..<10).map { index in
            URL(string: "https://example.com/perf_\(index).jpg")!
        }
        
        // Measure cache storage performance
        await measureAsync {
            for (image, url) in zip(images, urls) {
                await imageCache.store(image: image, for: url)
            }
        }
        
        // Measure cache retrieval performance
        await measureAsync {
            for url in urls {
                _ = await imageCache.image(for: url)
            }
        }
    }
    
    private func measureAsync(_ block: () async throws -> Void) async {
        let startTime = Date()
        try? await block()
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        print("Async operation took \(duration) seconds")
    }
}

// MARK: - UIColor Extension for Testing

extension UIColor {
    static var random: UIColor {
        return UIColor(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1),
            alpha: 1.0
        )
    }
}