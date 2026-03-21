import SwiftUI

/// View for displaying user profile information
@available(iOS 15.0, macOS 12.0, *)
struct ProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @State private var showEditSheet = false
    @State private var showDeleteConfirmation = false
    
    let isOwnProfile: Bool
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 24) {
                if viewModel.isLoading {
                    ProfileSkeleton()
                        .fadeInOnAppear()
                } else if let profile = viewModel.profile {
                    profileContent(profile)
                        .fadeInOnAppear()
                } else {
                    emptyState
                        .fadeInOnAppear()
                }
            }
            .padding()
        }
        .navigationTitle("Profile")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .toolbar {
            ToolbarItemGroup {
                if isOwnProfile {
                    #if os(iOS)
                    Button("Edit") {
                        showEditSheet = true
                    }
                    .disabled(viewModel.isLoading)
                    #else
                    Button("Edit") {
                        showEditSheet = true
                    }
                    .disabled(viewModel.isLoading)
                    #endif
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            ProfileEditView(viewModel: viewModel)
        }
        .alert("Delete Profile", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteProfile()
                }
            }
        } message: {
            Text("Are you sure you want to delete your profile? This action cannot be undone.")
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    @ViewBuilder
    private func profileContent(_ profile: UserProfile) -> some View {
        // Get filtered profile based on visibility settings
        let displayProfile = viewModel.getFilteredProfile(profile, isOwnProfile: isOwnProfile)
        
        VStack(spacing: 24) {
            // Profile Photo
            profilePhotoView(displayProfile)
            
            // Profile Information
            VStack(spacing: 16) {
                // Name
                VStack(alignment: .leading, spacing: 4) {
                    Text("Name")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(displayProfile.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                
                // Email
                if displayProfile.visibilitySettings.showEmail || isOwnProfile {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Email")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(displayProfile.email)
                            .font(.body)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Divider()
                }
                
                // Phone Number
                if let phoneNumber = displayProfile.phoneNumber,
                   (displayProfile.visibilitySettings.showPhone || isOwnProfile) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Phone")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(phoneNumber)
                            .font(.body)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Divider()
                }
                
                // Role
                VStack(alignment: .leading, spacing: 4) {
                    Text("Role")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(displayProfile.role.rawValue.capitalized)
                        .font(.body)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                
                // Member Since
                VStack(alignment: .leading, spacing: 4) {
                    Text("Member Since")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(displayProfile.createdAt, style: .date)
                        .font(.body)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            #if os(iOS)
            .background(Color(.systemBackground))
            #else
            .background(Color(NSColor.controlBackgroundColor))
            #endif
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            
            // Visibility Settings (only for own profile)
            if isOwnProfile {
                visibilitySettingsView(displayProfile)
            }
            
            // Delete Button (only for own profile)
            if isOwnProfile {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        }
                        Text("Delete Profile")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.isLoading ? Color.gray.opacity(0.6) : Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(viewModel.isLoading)
            }
        }
    }
    
    @ViewBuilder
    private func profilePhotoView(_ profile: UserProfile) -> some View {
        if let photoURL = profile.profilePhotoURL {
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
        } else {
            defaultProfileImage
        }
    }
    
    private var defaultProfileImage: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 120, height: 120)
            .foregroundColor(.gray)
    }
    
    @ViewBuilder
    private func visibilitySettingsView(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Privacy Settings")
                .font(.headline)
            
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: profile.visibilitySettings.showEmail ? "eye" : "eye.slash")
                        .foregroundColor(profile.visibilitySettings.showEmail ? .green : .gray)
                    Text("Email visible to others")
                        .font(.body)
                    Spacer()
                }
                
                HStack {
                    Image(systemName: profile.visibilitySettings.showPhone ? "eye" : "eye.slash")
                        .foregroundColor(profile.visibilitySettings.showPhone ? .green : .gray)
                    Text("Phone visible to others")
                        .font(.body)
                    Spacer()
                }
                
                HStack {
                    Image(systemName: profile.visibilitySettings.showListings ? "eye" : "eye.slash")
                        .foregroundColor(profile.visibilitySettings.showListings ? .green : .gray)
                    Text("Listings visible to others")
                        .font(.body)
                    Spacer()
                }
            }
        }
        .padding()
        #if os(iOS)
        .background(Color(.systemBackground))
        #else
        .background(Color(NSColor.controlBackgroundColor))
        #endif
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private var emptyState: some View {
        EmptyStateView.profileNotFound()
    }
}

// MARK: - Preview

@available(iOS 15.0, macOS 12.0, *)
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        let mockRemote = MockRemoteDataSource(simulateNetworkDelay: false)
        let persistence = PersistenceController(inMemory: true)
        let mockRepo = UserProfileRepository(
            localDataSource: LocalDataSource(persistenceController: persistence),
            remoteDataSource: mockRemote
        )
        let viewModel = ProfileViewModel(repository: mockRepo)
        
        // Set a sample profile
        viewModel.profile = UserProfile(
            id: "123",
            name: "John Doe",
            email: "john@example.com",
            phoneNumber: "+1234567890",
            role: .agent,
            visibilitySettings: ProfileVisibility(showEmail: true, showPhone: true, showListings: true)
        )

        return NavigationView {
            ProfileView(viewModel: viewModel, isOwnProfile: true)
        }
    }
}
