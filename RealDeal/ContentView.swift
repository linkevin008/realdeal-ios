import SwiftUI

@available(iOS 17.0, macOS 12.0, *)
struct ContentView: View {
    // MARK: - Data layer (shared across the app)
    private let localDataSource: LocalDataSource
    private let mockRemoteDataSource: MockRemoteDataSource
    private let propertyRepository: PropertyRepository
    private let userProfileRepository: UserProfileRepository
    private let favoritesRepository: FavoritesRepository
    private let propertyListingService: PropertyListingService

    // MARK: - Auth (owns the auth view model so user state flows to all tabs)
    @StateObject private var authViewModel: AuthViewModel

    init() {
        let localDS = LocalDataSource(persistenceController: PersistenceController.shared)
        let remoteDS = MockRemoteDataSource()

        let propRepo = PropertyRepository(
            localDataSource: localDS,
            remoteDataSource: remoteDS,
            creaDataSource: MockCREADataSource(simulateNetworkDelay: false)
        )
        let userRepo = UserProfileRepository(localDataSource: localDS, remoteDataSource: remoteDS)
        let favRepo  = FavoritesRepository(localDataSource: localDS, remoteDataSource: remoteDS)

        self.localDataSource        = localDS
        self.mockRemoteDataSource   = remoteDS
        self.propertyRepository     = propRepo
        self.userProfileRepository  = userRepo
        self.favoritesRepository    = favRepo
        self.propertyListingService = PropertyListingService(repository: propRepo)

        let authService = AuthenticationService(
            backendAuth: MockAuthenticationService(),
            userProfileRepository: userRepo
        )
        _authViewModel = StateObject(wrappedValue: AuthViewModel(authService: authService))
    }

    var body: some View {
        #if os(iOS)
        MainTabView(
            authViewModel: authViewModel,
            propertyRepository: propertyRepository,
            userProfileRepository: userProfileRepository,
            favoritesRepository: favoritesRepository,
            propertyListingService: propertyListingService
        )
        #else
        Text("RealDeal — macOS version coming soon")
            .padding()
        #endif
    }
}

@available(iOS 17.0, macOS 12.0, *)
#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
