import SwiftUI

/// Main tab view for the application with navigation support
@available(iOS 17.0, macOS 12.0, *)
struct MainTabView: View {
    @ObservedObject var authViewModel: AuthViewModel

    // Dependencies
    private let propertyRepository: PropertyRepository
    private let userProfileRepository: UserProfileRepository
    private let favoritesRepository: FavoritesRepository
    private let propertyListingService: PropertyListingService
    private let remoteDataSource: RemoteDataSourceProtocol

    @StateObject private var coordinator: NavigationCoordinator

    init(
        authViewModel: AuthViewModel,
        propertyRepository: PropertyRepository,
        userProfileRepository: UserProfileRepository,
        favoritesRepository: FavoritesRepository,
        propertyListingService: PropertyListingService,
        remoteDataSource: RemoteDataSourceProtocol = MockRemoteDataSource(simulateNetworkDelay: false)
    ) {
        self.authViewModel = authViewModel
        self.propertyRepository = propertyRepository
        self.userProfileRepository = userProfileRepository
        self.favoritesRepository = favoritesRepository
        self.propertyListingService = propertyListingService
        self.remoteDataSource = remoteDataSource
        _coordinator = StateObject(wrappedValue: NavigationCoordinator(propertyRepository: propertyRepository))
    }

    /// The authenticated user's ID, or empty string when signed out.
    private var currentUserId: String {
        authViewModel.currentUser?.id ?? ""
    }

    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            // Browse Tab
            NavigationStack(path: $coordinator.browseNavigationPath) {
                PropertyListView(
                    viewModel: PropertyListViewModel(repository: propertyRepository)
                )
                .navigationDestination(for: NavigationCoordinator.Destination.self) { destination in
                    destinationView(for: destination)
                }
            }
            .tabItem {
                Label(
                    NavigationCoordinator.AppTab.browse.title,
                    systemImage: NavigationCoordinator.AppTab.browse.icon
                )
            }
            .tag(NavigationCoordinator.AppTab.browse)

            // Map Tab
            NavigationStack(path: $coordinator.mapNavigationPath) {
                MapView(
                    repository: propertyRepository,
                    userProfileRepository: userProfileRepository
                )
                .navigationDestination(for: NavigationCoordinator.Destination.self) { destination in
                    destinationView(for: destination)
                }
            }
            .tabItem {
                Label(
                    NavigationCoordinator.AppTab.map.title,
                    systemImage: NavigationCoordinator.AppTab.map.icon
                )
            }
            .tag(NavigationCoordinator.AppTab.map)

            // Favorites Tab
            NavigationStack(path: $coordinator.favoritesNavigationPath) {
                FavoritesListView(
                    viewModel: FavoritesViewModel(
                        favoritesRepository: favoritesRepository,
                        propertyRepository: propertyRepository,
                        currentUserId: currentUserId
                    )
                )
                .navigationDestination(for: NavigationCoordinator.Destination.self) { destination in
                    destinationView(for: destination)
                }
            }
            .tabItem {
                Label(
                    NavigationCoordinator.AppTab.favorites.title,
                    systemImage: NavigationCoordinator.AppTab.favorites.icon
                )
            }
            .tag(NavigationCoordinator.AppTab.favorites)

            // My Listings Tab — only meaningful for agents and homeowners
            NavigationStack(path: $coordinator.myListingsNavigationPath) {
                if authViewModel.isAuthenticated,
                   let role = authViewModel.currentUser?.role, role.canCreateListings {
                    MyListingsView(
                        viewModel: MyListingsViewModel(
                            service: propertyListingService,
                            currentUserId: currentUserId,
                            remoteDataSource: remoteDataSource
                        )
                    )
                    .navigationDestination(for: NavigationCoordinator.Destination.self) { destination in
                        destinationView(for: destination)
                    }
                } else {
                    listingsUnavailableView
                }
            }
            .tabItem {
                Label(
                    NavigationCoordinator.AppTab.myListings.title,
                    systemImage: NavigationCoordinator.AppTab.myListings.icon
                )
            }
            .tag(NavigationCoordinator.AppTab.myListings)

