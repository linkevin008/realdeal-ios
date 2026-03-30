import SwiftUI

@available(iOS 17.0, *)
struct ContentView: View {
    // MARK: - Data layer (shared across the app)
    private let localDataSource: LocalDataSource
    private let remoteDataSource: APIRemoteDataSource
    private let propertyRepository: PropertyRepository
    private let userProfileRepository: UserProfileRepository
    private let favoritesRepository: FavoritesRepository
    private let propertyListingService: PropertyListingService

    // MARK: - Auth (owns the auth view model so user state flows to all tabs)
    @StateObject private var authViewModel: AuthViewModel

    init() {
        let localDS = LocalDataSource(persistenceController: PersistenceController.shared)
        let apiClient = APIClient(baseURL: URL(string: "http://localhost:8080")!)
        let remoteDS = APIRemoteDataSource(client: apiClient)

        let propRepo = PropertyRepository(
            localDataSource: localDS,
            remoteDataSource: remoteDS,
            creaDataSource: MockCREADataSource(simulateNetworkDelay: false)
        )
        let userRepo = UserProfileRepository(localDataSource: localDS, remoteDataSource: remoteDS)
        let favRepo  = FavoritesRepository(localDataSource: localDS, remoteDataSource: remoteDS)

        self.localDataSource        = localDS
        self.remoteDataSource       = remoteDS
        self.propertyRepository     = propRepo
        self.userProfileRepository  = userRepo
        self.favoritesRepository    = favRepo
        self.propertyListingService = PropertyListingService(repository: propRepo)

        let authService = AuthenticationService(
            backendAuth: APIAuthenticationService(client: apiClient),
            userProfileRepository: userRepo
        )
        _authViewModel = StateObject(wrappedValue: AuthViewModel(authService: authService))
    }

    var body: some View {
        MainTabView(
            authViewModel: authViewModel,
            propertyRepository: propertyRepository,
            userProfileRepository: userProfileRepository,
            favoritesRepository: favoritesRepository,
            propertyListingService: propertyListingService
        )
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
