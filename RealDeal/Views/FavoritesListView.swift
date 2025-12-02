import SwiftUI

/// View displaying the user's favorite properties
@available(iOS 17.0, macOS 13.0, *)
struct FavoritesListView: View {
    @StateObject private var viewModel: FavoritesViewModel
    @State private var selectedProperty: Property?
    
    init(viewModel: FavoritesViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                PropertyListSkeleton(itemCount: 2)
                    .fadeInOnAppear()
            } else if let errorMessage = viewModel.errorMessage {
                EmptyStateView.networkError {
                    Task {
                        await viewModel.loadFavorites()
                    }
                }
                .fadeInOnAppear()
            } else if viewModel.favoriteProperties.isEmpty {
                emptyStateView
                    .fadeInOnAppear()
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
    
    private var emptyStateView: some View {
        EmptyStateView.noFavorites()
    }
    
    @available(iOS 17.0, macOS 13.0, *)
    private var favoritesList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(Array(viewModel.favoriteProperties.enumerated()), id: \.element.id) { index, property in
                    NavigationLink(value: NavigationCoordinator.Destination.propertyDetail(property: property)) {
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
                    .buttonStyle(PlainButtonStyle())
                    .staggeredListAnimation(index: index)
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
