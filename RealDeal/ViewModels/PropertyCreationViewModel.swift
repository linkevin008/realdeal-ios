import Foundation
import Combine
#if canImport(UIKit)
import UIKit
#endif

/// ViewModel managing property creation and editing state
@MainActor
@available(iOS 15.0, macOS 12.0, *)
class PropertyCreationViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var property: Property?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    // Form fields - Address
    @Published var street: String = ""
    @Published var city: String = ""
    @Published var state: String = ""
    @Published var zipCode: String = ""
    @Published var country: String = "USA"
    
    // Form fields - Basic Info
    @Published var price: String = ""
    @Published var propertyType: PropertyType = .house
    @Published var propertyDescription: String = ""
    
    // Form fields - Specifications
    @Published var bedrooms: String = ""
    @Published var bathrooms: String = ""
    @Published var squareFeet: String = ""
    @Published var lotSize: String = ""
    @Published var yearBuilt: String = ""
    
    // Form fields - Location
    @Published var latitude: String = ""
    @Published var longitude: String = ""
    
    // Images
    @Published var propertyImages: [Data] = []
    @Published var isUploadingImages: Bool = false
    
    // Validation errors
    @Published var streetValidationError: String?
    @Published var cityValidationError: String?
    @Published var stateValidationError: String?
    @Published var zipCodeValidationError: String?
    @Published var priceValidationError: String?
    @Published var descriptionValidationError: String?
    @Published var locationValidationError: String?
    
    // Status
    @Published var propertyStatus: PropertyStatus = .active
    
    // Confirmation dialogs
    @Published var showDeleteConfirmation: Bool = false
    
    // MARK: - Properties
    
    private let service: PropertyListingService
    private let currentUserId: String
    private var cancellables = Set<AnyCancellable>()
    
    var isEditMode: Bool {
        property != nil
    }
    
    // MARK: - Initialization
    
    init(
        service: PropertyListingService,
        currentUserId: String,
        property: Property? = nil
    ) {
        self.service = service
        self.currentUserId = currentUserId
        self.property = property
        
        if let property = property {
            populateFormFields(from: property)
        }
        
        setupValidation()
    }
    
    // MARK: - Validation Setup
    
    private func setupValidation() {
        // Street validation
        $street
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .sink { [weak self] value in
                guard let self = self, !value.isEmpty else {
                    self?.streetValidationError = nil
                    return
                }
                
                if value.trimmingCharacters(in: .whitespaces).isEmpty {
                    self.streetValidationError = "Street address is required"
                } else {
                    self.streetValidationError = nil
                }
            }
            .store(in: &cancellables)
        
        // City validation
        $city
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .sink { [weak self] value in
                guard let self = self, !value.isEmpty else {
                    self?.cityValidationError = nil
                    return
                }
                
                if value.trimmingCharacters(in: .whitespaces).isEmpty {
                    self.cityValidationError = "City is required"
                } else {
                    self.cityValidationError = nil
                }
            }
            .store(in: &cancellables)
        
        // State validation
        $state
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .sink { [weak self] value in
                guard let self = self, !value.isEmpty else {
                    self?.stateValidationError = nil
                    return
                }
                
                if value.trimmingCharacters(in: .whitespaces).isEmpty {
                    self.stateValidationError = "State is required"
                } else {
                    self.stateValidationError = nil
                }
            }
            .store(in: &cancellables)
        
        // Zip code validation
        $zipCode
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .sink { [weak self] value in
                guard let self = self, !value.isEmpty else {
                    self?.zipCodeValidationError = nil
                    return
                }
                
                let zipPattern = "^[0-9]{5}(-[0-9]{4})?$"
                let zipPredicate = NSPredicate(format: "SELF MATCHES %@", zipPattern)
                if !zipPredicate.evaluate(with: value) {
                    self.zipCodeValidationError = "Zip code must be in format 12345 or 12345-6789"
                } else {
                    self.zipCodeValidationError = nil
                }
            }
            .store(in: &cancellables)
        
        // Price validation
        $price
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .sink { [weak self] value in
                guard let self = self, !value.isEmpty else {
                    self?.priceValidationError = nil
                    return
                }
                
                if Decimal(string: value) == nil || Decimal(string: value)! <= 0 {
                    self.priceValidationError = "Price must be a positive number"
                } else {
                    self.priceValidationError = nil
                }
            }
            .store(in: &cancellables)
        
        // Description validation
        $propertyDescription
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .sink { [weak self] value in
                guard let self = self, !value.isEmpty else {
                    self?.descriptionValidationError = nil
                    return
                }
                
                if value.trimmingCharacters(in: .whitespaces).isEmpty {
                    self.descriptionValidationError = "Description is required"
                } else {
                    self.descriptionValidationError = nil
                }
            }
            .store(in: &cancellables)
        
        // Location validation
        Publishers.CombineLatest($latitude, $longitude)
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .sink { [weak self] lat, lon in
                guard let self = self, !lat.isEmpty || !lon.isEmpty else {
                    self?.locationValidationError = nil
                    return
                }
                
                guard let latValue = Double(lat), let lonValue = Double(lon) else {
                    self.locationValidationError = "Invalid coordinates"
                    return
                }
                
                if latValue < -90 || latValue > 90 || lonValue < -180 || lonValue > 180 {
                    self.locationValidationError = "Latitude must be -90 to 90, longitude -180 to 180"
                } else {
                    self.locationValidationError = nil
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    
    /// Create a new property listing
    func createProperty() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        guard validateForm() else {
            isLoading = false
            return
        }
        
        do {
            let newProperty = try buildPropertyFromForm()
            let createdProperty = try await service.createProperty(newProperty, imageDataArray: propertyImages)
            property = createdProperty
            successMessage = "Property listing created successfully"
        } catch let error as AppError {
            errorMessage = error.userMessage
        } catch let error as ValidationError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = "Failed to create property listing. Please try again."
        }
        
        isLoading = false
    }
    
    /// Update existing property listing
    func updateProperty() async {
        guard let existingProperty = property else {
            errorMessage = "No property to update"
            return
        }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        guard validateForm() else {
            isLoading = false
            return
        }
        
        do {
            let newPropertyData = try buildPropertyFromForm()
            
            // Create updated property with existing id and metadata
            var updatedProperty = Property(
                id: existingProperty.id,
                address: newPropertyData.address,
                price: newPropertyData.price,
                propertyType: newPropertyData.propertyType,
                description: newPropertyData.description,
                specifications: newPropertyData.specifications,
                images: existingProperty.images, // Keep existing images
                location: newPropertyData.location,
                source: existingProperty.source,
                sellerId: existingProperty.sellerId,
                status: propertyStatus,
                createdAt: existingProperty.createdAt,
                updatedAt: Date()
            )
            
            try await service.updateProperty(updatedProperty, newImageDataArray: propertyImages)
            property = updatedProperty
            propertyImages = [] // Clear new images after upload
            successMessage = "Property listing updated successfully"
        } catch let error as AppError {
            errorMessage = error.userMessage
        } catch let error as ValidationError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = "Failed to update property listing. Please try again."
        }
        
        isLoading = false
    }
    
    /// Delete property listing
    func deleteProperty() async {
        guard let existingProperty = property else {
            errorMessage = "No property to delete"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await service.deleteProperty(id: existingProperty.id)
            property = nil
            clearForm()
            successMessage = "Property listing deleted successfully"
        } catch let error as AppError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = "Failed to delete property listing. Please try again."
        }
        
        isLoading = false
    }
    
    /// Update property status
    func updateStatus(_ status: PropertyStatus) async {
        guard let existingProperty = property else {
            errorMessage = "No property to update"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await service.updatePropertyStatus(propertyId: existingProperty.id, status: status)
            property?.status = status
            propertyStatus = status
            successMessage = "Property status updated to \(status.rawValue)"
        } catch let error as AppError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = "Failed to update property status. Please try again."
        }
        
        isLoading = false
    }
    
    /// Add property images
    func addPropertyImages(_ imageDataArray: [Data]) {
        propertyImages.append(contentsOf: imageDataArray)
    }
    
    /// Remove property image at index
    func removePropertyImage(at index: Int) {
        guard index < propertyImages.count else { return }
        propertyImages.remove(at: index)
    }
    
    /// Delete existing property image
    func deleteExistingImage(_ imageURL: URL) async {
        guard var existingProperty = property else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await service.updateProperty(existingProperty, imagesToDelete: [imageURL])
            existingProperty.images = existingProperty.images.filter { $0.url != imageURL }
            property = existingProperty
            successMessage = "Image deleted successfully"
        } catch let error as AppError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = "Failed to delete image. Please try again."
        }
        
        isLoading = false
    }
    
    // MARK: - Form Management
    
    private func populateFormFields(from property: Property) {
        street = property.address.street
        city = property.address.city
        state = property.address.state
        zipCode = property.address.zipCode
        country = property.address.country
        
        price = property.price.description
        propertyType = property.propertyType
        propertyDescription = property.description
        
        bedrooms = property.specifications.bedrooms.map { String($0) } ?? ""
        bathrooms = property.specifications.bathrooms.map { String($0) } ?? ""
        squareFeet = property.specifications.squareFeet.map { String($0) } ?? ""
        lotSize = property.specifications.lotSize.map { String($0) } ?? ""
        yearBuilt = property.specifications.yearBuilt.map { String($0) } ?? ""
        
        latitude = String(property.location.latitude)
        longitude = String(property.location.longitude)
        
        propertyStatus = property.status
    }
    
    private func clearForm() {
        street = ""
        city = ""
        state = ""
        zipCode = ""
        country = "USA"
        
        price = ""
        propertyType = .house
        propertyDescription = ""
        
        bedrooms = ""
        bathrooms = ""
        squareFeet = ""
        lotSize = ""
        yearBuilt = ""
        
        latitude = ""
        longitude = ""
        
        propertyImages = []
        propertyStatus = .active
        
        streetValidationError = nil
        cityValidationError = nil
        stateValidationError = nil
        zipCodeValidationError = nil
        priceValidationError = nil
        descriptionValidationError = nil
        locationValidationError = nil
    }
    
    private func validateForm() -> Bool {
        var isValid = true
        
        // Required fields validation
        if street.trimmingCharacters(in: .whitespaces).isEmpty {
            streetValidationError = "Street address is required"
            isValid = false
        }
        
        if city.trimmingCharacters(in: .whitespaces).isEmpty {
            cityValidationError = "City is required"
            isValid = false
        }
        
        if state.trimmingCharacters(in: .whitespaces).isEmpty {
            stateValidationError = "State is required"
            isValid = false
        }
        
        let zipPattern = "^[0-9]{5}(-[0-9]{4})?$"
        let zipPredicate = NSPredicate(format: "SELF MATCHES %@", zipPattern)
        if !zipPredicate.evaluate(with: zipCode) {
            zipCodeValidationError = "Zip code must be in format 12345 or 12345-6789"
            isValid = false
        }
        
        if price.isEmpty || Decimal(string: price) == nil || Decimal(string: price)! <= 0 {
            priceValidationError = "Price must be a positive number"
            isValid = false
        }
        
        if propertyDescription.trimmingCharacters(in: .whitespaces).isEmpty {
            descriptionValidationError = "Description is required"
            isValid = false
        }
        
        if latitude.isEmpty || longitude.isEmpty {
            locationValidationError = "Location coordinates are required"
            isValid = false
        } else if let latValue = Double(latitude), let lonValue = Double(longitude) {
            if latValue < -90 || latValue > 90 || lonValue < -180 || lonValue > 180 {
                locationValidationError = "Latitude must be -90 to 90, longitude -180 to 180"
                isValid = false
            }
        } else {
            locationValidationError = "Invalid coordinates"
            isValid = false
        }
        
        return isValid
    }
    
    private func buildPropertyFromForm() throws -> Property {
        guard let priceValue = Decimal(string: price) else {
            throw ValidationError.invalidFormat("price")
        }
        
        guard let latValue = Double(latitude), let lonValue = Double(longitude) else {
            throw ValidationError.invalidLocation
        }
        
        let address = Address(
            street: street,
            city: city,
            state: state,
            zipCode: zipCode,
            country: country
        )
        
        let specifications = PropertySpecifications(
            bedrooms: bedrooms.isEmpty ? nil : Int(bedrooms),
            bathrooms: bathrooms.isEmpty ? nil : Double(bathrooms),
            squareFeet: squareFeet.isEmpty ? nil : Int(squareFeet),
            lotSize: lotSize.isEmpty ? nil : Double(lotSize),
            yearBuilt: yearBuilt.isEmpty ? nil : Int(yearBuilt)
        )
        
        let location = Coordinate(latitude: latValue, longitude: lonValue)
        
        return Property(
            address: address,
            price: priceValue,
            propertyType: propertyType,
            description: propertyDescription,
            specifications: specifications,
            location: location,
            source: .userGenerated,
            sellerId: currentUserId,
            status: propertyStatus
        )
    }
    
    // MARK: - Computed Properties
    
    var canSave: Bool {
        !street.isEmpty &&
        !city.isEmpty &&
        !state.isEmpty &&
        !zipCode.isEmpty &&
        !price.isEmpty &&
        !propertyDescription.isEmpty &&
        !latitude.isEmpty &&
        !longitude.isEmpty &&
        streetValidationError == nil &&
        cityValidationError == nil &&
        stateValidationError == nil &&
        zipCodeValidationError == nil &&
        priceValidationError == nil &&
        descriptionValidationError == nil &&
        locationValidationError == nil &&
        !isLoading
    }
}
