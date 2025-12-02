# Image Handling and Caching System

This document describes the comprehensive image handling and caching system implemented for the RealDeal app.

## Overview

The image handling system provides:
- **Memory and disk caching** for optimal performance
- **Lazy image loading** with placeholders
- **Image compression** for uploads
- **Progress tracking** for upload operations
- **Batch operations** for multiple images
- **Automatic cleanup** and cache management

## Core Components

### 1. ImageCache (`Utilities/ImageCache.swift`)

A comprehensive caching system with both memory and disk storage:

```swift
// Store image in cache
await ImageCache.shared.store(image: image, for: url)

// Retrieve image from cache
let cachedImage = await ImageCache.shared.image(for: url)

// Remove image from cache
await ImageCache.shared.removeImage(for: url)

// Clear all cached images
await ImageCache.shared.clearAll()

// Get cache information
let info = await ImageCache.shared.getCacheInfo()
```

**Features:**
- Automatic memory management with size limits
- Disk cache with expiration (7 days default)
- Background cleanup on memory warnings
- Thread-safe operations

### 2. ImageCompression (`Utilities/ImageCompression.swift`)

Intelligent image compression with multiple presets:

```swift
// Compress with custom settings
let result = ImageCompression.compress(image: image, settings: .property)

// Use preset compressions
let profileResult = ImageCompression.compressForProfile(image)
let propertyResult = ImageCompression.compressForProperty(image)
let thumbnailResult = ImageCompression.compressForThumbnail(image)

// Validate image before processing
let validation = ImageCompression.validateImage(image)
```

**Compression Presets:**
- **Profile**: 2MB max, 1024px max dimension, 80% quality
- **Property**: 5MB max, 2048px max dimension, 85% quality  
- **Thumbnail**: 500KB max, 300px max dimension, 70% quality

### 3. ImageUploadService (`Services/ImageUploadService.swift`)

Upload service with progress tracking and batch operations:

```swift
let uploadService = ImageUploadService(imageStorage: storage)

// Upload single image
let result = try await uploadService.uploadImage(image, to: "path/image.jpg")

// Upload multiple images
let results = try await uploadService.uploadImages(imagesWithPaths)

// Upload with convenience methods
let profileResult = try await uploadService.uploadProfilePhoto(image, userId: "user123")
let propertyResults = try await uploadService.uploadPropertyImages(images, propertyId: "prop456")
```

**Features:**
- Real-time progress tracking
- Automatic compression
- Batch upload optimization
- Upload cancellation support

### 4. LazyImageView (`Views/LazyImageView.swift`)

SwiftUI view for lazy image loading with caching:

```swift
// Basic lazy image
LazyImageView(url: imageURL)

// With custom placeholder
LazyImageView(url: imageURL) {
    Text("Loading...")
} errorView: {
    Text("Failed to load")
}

// Specialized views
PropertyImageView(url: imageURL, aspectRatio: 16/9)
ProfileImageView(url: imageURL, size: 80)
ImageGalleryView(imageUrls: urls, aspectRatio: 4/3)
```

**Features:**
- Automatic caching integration
- Customizable placeholders and error views
- Smooth animations
- Specialized views for different use cases

### 5. ImageManager (`Services/ImageManager.swift`)

Central coordinator for all image operations:

```swift
let imageManager = ImageManager.shared

// Load image with caching
let image = await imageManager.loadImage(from: url)

// Upload with progress tracking
let result = try await imageManager.uploadImage(image, to: path)

// Process property images (original + thumbnails)
let processingResult = try await imageManager.processPropertyImages(
    images, 
    propertyId: "prop123",
    generateThumbnails: true
)

// Cache management
let cacheInfo = await imageManager.getCacheInfo()
await imageManager.clearCache()
```

## Usage Examples

### Property Listing Images

```swift
// Upload property images with thumbnails
let images = [image1, image2, image3]
let result = try await ImageManager.shared.processPropertyImages(
    images,
    propertyId: propertyId,
    generateThumbnails: true
)

// Display in gallery
ImageGalleryView(imageUrls: result.originalImageUrls)
```

### Profile Photo

```swift
// Upload profile photo
let result = try await ImageManager.shared.uploadProfilePhoto(
    profileImage, 
    userId: currentUser.id
)

// Display profile image
ProfileImageView(url: result.url, size: 60)
```

### Image Picker Integration

```swift
// Enhanced image picker with compression
EnhancedImagePicker.forPropertyImages(
    selectedImages: $selectedImages,
    selectionLimit: 10
) { images in
    // Handle selected images
}

// Upload button with progress
ImageUploadButton(
    title: "Upload Property Images",
    uploadType: .property(propertyId)
) { urls in
    // Handle uploaded URLs
}
```

## Performance Considerations

### Memory Management
- Memory cache automatically evicts images under memory pressure
- Disk cache has size limits (200MB default) with LRU eviction
- Images are compressed before caching to reduce memory usage

### Network Optimization
- Images are cached after first download
- Batch uploads are optimized for parallel processing
- Automatic retry logic for failed operations

### UI Performance
- Lazy loading prevents blocking the main thread
- Smooth animations for image state transitions
- Background processing for compression operations

## Configuration

### Cache Settings
```swift
// Cache limits are configurable in ImageCache
private let maxMemoryCacheSize: Int = 50 * 1024 * 1024 // 50MB
private let maxDiskCacheSize: Int = 200 * 1024 * 1024 // 200MB
private let maxCacheAge: TimeInterval = 7 * 24 * 60 * 60 // 7 days
```

### Compression Settings
```swift
// Custom compression settings
let customSettings = ImageCompression.CompressionSettings(
    maxFileSize: 3 * 1024 * 1024, // 3MB
    maxDimension: 1500,
    jpegQuality: 0.75
)
```

## Error Handling

The system provides comprehensive error handling:

```swift
enum ImageUploadError: Error {
    case invalidImage([String])
    case compressionFailed
    case uploadFailed(Error)
    case cancelled
}

enum LazyImageError: Error {
    case invalidURL
    case invalidImageData
    case networkError(Error)
}
```

## Testing

Comprehensive test suite in `RealDealTests/ImageHandlingTests.swift`:

- Cache operations (store, retrieve, remove)
- Image compression with different settings
- Upload operations (single, batch, specialized)
- Image deletion and cleanup
- Performance testing
- Integration testing

## Integration Points

### Backend Storage
The system works with any backend through the `ImageStorageProtocol`:
- Firebase Storage
- AWS S3
- Custom REST API
- Mock storage (for testing)

### UI Components
Integrates seamlessly with SwiftUI:
- Property listing views
- Profile management
- Image galleries
- Upload progress indicators

## Best Practices

1. **Always use compression** for uploads to reduce bandwidth and storage costs
2. **Implement proper error handling** for network operations
3. **Use appropriate image sizes** for different contexts (profile vs property vs thumbnail)
4. **Monitor cache size** and clear when necessary
5. **Provide user feedback** during upload operations
6. **Handle offline scenarios** gracefully with cached images

## Future Enhancements

Potential improvements:
- WebP format support for better compression
- Progressive image loading
- Image editing capabilities
- Cloud-based image processing
- Advanced caching strategies (CDN integration)
- Image metadata extraction and search