import Foundation
import Combine
#if canImport(UIKit)
import UIKit
#endif

/// ViewModel managing user profile state and operations
@MainActor
@available(iOS 15.0, macOS 12.0, *)
class ProfileViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var profile: UserProfile?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    // Edit form fields
    @Published var editName: String = ""
    @Published var editEmail: String = ""
    @Published var editPhoneNumber: String = ""
    @Published var editRole: UserRole = .buyer
    @Published var editShowEmail: Bool = true
    @Published var editShowPhone: Bool = true
    @Published var editShowListings: Bool = true
    
    // Profile photo
    @Published var profilePhotoData: Data?
    @Published var isUploadingPhoto: Bool = false
    
    // Validation errors
    @Published var nameValidationError: String?
    @Published var emailValidationError: String?
    @Published var phoneValidationError: String?
    
    // MARK: - Properties
    
    private let repository: UserProfileRepositoryProtocol
    private let imageStorage: ImageStorageProtocol?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        repository: UserProfileRepositoryProtocol,
        imageStorage: ImageStorageProtocol? = nil
    ) {
        self.repository = repository
        self.imageStorage = imageStorage
        setupValidation()
    }
    
    // MARK: - Validation Setup
    
    private func setupValidation() {
        // Name validation
        $editName
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .sink { [weak self] name in
                guard let self = self, !name.isEmpty else {
                    self?.nameValidationError = nil
                    return
                }
                
                if name.trimmingCharacters(in: .whitespaces).isEmpty {
                    self.nameValidationError = "Name cannot be empty"
                } else {
                    self.nameValidationError = nil
                }
            }
            .store(in: &cancellables)
        
        // Email validation
        $editEmail
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .sink { [weak self] email in
                guard let self = self, !email.isEmpty else {
                    self?.emailValidationError = nil
                    return
                }
                
                if !Validator.isValidEmail(email) {
                    self.emailValidationError = "Please enter a valid email address"
                } else {
                    self.emailValidationError = nil
                }
            }
            .store(in: &cancellables)
        
        // Phone validation
        $editPhoneNumber
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .sink { [weak self] phone in
                guard let self = self, !phone.isEmpty else {
                    self?.phoneValidationError = nil
                    return
                }
                
                if !Validator.isValidPhoneNumber(phone) {
                    self.phoneValidationError = "Please enter a valid phone number"
                } else {
                    self.phoneValidationError = nil
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    
    /// Load user profile by ID
    func loadProfile(userId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let loadedProfile = try await repository.fetchUserProfile(id: userId)
            profile = loadedProfile
            populateEditFields(from: loadedProfile)
        } catch let error as AppError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = "Failed to load profile. Please try again."
        }
        
        isLoading = false
    }
    
    /// Create a new user profile
    func createProfile(userId: String) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        guard validateForm() else {
            isLoading = false
            return
        }
        
        do {
            var newProfile = UserProfile(
                id: userId,
                name: editName,
                email: editEmail,
                phoneNumber: editPhoneNumber.isEmpty ? nil : editPhoneNumber,
                role: editRole,
                visibilitySettings: ProfileVisibility(
                    showEmail: editShowEmail,
                    showPhone: editShowPhone,
                    showListings: editShowListings
                )
            )
            
            // Upload profile photo if provided
            if let photoData = profilePhotoData {
                newProfile.profilePhotoURL = try await uploadProfilePhoto(photoData, userId: userId)
            }
            
            // Validate the profile
            try newProfile.validate()
            
            let createdProfile = try await repository.createUserProfile(newProfile)
            profile = createdProfile
            successMessage = "Profile created successfully"
        } catch let error as AppError {
            errorMessage = error.userMessage
        } catch let error as ValidationError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = "Failed to create profile. Please try again."
        }
        
        isLoading = false
    }
    
    /// Update existing user profile
    func updateProfile() async {
        guard let currentProfile = profile else {
            errorMessage = "No profile to update"
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
            var updatedProfile = currentProfile
            updatedProfile.name = editName
            updatedProfile.email = editEmail
            updatedProfile.phoneNumber = editPhoneNumber.isEmpty ? nil : editPhoneNumber
            updatedProfile.role = editRole
            updatedProfile.visibilitySettings = ProfileVisibility(
                showEmail: editShowEmail,
                showPhone: editShowPhone,
                showListings: editShowListings
            )
            
            // Upload new profile photo if provided
            if let photoData = profilePhotoData {
                // Delete old photo if exists
                if let oldPhotoURL = currentProfile.profilePhotoURL {
                    try? await imageStorage?.deleteImage(url: oldPhotoURL)
                }
                updatedProfile.profilePhotoURL = try await uploadProfilePhoto(photoData, userId: currentProfile.id)
            }
            
            // Validate the profile
            try updatedProfile.validate()
            
            try await repository.updateUserProfile(updatedProfile)
            profile = updatedProfile
            successMessage = "Profile updated successfully"
        } catch let error as AppError {
            errorMessage = error.userMessage
        } catch let error as ValidationError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = "Failed to update profile. Please try again."
        }
        
        isLoading = false
    }
    
    /// Delete user profile
    func deleteProfile() async {
        guard let currentProfile = profile else {
            errorMessage = "No profile to delete"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Delete profile photo if exists
            if let photoURL = currentProfile.profilePhotoURL {
                try? await imageStorage?.deleteImage(url: photoURL)
            }
            
            try await repository.deleteUserProfile(id: currentProfile.id)
            profile = nil
            clearEditFields()
            successMessage = "Profile deleted successfully"
        } catch let error as AppError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = "Failed to delete profile. Please try again."
        }
        
        isLoading = false
    }
    
    /// Upload profile photo
    private func uploadProfilePhoto(_ imageData: Data, userId: String) async throws -> URL {
        guard let imageStorage = imageStorage else {
            throw AppError.unknown(NSError(domain: "ProfileViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Image storage not configured"]))
        }
        
        // Validate photo
        try ProfilePhotoValidator.validate(imageData)
        
        isUploadingPhoto = true
        defer { isUploadingPhoto = false }
        
        let path = "profiles/\(userId)/photo.jpg"
        return try await imageStorage.uploadImage(imageData, path: path)
    }
    
    /// Set profile photo from image data
    func setProfilePhoto(_ imageData: Data) {
        do {
            try ProfilePhotoValidator.validate(imageData)
            profilePhotoData = imageData
            errorMessage = nil
        } catch let error as ValidationError {
            errorMessage = error.userMessage
            profilePhotoData = nil
        } catch {
            errorMessage = "Invalid image file"
            profilePhotoData = nil
        }
    }
    
    /// Clear profile photo
    func clearProfilePhoto() {
        profilePhotoData = nil
    }
    
    // MARK: - Form Management
    
    private func populateEditFields(from profile: UserProfile) {
        editName = profile.name
        editEmail = profile.email
        editPhoneNumber = profile.phoneNumber ?? ""
        editRole = profile.role
        editShowEmail = profile.visibilitySettings.showEmail
        editShowPhone = profile.visibilitySettings.showPhone
        editShowListings = profile.visibilitySettings.showListings
    }
    
    private func clearEditFields() {
        editName = ""
        editEmail = ""
        editPhoneNumber = ""
        editRole = .buyer
        editShowEmail = true
        editShowPhone = true
        editShowListings = true
        profilePhotoData = nil
        
        nameValidationError = nil
        emailValidationError = nil
        phoneValidationError = nil
    }
    
    private func validateForm() -> Bool {
        var isValid = true
        
        // Name validation
        if editName.trimmingCharacters(in: .whitespaces).isEmpty {
            nameValidationError = "Name is required"
            isValid = false
        }
        
        // Email validation
        if editEmail.isEmpty {
            emailValidationError = "Email is required"
            isValid = false
        } else if !Validator.isValidEmail(editEmail) {
            emailValidationError = "Please enter a valid email address"
            isValid = false
        }
        
        // Phone validation (optional field)
        if !editPhoneNumber.isEmpty && !Validator.isValidPhoneNumber(editPhoneNumber) {
            phoneValidationError = "Please enter a valid phone number"
            isValid = false
        }
        
        return isValid
    }
    
    // MARK: - Computed Properties
    
    var canSave: Bool {
        !editName.isEmpty &&
        !editEmail.isEmpty &&
        nameValidationError == nil &&
        emailValidationError == nil &&
        phoneValidationError == nil &&
        !isLoading
    }
    
    /// Get filtered profile for display based on visibility settings
    func getFilteredProfile(_ profile: UserProfile, isOwnProfile: Bool) -> UserProfile {
        guard !isOwnProfile else {
            return profile // Show everything for own profile
        }
        
        var filtered = profile
        
        // Apply visibility settings
        if !profile.visibilitySettings.showEmail {
            filtered.email = "Hidden"
        }
        
        if !profile.visibilitySettings.showPhone {
            filtered.phoneNumber = nil
        }
        
        return filtered
    }
}
