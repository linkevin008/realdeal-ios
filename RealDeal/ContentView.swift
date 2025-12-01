import SwiftUI

@available(iOS 17.0, macOS 12.0, *)
struct ContentView: View {
    // Initialize repositories
    private let persistenceController = PersistenceController.shared
    private let localDataSource: LocalDataSource
    private let mockRemoteDataSource: MockRemoteDataSource
    private let propertyRepository: PropertyRepository
    private let userProfileRepository: UserProfileRepository
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
        
        // Set up services
        self.propertyListingService = PropertyListingService(
            repository: propertyRepository
        )
    }
    
    var body: some View {
        #if os(iOS)
        TabView {
            // Browse Tab
            NavigationStack {
                PropertyListView(viewModel: PropertyListViewModel(repository: propertyRepository))
            }
            .tabItem {
                Label("Browse", systemImage: "list.bullet")
            }
            
            // Map Tab
            NavigationStack {
                MapView(repository: propertyRepository, userProfileRepository: userProfileRepository)
            }
            .tabItem {
                Label("Map", systemImage: "map")
            }
            
            // My Listings Tab
            NavigationStack {
                MyListingsView(viewModel: MyListingsViewModel(
                    service: propertyListingService,
                    currentUserId: "demo-user-id"  // TODO: Replace with actual user ID from auth
                ))
            }
            .tabItem {
                Label("My Listings", systemImage: "house.fill")
            }
            
            // Profile Tab
            NavigationStack {
                ProfileView(viewModel: ProfileViewModel(repository: userProfileRepository), isOwnProfile: true)
            }
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }
        }
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
