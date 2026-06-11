import Foundation

/// Service for managing property listing operations
/// Handles CRUD operations for user-generated property listings
@available(iOS 15.0, macOS 12.0, *)
class PropertyListingService {
    // MARK: - Properties
    
    private let repository: PropertyRepositoryProtocol
    private let imageStorage: ImageStorageProtocol?
    
    // MARK: - Initialization
    
    init(
        repository: PropertyRepositoryProtocol,
        imageStorage: ImageStorageProtocol? = nil
    ) {
        self.repository = repository
        self.imageStorage = imageStorage
    }
    
    // MARK: - CRUD Operations
    
    /// Create a new property listing
    /// - Parameters:
    ///   - property: The property to create
    ///   - imageDataArray: Array of image data to upload
    /// - Returns: The created property with uploaded image URLs
    func createProperty(_ property: Property, imageDataArray: [Data]) async throws -> Property {
        // Validate property data
        try property.validate()
        
        var propertyToCreate = property
        
        // Upload images if provided
        if !imageDataArray.isEmpty, let imageStorage = imageStorage {
            let imageURLs = try await uploadPropertyImages(imageDataArray, propertyId: property.id)
            propertyToCreate.images = imageURLs.enumerated().map { index, url in
                PropertyImage(url: url, order: index)
            }
        }
        
        // Create property through repository
        return try await repository.createProperty(propertyToCreate)
    }
    
    /// Update an existing property listing
    /// - Parameters:
    ///   - property: The property with updated data
    ///   - newImageDataArray: Optional array of new images to add
    ///   - imagesToDelete: Optional array of image URLs to delete
    func updateProperty(
        _ property: Property,
        newImageDataArray: [Data] = [],
        imagesToDelete: [URL] = []
    ) async throws {
        // Validate property data
        try property.validate()
        
        var propertyToUpdate = property
        
        // Delete specified images
        if !imagesToDelete.isEmpty, let imageStorage = imageStorage {
            try await imageStorage.deleteImages(urls: imagesToDelete)
            // Remove deleted images from property
            propertyToUpdate.images = propertyToUpdate.images.filter { image in
                !imagesToDelete.contains(image.url)
            }
        }
        
        // Upload new images if provided
        if !newImageDataArray.isEmpty, let imageStorage = imageStorage {
            let newImageURLs = try await uploadPropertyImages(newImageDataArray, propertyId: property.id)
            let startOrder = propertyToUpdate.images.count
            let newImages = newImageURLs.enumerated().map { index, url in
                PropertyImage(url: url, order: startOrder + index)
            }
            propertyToUpdate.images.append(contentsOf: newImages)
        }
        
        // Update timestamp
        propertyToUpdate.updatedAt = Date()
        
        // Update property through repository
        try await repository.updateProperty(propertyToUpdate)
    }
    
    /// Delete a property listing
    /// - Parameter propertyId: The ID of the property to delete
    func deleteProperty(id: String) async throws {
        // Fetch property to get image URLs
        if let property = try await repository.getProperty(id: id) {
            // Delete all associated images
            if !property.images.isEmpty, let imageStorage = imageStorage {
                let imageURLs = property.images.map { $0.url }
                try? await imageStorage.deleteImages(urls: imageURLs)
            }
        }
        
        // Delete property through repository
        try await repository.deleteProperty(id: id)
    }
    
    /// Fetch properties for a specific seller
    /// - Parameter sellerId: The seller's user ID
    /// - Returns: Array of properties owned by the seller
    /// Countries listings can be created in. Falls back to the launch list if
    /// the backend is unreachable so the form is never empty.
    func supportedCountries() async -> [String] {
        (try? await repository.fetchSupportedCountries()) ?? ["US", "CA"]
    }

    func fetchSellerProperties(sellerId: String) async throws -> [Property] {
        let allProperties = try await repository.fetchProperties(filters: nil)
        return allProperties.filter { $0.sellerId == sellerId }
    }
    
    /// Update property status
    /// - Parameters:
    ///   - propertyId: The ID of the property
    ///   - status: The new status
    func updatePropertyStatus(propertyId: String, status: PropertyStatus) async throws {
        guard var property = try await repository.getProperty(id: propertyId) else {
            throw AppError.notFound
        }
        
        property.status = status
        property.updatedAt = Date()
        
        try await repository.updateProperty(property)
    }
    
    // MARK: - Private Helpers
    
    /// Upload property images to storage
    private func uploadPropertyImages(_ imageDataArray: [Data], propertyId: String) async throws -> [URL] {
        guard let imageStorage = imageStorage else {
            throw AppError.unknown("Image storage not configured")
        }
        
        // Validate all images first
        for imageData in imageDataArray {
            try validatePropertyImage(imageData)
        }
        
        // Prepare upload data
        let imagesWithPaths = imageDataArray.enumerated().map { index, data in
            let path = "properties/\(propertyId)/image_\(index)_\(UUID().uuidString).jpg"
            return (data: data, path: path)
        }
        
        // Upload all images
        return try await imageStorage.uploadImages(imagesWithPaths)
    }
    
    /// Validate property image data
    private func validatePropertyImage(_ imageData: Data) throws {
        // Check size (max 5 MB)
        let maxSize = 5 * 1024 * 1024
        guard imageData.count <= maxSize else {
            throw ValidationError.imageTooLarge
        }
        
        // Basic format validation (check for JPEG/PNG headers)
        guard imageData.count > 4 else {
            throw ValidationError.invalidImageFormat
        }
        
        let bytes = [UInt8](imageData.prefix(4))
        
        // JPEG: FF D8 FF
        let isJPEG = bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF
        
        // PNG: 89 50 4E 47
        let isPNG = bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47
        
        guard isJPEG || isPNG else {
            throw ValidationError.invalidImageFormat
        }
    }
}
