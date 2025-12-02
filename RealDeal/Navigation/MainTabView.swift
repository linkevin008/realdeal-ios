import SwiftUI

/// Main tab view for the application with navigation support
@available(iOS 17.0, macOS 12.0, *)
struct MainTabView: View {
    @StateObject private var coordinator = NavigationCoordinator()
    
    // Dependencies
    private let propertyRepository: PropertyRepository
    private let userProfileRepository: UserProfileRepository
    private let favoritesRepository: FavoritesRepository
    private let propertyListingService: PropertyListingService
    
    // Current user ID (TODO: Replace with actual auth)
    private let currentUserId: String = "demo-user-id"
    
    init(
        propertyRepository: PropertyRepository,
        userProfileRepository: UserProfileRepository,
        favoritesRepository: FavoritesRepository,
        propertyListingService: PropertyListingService
    ) {
        self.propertyRepository = propertyRepository
        self.userProfileRepository = userProfileRepository
        self.favoritesRepository = favoritesRepository
        self.propertyListingService = propertyListingService
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
            
            // My Listings Tab
            NavigationStack(path: $coordinator.myListingsNavigationPath) {
                MyListingsView(
                    viewModel: MyListingsViewModel(
                        service: propertyListingService,
                        currentUserId: currentUserId
                    )
                )
                .navigationDestination(for: NavigationCoordinator.Destination.self) { destination in
                    destinationView(for: destination)
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
                ProfileView(
                    viewModel: ProfileViewModel(repository: userProfileRepository),
                    isOwnProfile: true
                )
                .navigationDestination(for: NavigationCoordinator.Destination.self) { destination in
                    destinationView(for: destination)
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
    }
    
    // MARK: - Destination Views
    
    @ViewBuilder
    private func destinationView(for destination: NavigationCoordinator.Destination) -> some View {
        switch destination {
        case .propertyDetail(let propertyId):
            PropertyDetailView(
                viewModel: PropertyDetailViewModel(
                    propertyId: propertyId,
                    repository: propertyRepository,
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
            
        case .propertyEdit(let propertyId):
            PropertyCreationView(
                viewModel: PropertyCreationViewModel(
                    service: propertyListingService,
                    currentUserId: currentUserId,
                    editingPropertyId: propertyId
                )
            )
            
        case .profileView(let userId, let isOwnProfile):
            ProfileView(
                viewModel: ProfileViewModel(
                    repository: userProfileRepository,
                    userId: userId
                ),
                isOwnProfile: isOwnProfile
            )
            
        case .profileEdit:
            ProfileEditView(
                viewModel: ProfileViewModel(repository: userProfileRepository)
            )
            
        case .login:
            LoginView(
                viewModel: AuthViewModel(
                    authService: MockAuthenticationService(),
                    userProfileRepository: userProfileRepository
                )
            )
            
        case .registration:
            RegistrationView(
                viewModel: AuthViewModel(
                    authService: MockAuthenticationService(),
                    userProfileRepository: userProfileRepository
                )
            )
        }
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
        
        MainTabView(
            propertyRepository: propertyRepository,
            userProfileRepository: userProfileRepository,
            favoritesRepository: favoritesRepository,
            propertyListingService: propertyListingService
        )
        .environment(\.managedObjectContext, persistenceController.container.viewContext)
    }
}