            // Profile Tab
            NavigationStack(path: $coordinator.profileNavigationPath) {
                if authViewModel.isAuthenticated, let userId = authViewModel.currentUser?.id {
                    ProfileTab(
                        repository: userProfileRepository,
                        userId: userId,
                        setupWizardActive: authViewModel.needsProfileSetup,
                        onSetupProfile: { authViewModel.needsProfileSetup = true }
                    )
                    .navigationDestination(for: NavigationCoordinator.Destination.self) { destination in
                        destinationView(for: destination)
                    }
                } else {
                    LoginView(viewModel: authViewModel)
                }
            }
            .tabItem {
                Label(
                    NavigationCoordinator.AppTab.profile.title,
                    systemImage: NavigationCoordinator.AppTab.profile.icon
                )
            }
            .tag(NavigationCoordinator.AppTab.profile)
        }
        .environmentObject(coordinator)
        .animation(AnimationUtilities.gentleEase, value: coordinator.selectedTab)
        .onOpenURL { url in
            coordinator.handleDeepLink(url: url)
        }
        #if os(iOS)
        .fullScreenCover(isPresented: $authViewModel.needsProfileSetup) {
            ProfileSetupView(authViewModel: authViewModel, userProfileRepository: userProfileRepository)
        }
        #else
        .sheet(isPresented: $authViewModel.needsProfileSetup) {
            ProfileSetupView(authViewModel: authViewModel, userProfileRepository: userProfileRepository)
        }
        #endif
    }

    // MARK: - Auth-gated views

    private var signInPromptView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("Sign in to view your profile")
                .font(.headline)
            NavigationLink("Sign In", destination: LoginView(viewModel: authViewModel))
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var listingsUnavailableView: some View {
        VStack(spacing: 16) {
            Image(systemName: "house.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            if !authViewModel.isAuthenticated {
                Text("Sign in to manage your listings")
                    .font(.headline)
                NavigationLink("Sign In", destination: LoginView(viewModel: authViewModel))
                    .buttonStyle(.borderedProminent)
            } else {
                Text("Listings are available for agents and homeowners")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Destination Views

    @ViewBuilder
    private func destinationView(for destination: NavigationCoordinator.Destination) -> some View {
        switch destination {
        case .propertyDetail(let property):
            PropertyDetailView(
                viewModel: PropertyDetailViewModel(
                    property: property,
                    propertyRepository: propertyRepository,
                    userProfileRepository: userProfileRepository,
                    favoritesRepository: favoritesRepository,
                    currentUserId: currentUserId
                )
            )

        case .propertyCreation:
            PropertyCreationView(
                viewModel: PropertyCreationViewModel(
                    service: propertyListingService,
                    currentUserId: currentUserId
                )
            )

        case .propertyEdit(let property):
            PropertyCreationView(
                viewModel: PropertyCreationViewModel(
                    service: propertyListingService,
                    currentUserId: currentUserId,
                    property: property
                )
            )

        case .profileView(let userId, let isOwnProfile):
            ProfileView(
                viewModel: ProfileViewModel(repository: userProfileRepository),
                isOwnProfile: isOwnProfile
            )
            .task {
                // Load the specified user's profile
                _ = userId
            }

        case .profileEdit:
            ProfileEditView(
                viewModel: ProfileViewModel(repository: userProfileRepository)
            )

        case .login:
            LoginView(viewModel: authViewModel)

        case .registration:
            RegistrationView(viewModel: authViewModel)
        }
    }
}

// MARK: - Profile Tab

/// Owns the ProfileViewModel as @StateObject so it survives MainTabView body
/// re-evaluations. Previously the view model was created inline in body, so any
/// published auth change replaced it with a fresh, never-loaded instance —
/// which is why new users saw "Profile Not Found" even though their profile
/// existed on the backend.
@available(iOS 17.0, macOS 12.0, *)
private struct ProfileTab: View {
    let userId: String
    let setupWizardActive: Bool
    let onSetupProfile: () -> Void
    @StateObject private var viewModel: ProfileViewModel

    init(
        repository: UserProfileRepository,
        userId: String,
        setupWizardActive: Bool,
        onSetupProfile: @escaping () -> Void
    ) {
        self.userId = userId
        self.setupWizardActive = setupWizardActive
        self.onSetupProfile = onSetupProfile
        _viewModel = StateObject(wrappedValue: ProfileViewModel(repository: repository))
    }

    var body: some View {
        ProfileView(viewModel: viewModel, isOwnProfile: true, onSetupProfile: onSetupProfile)
            // Keyed on the wizard flag too: the tab loads while the setup wizard
            // covers it, so it must reload when the wizard dismisses or it would
            // keep showing the pre-wizard profile.
            .task(id: "\(userId)-\(setupWizardActive)") { await viewModel.loadProfile(userId: userId) }
    }
}

// MARK: - Preview

@available(iOS 17.0, macOS 12.0, *)
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        let persistenceController = PersistenceController.preview
        let localDataSource = LocalDataSource(persistenceController: persistenceController)
        let mockRemoteDataSource = MockRemoteDataSource()

        let propertyRepository = PropertyRepository(
            localDataSource: localDataSource,
            remoteDataSource: mockRemoteDataSource
        )
        let userProfileRepository = UserProfileRepository(
            localDataSource: localDataSource,
            remoteDataSource: mockRemoteDataSource
        )
        let favoritesRepository = FavoritesRepository(
            localDataSource: localDataSource,
            remoteDataSource: mockRemoteDataSource
        )
        let propertyListingService = PropertyListingService(
            repository: propertyRepository
        )
        let authService = AuthenticationService(
            backendAuth: MockAuthenticationService(),
            userProfileRepository: userProfileRepository
        )
        let authViewModel = AuthViewModel(authService: authService)

        MainTabView(
            authViewModel: authViewModel,
            propertyRepository: propertyRepository,
            userProfileRepository: userProfileRepository,
            favoritesRepository: favoritesRepository,
            propertyListingService: propertyListingService
        )
        .environment(\.managedObjectContext, persistenceController.container.viewContext)
    }
}
