import Foundation
import Combine
import CoreLocation
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
    @Published var province: String = ""
    @Published var postalCode: String = ""
    /// ISO 3166-1 alpha-2 code (what the API stores); defaults to the device's
    /// region. The UI shows the localized country name.
    @Published var country: String = Locale.current.regionCode ?? "US"
    
    // Form fields - Basic Info
    @Published var price: String = ""
    @Published var propertyType: PropertyType = .house
    @Published var propertyDescription: String = ""
    
    // Form fields - Specifications
    @Published var bedrooms: String = ""
    @Published var bathrooms: String = ""
    @Published var squareFeet: String = ""
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
    @Published var provinceValidationError: String?
    @Published var postalCodeValidationError: String?
    @Published var priceValidationError: String?
    @Published var descriptionValidationError: String?
    @Published var locationValidationError: String?
    @Published var specificationsValidationError: String?
    
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
        
        // Province validation
        $province
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .sink { [weak self] value in
                guard let self = self, !value.isEmpty else {
                    self?.provinceValidationError = nil
                    return
                }

                if value.trimmingCharacters(in: .whitespaces).isEmpty {
                    self.provinceValidationError = "Province is required"
                } else {
                    self.provinceValidationError = nil
                }
            }
            .store(in: &cancellables)
        
        // Postal code validation — format depends on the selected country
        Publishers.CombineLatest($postalCode, $country)
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .sink { [weak self] value, country in
                guard let self = self, !value.isEmpty else {
                    self?.postalCodeValidationError = nil
                    return
                }
                self.postalCodeValidationError = Self.postalCodeError(value, country: country)
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

        // Coordinates come from the address, never from the user
        guard await resolveCoordinates() else {
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

        // Re-geocode on edit too — the address may have changed
        guard await resolveCoordinates() else {
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
        province = property.address.province
        postalCode = property.address.postalCode
        country = property.address.country
        
        price = property.price.description
        propertyType = property.propertyType
        propertyDescription = property.description
        
        bedrooms = property.specifications.bedrooms.map { String($0) } ?? ""
        bathrooms = property.specifications.bathrooms.map { String($0) } ?? ""
        squareFeet = property.specifications.squareFeet.map { String($0) } ?? ""
        yearBuilt = property.specifications.yearBuilt.map { String($0) } ?? ""
        
        latitude = String(property.location.latitude)
        longitude = String(property.location.longitude)
        
        propertyStatus = property.status
    }
    
    private func clearForm() {
        street = ""
        city = ""
        province = ""
        postalCode = ""
        country = "Canada"
        
        price = ""
        propertyType = .house
        propertyDescription = ""
        
        bedrooms = ""
        bathrooms = ""
        squareFeet = ""
        yearBuilt = ""
        
        latitude = ""
        longitude = ""
        
        propertyImages = []
        propertyStatus = .active
        
        streetValidationError = nil
        cityValidationError = nil
        provinceValidationError = nil
        postalCodeValidationError = nil
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
        
        if province.trimmingCharacters(in: .whitespaces).isEmpty {
            provinceValidationError = "Province is required"
            isValid = false
        }
        
        if let error = Self.postalCodeError(postalCode, country: country) {
            postalCodeValidationError = error
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

        // Specifications are required on every listing
        let currentYear = Calendar.current.component(.year, from: Date())
        if bedrooms.isEmpty || Int(bedrooms) == nil {
            specificationsValidationError = "Bedrooms is required"
            isValid = false
        } else if bathrooms.isEmpty || Double(bathrooms) == nil {
            specificationsValidationError = "Bathrooms is required"
            isValid = false
        } else if squareFeet.isEmpty || (Int(squareFeet) ?? 0) <= 0 {
            specificationsValidationError = "Square feet must be a positive number"
            isValid = false
        } else if yearBuilt.isEmpty || Int(yearBuilt) == nil
                    || Int(yearBuilt)! < 1800 || Int(yearBuilt)! > currentYear + 1 {
            specificationsValidationError = "Year built must be between 1800 and \(currentYear + 1)"
            isValid = false
        } else {
            specificationsValidationError = nil
        }
        
        // Coordinates are derived from the address via geocoding (resolveCoordinates),
        // not validated as user input.

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
            province: province,
            postalCode: postalCode,
            country: country
        )
        
        let specifications = PropertySpecifications(
            bedrooms: bedrooms.isEmpty ? nil : Int(bedrooms),
            bathrooms: bathrooms.isEmpty ? nil : Double(bathrooms),
            squareFeet: squareFeet.isEmpty ? nil : Int(squareFeet),
            lotSize: nil,
            yearBuilt: Int(yearBuilt)
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
        !province.isEmpty &&
        !postalCode.isEmpty &&
        !price.isEmpty &&
        !propertyDescription.isEmpty &&
        !bedrooms.isEmpty &&
        !bathrooms.isEmpty &&
        !squareFeet.isEmpty &&
        !yearBuilt.isEmpty &&
        streetValidationError == nil &&
        cityValidationError == nil &&
        provinceValidationError == nil &&
        postalCodeValidationError == nil &&
        priceValidationError == nil &&
        descriptionValidationError == nil &&
        locationValidationError == nil &&
        specificationsValidationError == nil &&
        !isLoading
    }

    // MARK: - Country / postal helpers

    /// Countries the platform supports, with localized display names. Loaded
    /// from the backend (the single source of truth) by loadSupportedCountries;
    /// starts with the launch list so the picker is never empty.
    @Published var supportedCountries: [(code: String, name: String)] = PropertyCreationViewModel.localized(["US", "CA"])

    /// Fetches the backend's supported-country list and reconciles the current
    /// selection (falls back to the first supported country if needed).
    func loadSupportedCountries() async {
        let codes = await service.supportedCountries()
        supportedCountries = Self.localized(codes)
        if !codes.contains(country), let first = codes.first {
            country = first
        }
    }

    private static func localized(_ codes: [String]) -> [(code: String, name: String)] {
        codes
            .map { (code: $0, name: Locale.current.localizedString(forRegionCode: $0) ?? $0) }
            .sorted { $0.name < $1.name }
    }

    /// Localized display name for the currently selected country code.
    var countryDisplayName: String {
        Locale.current.localizedString(forRegionCode: country) ?? country
    }

    /// True when the selected country calls its postal identifier a "ZIP Code".
    var usesZipCode: Bool { country == "US" }

    // MARK: - Geocoding

    /// Resolves an address string to coordinates. Injectable for tests; the
    /// default uses Apple's CLGeocoder, so users never type coordinates.
    var geocode: (String) async throws -> CLLocationCoordinate2D = { address in
        let placemarks = try await CLGeocoder().geocodeAddressString(address)
        guard let coordinate = placemarks.first?.location?.coordinate else {
            throw ValidationError.invalidLocation
        }
        return coordinate
    }

    /// Geocodes the entered address and fills latitude/longitude. Returns
    /// false (and sets a user-facing error) when the address can't be located.
    func resolveCoordinates() async -> Bool {
        let address = "\(street), \(city), \(province) \(postalCode), \(countryDisplayName)"
        do {
            let coordinate = try await geocode(address)
            latitude = String(coordinate.latitude)
            longitude = String(coordinate.longitude)
            locationValidationError = nil
            return true
        } catch {
            locationValidationError = "We couldn't locate that address — please double-check it"
            errorMessage = "We couldn't locate that address — please double-check it"
            return false
        }
    }

    /// Mirrors the server's per-country postal validation: strict formats for
    /// US/CA, non-empty for everywhere else.
    static func postalCodeError(_ value: String, country: String) -> String? {
        let patterns: [String: String] = [
            "US": "^\\d{5}(-\\d{4})?$",
            "CA": "^[A-Za-z]\\d[A-Za-z][ -]?\\d[A-Za-z]\\d$",
        ]
        if value.trimmingCharacters(in: .whitespaces).isEmpty {
            return country == "US" ? "ZIP code is required" : "Postal code is required"
        }
        if let pattern = patterns[country],
           !NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: value) {
            return country == "US" ? "Please enter a valid ZIP code (e.g. 90210)" : "Please enter a valid postal code (e.g. A1A 1A1)"
        }
        return nil
    }
}
