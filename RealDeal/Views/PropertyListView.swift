import SwiftUI

/// Main property browsing view with filtering and search
@available(iOS 17.0, macOS 13.0, *)
struct PropertyListView: View {
    @StateObject private var viewModel: PropertyListViewModel
    @State private var showFilters = false
    
    init(viewModel: PropertyListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ZStack {
            if viewModel.isLoading && viewModel.properties.isEmpty {
                PropertyListSkeleton(itemCount: 3)
                    .fadeInOnAppear()
            } else if let errorMessage = viewModel.errorMessage, viewModel.properties.isEmpty {
                EmptyStateView.networkError {
                    Task {
                        await viewModel.loadProperties()
                    }
                }
                .fadeInOnAppear()
            } else if viewModel.properties.isEmpty {
                EmptyStateView.noProperties {
                    Task {
                        await viewModel.loadProperties()
                    }
                }
                .fadeInOnAppear()
            } else {
                propertyListContent
            }
        }
        .navigationTitle("Browse Properties")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: { showFilters.toggle() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        if viewModel.hasActiveFilters {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 8, height: 8)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showFilters) {
            PropertyFiltersView(viewModel: viewModel)
        }
        .task {
            await viewModel.loadProperties()
        }
    }
    
    @available(iOS 17.0, macOS 13.0, *)
    private var propertyListContent: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(Array(viewModel.properties.enumerated()), id: \.element.id) { index, property in
                    NavigationLink(value: NavigationCoordinator.Destination.propertyDetail(property: property)) {
                        PropertyCardView(
                            property: property,
                            isFavorite: viewModel.isFavorite(propertyId: property.id),
                            onFavoriteToggle: {
                                Task {
                                    await viewModel.toggleFavorite(propertyId: property.id)
                                }
                            }
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .staggeredListAnimation(index: index)
                    .onAppear {
                        // Load more when reaching the last item
                        if property.id == viewModel.properties.last?.id {
                            Task {
                                await viewModel.loadMoreProperties()
                            }
                        }
                    }
                }
            }
            .padding()
            
            if viewModel.isLoading {
                LoadingIndicator(style: .inline, message: "Loading more...")
                    .padding()
            }
        }
        .refreshable {
            await viewModel.refreshProperties()
        }
        .errorBanner(error: $viewModel.error) {
            Task {
                await viewModel.retryLoadProperties()
            }
        }
        .successBanner(message: $viewModel.successMessage)
    }
}

/// Property card displaying key property details
@available(iOS 17.0, macOS 13.0, *)
struct PropertyCardView: View {
    let property: Property
    var isFavorite: Bool = false
    var onFavoriteToggle: (() -> Void)? = nil
    var onTap: (() -> Void)? = nil
    
    var body: some View {
        Button(action: {
            onTap?()
        }) {
            cardContent
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Property image with favorite button overlay
            ZStack(alignment: .topTrailing) {
                if let firstImage = property.images.first {
                    AsyncImage(url: firstImage.url) { phase in
                        switch phase {
                        case .empty:
                            ImageLoadingPlaceholder(height: 200)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .clipped()
                        case .failure:
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 200)
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.largeTitle)
                                        .foregroundColor(.gray)
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 200)
                        .overlay(
                            Image(systemName: "house")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                        )
                }
                
                // Favorite button overlay
                if let onFavoriteToggle = onFavoriteToggle {
                    FavoriteButton(
                        isFavorite: isFavorite,
                        action: onFavoriteToggle,
                        size: 24
                    )
                    .padding(8)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.9))
                            .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                    )
                    .padding(8)
                }
            }
            .cornerRadius(12)
            
            // Property details
            VStack(alignment: .leading, spacing: 8) {
                // Price
                Text(CurrencyFormatter.format(
                    property.price,
                    storageCurrency: property.currency,
                    displayCurrency: DisplayCurrencyPreference.shared.displayCurrency
                ))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                // Address
                Text(property.address.street)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("\(property.address.city), \(property.address.province) \(property.address.postalCode)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Specifications
                HStack(spacing: 16) {
                    if let bedrooms = property.specifications.bedrooms {
                        Label("\(bedrooms)", systemImage: "bed.double")
                            .font(.caption)
                    }
                    if let bathrooms = property.specifications.bathrooms {
                        Label(String(format: "%.1f", bathrooms), systemImage: "shower")
                            .font(.caption)
                    }
                    if let sqft = property.specifications.squareFeet {
                        Label("\(sqft) sqft", systemImage: "square")
                            .font(.caption)
                    }
                }
                .foregroundColor(.secondary)
                
                // Property type + owner-listed badge
                HStack(spacing: 6) {
                    Text(property.propertyType.rawValue.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(4)

                    if property.source == .userGenerated {
                        Text("Owner Listed")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.1))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        #if os(iOS)
        .background(Color(.systemBackground))
        #else
        .background(Color.white)
        #endif
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
}
