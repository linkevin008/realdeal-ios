import SwiftUI

/// Main property browsing view with filtering and search
@available(iOS 15.0, macOS 12.0, *)
struct PropertyListView: View {
    @StateObject private var viewModel: PropertyListViewModel
    @State private var showFilters = false
    
    init(viewModel: PropertyListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading && viewModel.properties.isEmpty {
                    ProgressView("Loading properties...")
                } else if let errorMessage = viewModel.errorMessage, viewModel.properties.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        Button("Try Again") {
                            Task {
                                await viewModel.loadProperties()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else if viewModel.properties.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "house.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("No properties found")
                            .font(.headline)
                        Text("Try adjusting your filters")
                            .foregroundColor(.secondary)
                    }
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
    }
    
    private var propertyListContent: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.properties) { property in
                    PropertyCardView(
                        property: property,
                        isFavorite: viewModel.isFavorite(propertyId: property.id),
                        onFavoriteToggle: {
                            Task {
                                await viewModel.toggleFavorite(propertyId: property.id)
                            }
                        }
                    )
                    .onAppear {
                        // Load more when reaching the last item
                        if property.id == viewModel.properties.last?.id {
                            Task {
                                await viewModel.loadMoreProperties()
                            }
                        }
                    }
                }
                
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                }
            }
            .padding()
        }
        .refreshable {
            await viewModel.refreshProperties()
        }
    }
}

/// Property card displaying key property details
@available(iOS 15.0, macOS 12.0, *)
struct PropertyCardView: View {
    let property: Property
    var isFavorite: Bool = false
    var onFavoriteToggle: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Property image with favorite button overlay
            ZStack(alignment: .topTrailing) {
                if let firstImage = property.images.first {
                    AsyncImage(url: firstImage.url) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 200)
                                .overlay(ProgressView())
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
                Text(formatPrice(property.price))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                // Address
                Text(property.address.street)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("\(property.address.city), \(property.address.state) \(property.address.zipCode)")
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
                
                // Property type
                Text(property.propertyType.rawValue.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(4)
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
    
    private func formatPrice(_ price: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: price as NSDecimalNumber) ?? "$0"
    }
}
