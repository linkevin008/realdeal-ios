import SwiftUI

@available(iOS 17.0, macOS 12.0, *)
struct ContentView: View {
    // Initialize repositories and services
    private let persistenceController = PersistenceController.shared
    private let localDataSource: LocalDataSource
    private let mockRemoteDataSource: MockRemoteDataSource
    private let propertyRepository: PropertyRepository
    private let userProfileRepository: UserProfileRepository
    private let favoritesRepository: FavoritesRepository
    private let propertyListingService: PropertyListingService
    
    init() {
        // Set up data sources
        self.localDataSource = LocalDataSource(persistenceController: PersistenceController.shared)
        self.mockRemoteDataSource = MockRemoteDataSource()
        
        // Set up repositories
        self.propertyRepository = PropertyRepository(
            localDataSource: localDataSource,
            remoteDataSource: mockRemoteDataSource
        )
        self.userProfileRepository = UserProfileRepository(
            localDataSource: localDataSource,
            remoteDataSource: mockRemoteDataSource
        )
        self.favoritesRepository = FavoritesRepository(
            localDataSource: localDataSource,
            remoteDataSource: mockRemoteDataSource
        )
        
        // Set up services
        self.propertyListingService = PropertyListingService(
            repository: propertyRepository
        )
    }
    
    var body: some View {
        #if os(iOS)
        MainTabView(
            propertyRepository: propertyRepository,
            userProfileRepository: userProfileRepository,
            favoritesRepository: favoritesRepository,
            propertyListingService: propertyListingService
        )
        #else
        Text("Real Estate Listings - macOS version coming soon")
            .padding()
        #endif
    }
}

@available(iOS 17.0, macOS 12.0, *)
#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
