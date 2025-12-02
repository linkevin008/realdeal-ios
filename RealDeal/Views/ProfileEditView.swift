import SwiftUI

/// View for creating and editing user profiles
@available(iOS 15.0, macOS 12.0, *)
struct ProfileEditView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showImagePicker = false
    
    var isCreating: Bool {
        viewModel.profile == nil
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Profile Photo Section
                Section {
                    profilePhotoSection
                } header: {
                    Text("Profile Photo")
                }
                
                // Basic Information Section
                Section {
                    // Name Field
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Name", text: $viewModel.editName)
                            #if os(iOS)
                            .textContentType(.name)
                            .autocapitalization(.words)
                            #endif
                            .disabled(viewModel.isLoading)
                        
                        if let error = viewModel.nameValidationError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    // Email Field
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Email", text: $viewModel.editEmail)
                            #if os(iOS)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            #endif
                            .disabled(viewModel.isLoading)
                        
                        if let error = viewModel.emailValidationError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    // Phone Number Field
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Phone Number (Optional)", text: $viewModel.editPhoneNumber)
                            #if os(iOS)
                            .textContentType(.telephoneNumber)
                            .keyboardType(.phonePad)
                            #endif
                            .disabled(viewModel.isLoading)
                        
                        if let error = viewModel.phoneValidationError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    // Role Picker
                    Picker("Role", selection: $viewModel.editRole) {
                        Text("Buyer").tag(UserRole.buyer)
                        Text("Seller").tag(UserRole.seller)
                        Text("Both").tag(UserRole.both)
                    }
                    .disabled(viewModel.isLoading)
                } header: {
                    Text("Basic Information")
                }
                
                // Privacy Settings Section
                Section {
                    Toggle("Show email to others", isOn: $viewModel.editShowEmail)
                        .disabled(viewModel.isLoading)
                    
                    Toggle("Show phone to others", isOn: $viewModel.editShowPhone)
                        .disabled(viewModel.isLoading)
                    
                    Toggle("Show my listings to others", isOn: $viewModel.editShowListings)
                        .disabled(viewModel.isLoading)
                } header: {
                    Text("Privacy Settings")
                } footer: {
                    Text("Control what information is visible to other users")
                        .font(.caption)
                }
                
                // Error/Success Messages
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                if let successMessage = viewModel.successMessage {
                    Section {
                        Text(successMessage)
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(isCreating ? "Create Profile" : "Edit Profile")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(viewModel.isLoading)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            if isCreating {
                                // For creating, we need a user ID - this should be passed in
                                // For now, we'll use a placeholder
                                await viewModel.createProfile(userId: UUID().uuidString)
                            } else {
                                await viewModel.updateProfile()
                            }
                            
                            // Dismiss on success
                            if viewModel.errorMessage == nil {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }
                    .primaryButtonStyle(isLoading: viewModel.isLoading, isDisabled: !viewModel.canSave)
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(viewModel.isLoading)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            if isCreating {
                                await viewModel.createProfile(userId: UUID().uuidString)
                            } else {
                                await viewModel.updateProfile()
                            }
                            
                            if viewModel.errorMessage == nil {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }
                    .primaryButtonStyle(isLoading: viewModel.isLoading, isDisabled: !viewModel.canSave)
                }
                #endif
            }
            #if os(iOS)
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(imageData: $viewModel.profilePhotoData)
            }
            #endif
        }
    }
    
    @ViewBuilder
    private var profilePhotoSection: some View {
        VStack(spacing: 12) {
            // Photo Preview
            profilePhotoPreview
            
            // Photo Actions
            HStack(spacing: 16) {
                #if os(iOS)
                Button(action: {
                    showImagePicker = true
                }) {
                    Label("Choose Photo", systemImage: "photo")
                        .font(.caption)
                }
                .compactButtonStyle(isLoading: viewModel.isUploadingPhoto, isDisabled: viewModel.isLoading)
                #endif
                
                if viewModel.profilePhotoData != nil || viewModel.profile?.profilePhotoURL != nil {
                    Button(role: .destructive, action: {
                        viewModel.clearProfilePhoto()
                    }) {
                        Label("Remove", systemImage: "trash")
                            .font(.caption)
                    }
                    .compactButtonStyle(isDisabled: viewModel.isLoading || viewModel.isUploadingPhoto)
                }
            }
            
            if viewModel.isUploadingPhoto {
                LoadingIndicator(style: .inline, message: "Uploading photo...")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
    
    @ViewBuilder
    private var profilePhotoPreview: some View {
        #if canImport(UIKit)
        if let photoData = viewModel.profilePhotoData,
           let uiImage = UIImage(data: photoData) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 120, height: 120)
                .clipShape(Circle())
        } else if let photoURL = viewModel.profile?.profilePhotoURL {
            photoURLPreview(photoURL)
        } else {
            defaultProfileImage
        }
        #else
        if let photoURL = viewModel.profile?.profilePhotoURL {
            photoURLPreview(photoURL)
        } else {
            defaultProfileImage
        }
        #endif
    }
    
    @ViewBuilder
    private func photoURLPreview(_ photoURL: URL) -> some View {
        AsyncImage(url: photoURL) { phase in
            switch phase {
            case .empty:
                SkeletonView(width: 120, height: 120, cornerRadius: 60)
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
            case .failure:
                defaultProfileImage
            @unknown default:
                defaultProfileImage
            }
        }
    }
    
    private var defaultProfileImage: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 120, height: 120)
            .foregroundColor(.gray)
    }
}

// MARK: - Preview

@available(iOS 15.0, macOS 12.0, *)
struct ProfileEditView_Previews: PreviewProvider {
    static var previews: some View {
        let mockRemote = MockRemoteDataSource(simulateNetworkDelay: false)
        let persistence = PersistenceController(inMemory: true)
        let mockRepo = UserProfileRepository(
            localDataSource: LocalDataSource(persistenceController: persistence),
            remoteDataSource: mockRemote
        )
        let viewModel = ProfileViewModel(repository: mockRepo)
        
        // Set a sample profile for editing
        viewModel.profile = UserProfile(
            id: "123",
            name: "John Doe",
            email: "john@example.com",
            phoneNumber: "+1234567890",
            role: .seller,
            visibilitySettings: ProfileVisibility(showEmail: true, showPhone: true, showListings: true)
        )
        
        // Populate edit fields
        viewModel.editName = "John Doe"
        viewModel.editEmail = "john@example.com"
        viewModel.editPhoneNumber = "+1234567890"
        viewModel.editRole = .seller
        
        return ProfileEditView(viewModel: viewModel)
    }
}
