import SwiftUI

/// Post-signup onboarding wizard: walks a brand-new user through completing
/// their profile (contact info → role → privacy) instead of dropping them on
/// the "Profile Not Found" empty state. The account already exists server-side,
/// so skipping is always safe — finishing simply enriches the profile.
@available(iOS 15.0, macOS 12.0, *)
struct ProfileSetupView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @StateObject private var viewModel: ProfileViewModel

    @State private var step: Step = .contact

    enum Step: Int, CaseIterable {
        case contact
        case role
        case privacy

        var title: String {
            switch self {
            case .contact: return "About You"
            case .role: return "Your Role"
            case .privacy: return "Privacy"
            }
        }
    }

    init(authViewModel: AuthViewModel, userProfileRepository: UserProfileRepositoryProtocol) {
        self.authViewModel = authViewModel
        _viewModel = StateObject(wrappedValue: ProfileViewModel(repository: userProfileRepository))
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                progressHeader

                switch step {
                case .contact: contactStep
                case .role: roleStep
                case .privacy: privacyStep
                }

                Spacer()

                navigationButtons
            }
            .padding()
            .navigationTitle("Complete Your Profile")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") {
                        authViewModel.completeProfileSetup()
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .onAppear(perform: seedFromCurrentUser)
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }

    // MARK: - Steps

    private var progressHeader: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(Step.allCases, id: \.rawValue) { s in
                    Capsule()
                        .fill(s.rawValue <= step.rawValue ? Color.accentColor : Color.gray.opacity(0.3))
                        .frame(height: 4)
                }
            }
            Text("Step \(step.rawValue + 1) of \(Step.allCases.count): \(step.title)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var contactStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How should others see you?")
                .font(.headline)

            VStack(alignment: .leading, spacing: 4) {
                Text("Name").font(.caption).foregroundColor(.secondary)
                TextField("Full Name", text: $viewModel.editName)
                    .textFieldStyle(.roundedBorder)
                if let error = viewModel.nameValidationError {
                    Text(error).font(.caption).foregroundColor(.red)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Phone (optional)").font(.caption).foregroundColor(.secondary)
                TextField("Phone Number", text: $viewModel.editPhoneNumber)
                    .textFieldStyle(.roundedBorder)
                    #if os(iOS)
                    .keyboardType(.phonePad)
                    #endif
                if let error = viewModel.phoneValidationError {
                    Text(error).font(.caption).foregroundColor(.red)
                }
            }
        }
    }

    private var roleStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What brings you to RealDeal?")
                .font(.headline)

            ForEach(UserRole.allCases, id: \.self) { role in
                Button {
                    viewModel.editRole = role
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(role.displayName)
                                .font(.body)
                                .fontWeight(.semibold)
                            Text(roleDescription(role))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: viewModel.editRole == role ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(viewModel.editRole == role ? .accentColor : .gray)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(viewModel.editRole == role ? Color.accentColor : Color.gray.opacity(0.3))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var privacyStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What can other users see?")
                .font(.headline)

            Toggle("Show my email to others", isOn: $viewModel.editShowEmail)
            Toggle("Show my phone number to others", isOn: $viewModel.editShowPhone)
            Toggle("Show my listings to others", isOn: $viewModel.editShowListings)
        }
    }

    private var navigationButtons: some View {
        HStack {
            if step != .contact {
                Button("Back") {
                    step = Step(rawValue: step.rawValue - 1) ?? .contact
                }
                .disabled(viewModel.isLoading)
            }

            Spacer()

            if step == .privacy {
                Button {
                    Task { await finish() }
                } label: {
                    if viewModel.isLoading {
                        ProgressView().scaleEffect(0.8)
                    } else {
                        Text("Finish").fontWeight(.semibold)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canSave)
            } else {
                Button("Next") {
                    step = Step(rawValue: step.rawValue + 1) ?? .privacy
                }
                .buttonStyle(.borderedProminent)
                .disabled(step == .contact && viewModel.editName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    // MARK: - Actions

    private func roleDescription(_ role: UserRole) -> String {
        switch role {
        case .buyer: return "I'm looking for a property"
        case .homeowner: return "I'm selling my own property"
        case .agent: return "I manage listings for clients"
        }
    }

    /// The signup already created the account — seed the form with what we know.
    private func seedFromCurrentUser() {
        guard let user = authViewModel.currentUser else { return }
        viewModel.profile = user
        viewModel.editName = user.name
        viewModel.editEmail = user.email
        viewModel.editPhoneNumber = user.phoneNumber ?? ""
        viewModel.editRole = user.role
        viewModel.editShowEmail = user.visibilitySettings.showEmail
        viewModel.editShowPhone = user.visibilitySettings.showPhone
        viewModel.editShowListings = user.visibilitySettings.showListings
    }

    private func finish() async {
        await viewModel.updateProfile()
        // Only dismiss on success; on failure the alert shows and the user can retry or skip
        if viewModel.errorMessage == nil {
            authViewModel.completeProfileSetup(updatedProfile: viewModel.profile)
        }
    }
}

// MARK: - Preview

@available(iOS 15.0, macOS 12.0, *)
struct ProfileSetupView_Previews: PreviewProvider {
    static var previews: some View {
        let mockAuth = MockAuthenticationService(simulateNetworkDelay: false)
        let persistence = PersistenceController(inMemory: true)
        let repo = UserProfileRepository(
            localDataSource: LocalDataSource(persistenceController: persistence),
            remoteDataSource: MockRemoteDataSource(simulateNetworkDelay: false)
        )
        let authService = AuthenticationService(backendAuth: mockAuth, userProfileRepository: repo)
        return ProfileSetupView(
            authViewModel: AuthViewModel(authService: authService),
            userProfileRepository: repo
        )
    }
}
