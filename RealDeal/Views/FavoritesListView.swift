import SwiftUI

/// View displaying the user's favorite properties
@available(iOS 15.0, macOS 12.0, *)
struct FavoritesListView: View {
    @StateObject private var viewModel: FavoritesViewModel
    @State private var selectedProperty: Property?
    
    init(viewModel: FavoritesViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading favorites...")
                } else if let errorMessage = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .multilineTextAlignment(.center)
                        Button("Try Again") {
                            Task {
                                await viewModel.loadFavorites()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                } else if viewModel.favoriteProperties.isEmpty {
                    emptyStateView
                } else {
                    favoritesList
                }
            }
            .navigationTitle("Favorites")
            .refreshable {
                await viewModel.refreshFavorites()
            }
            .task {
                await viewModel.loadFavorites()
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.slash")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            Text("No Favorites Yet")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Properties you favorite will appear here")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private var favoritesList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.favoriteProperties) { property in
                    PropertyCardView(
                        property: property,
                        isFavorite: true,
                        onFavoriteToggle: {
                            Task {
                                await viewModel.removeFavorite(propertyId: property.id)
                            }
                        }
                    )
                }
            }
            .padding()
        }
    }
}

// MARK: - Preview

@available(iOS 15.0, macOS 12.0, *)
struct FavoritesListView_Previews: PreviewProvider {
    static var previews: some View {
        let mockLocalDataSource = LocalDataSource(persistenceController: PersistenceController.preview)
        let mockRemoteDataSource = MockRemoteDataSource()
        let favoritesRepository = FavoritesRepository(
            localDataSource: mockLocalDataSource,
            remoteDataSource: mockRemoteDataSource
        )
        let propertyRepository = PropertyRepository(
            localDataSource: mockLocalDataSource,
            remoteDataSource: mockRemoteDataSource
        )
        
        let viewModel = FavoritesViewModel(
            favoritesRepository: favoritesRepository,
            propertyRepository: propertyRepository,
            currentUserId: "user123"
        )
        
        FavoritesListView(viewModel: viewModel)
    }
}
