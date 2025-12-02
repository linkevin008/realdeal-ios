import SwiftUI
import MapKit

/// Property detail view displaying comprehensive property information
@available(iOS 15.0, macOS 12.0, *)
struct PropertyDetailView: View {
    @StateObject var viewModel: PropertyDetailViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Image Gallery
                if viewModel.hasImages {
                    ImageGalleryView(
                        images: viewModel.sortedImages,
                        onImageTap: { index in
                            viewModel.showFullScreenImage(at: index)
                        }
                    )
                    .frame(height: 300)
                } else {
                    PlaceholderImageView()
                        .frame(height: 300)
                }
                
                // Property Information
                VStack(alignment: .leading, spacing: 20) {
                    // Price, Address, and Favorite Button
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(viewModel.formattedPrice)
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text(viewModel.formattedAddress)
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        FavoriteButton(
                            isFavorite: viewModel.isFavorite,
                            action: {
                                Task {
                                    await viewModel.toggleFavorite()
                                }
                            },
                            size: 28
                        )
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    Divider()
                    
                    // Specifications
                    if !viewModel.formattedSpecifications.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Property Details")
                                .font(.headline)
                            
                            Text(viewModel.formattedSpecifications)
                                .font(.body)
                                .foregroundColor(.secondary)
                            
                            if let lotSize = viewModel.formattedLotSize {
                                Text("Lot Size: \(lotSize)")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            
                            if let yearBuilt = viewModel.formattedYearBuilt {
                                Text(yearBuilt)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text("Type: \(viewModel.formattedPropertyType)")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        
                        Divider()
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        
                        Text(viewModel.property.description)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal)
                    
                    Divider()
                    
                    // Map Location
                    MapLocationView(coordinate: viewModel.property.location)
                        .frame(height: 200)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    
                    Divider()
                    
                    // Timestamps
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.formattedCreatedDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(viewModel.formattedUpdatedDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    Divider()
                    
                    // Seller Information
                    SellerProfileView(
                        sellerProfile: viewModel.sellerProfile,
                        isLoading: viewModel.isLoadingProfile,
                        visibleEmail: viewModel.visibleSellerEmail,
                        visiblePhone: viewModel.visibleSellerPhone
                    )
                    .padding(.horizontal)
                    
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                }
                .padding(.bottom)
            }
        }
        .navigationTitle("Property Details")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .sheet(isPresented: $viewModel.isShowingFullScreenImage) {
            FullScreenImageViewer(
                images: viewModel.sortedImages,
                selectedIndex: $viewModel.selectedImageIndex,
                onNext: viewModel.nextImage,
                onPrevious: viewModel.previousImage
            )
        }
        .task {
            await viewModel.loadSellerProfile()
            await viewModel.checkFavoriteStatus()
        }
        .refreshable {
            await viewModel.refreshProperty()
            await viewModel.loadSellerProfile()
            await viewModel.checkFavoriteStatus()
        }
    }
}

// MARK: - Image Gallery View

@available(iOS 15.0, macOS 12.0, *)
struct ImageGalleryView: View {
    let images: [PropertyImage]
    let onImageTap: (Int) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(images.enumerated()), id: \.element.id) { index, image in
                    AsyncImage(url: image.url) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .overlay(
                                    VStack(spacing: 8) {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                        Text("Loading...")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                )
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            Image(systemName: "photo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(.gray)
                                .padding(40)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    #if os(iOS)
                    .frame(width: UIScreen.main.bounds.width, height: 300)
                    #else
                    .frame(width: 800, height: 300)
                    #endif
                    .clipped()
                    .onTapGesture {
                        onImageTap(index)
                    }
                }
            }
        }
        .frame(height: 300)
    }
}

// MARK: - Placeholder Image View

@available(iOS 15.0, macOS 12.0, *)
struct PlaceholderImageView: View {
    var body: some View {
        ZStack {
            Color.gray.opacity(0.2)
            Image(systemName: "house.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.gray)
                .frame(width: 100, height: 100)
        }
    }
}

// MARK: - Map Location View

@available(iOS 15.0, macOS 12.0, *)
struct MapLocationView: View {
    let coordinate: Coordinate
    
    @State private var region: MKCoordinateRegion
    
    init(coordinate: Coordinate) {
        self.coordinate = coordinate
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            ),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: [coordinate]) { coord in
            MapMarker(
                coordinate: CLLocationCoordinate2D(
                    latitude: coord.latitude,
                    longitude: coord.longitude
                ),
                tint: .red
            )
        }
        .disabled(true)
    }
}

// Make Coordinate conform to Identifiable for Map
extension Coordinate: Identifiable {
    var id: String {
        "\(latitude),\(longitude)"
    }
}

// MARK: - Seller Profile View

@available(iOS 15.0, macOS 12.0, *)
struct SellerProfileView: View {
    let sellerProfile: UserProfile?
    let isLoading: Bool
    let visibleEmail: String?
    let visiblePhone: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Seller Information")
                .font(.headline)
            
            if isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading seller info...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            } else if let profile = sellerProfile {
                HStack(spacing: 12) {
                    // Profile Photo
                    if let photoURL = profile.profilePhotoURL {
                        AsyncImage(url: photoURL) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure:
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .foregroundColor(.gray)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundColor(.gray)
                            .frame(width: 60, height: 60)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(profile.name)
                            .font(.headline)
                        
                        if let email = visibleEmail {
                            HStack(spacing: 4) {
                                Image(systemName: "envelope.fill")
                                    .font(.caption)
                                Text(email)
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }
                        
                        if let phone = visiblePhone {
                            HStack(spacing: 4) {
                                Image(systemName: "phone.fill")
                                    .font(.caption)
                                Text(phone)
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            } else {
                Text("Seller information not available")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Full Screen Image Viewer

@available(iOS 15.0, macOS 12.0, *)
struct FullScreenImageViewer: View {
    let images: [PropertyImage]
    @Binding var selectedIndex: Int
    let onNext: () -> Void
    let onPrevious: () -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                // Close button
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                
                Spacer()
                
                // Image with zoom
                TabView(selection: $selectedIndex) {
                    ForEach(Array(images.enumerated()), id: \.element.id) { index, image in
                        AsyncImage(url: image.url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .tint(.white)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .scaleEffect(scale)
                                    .gesture(
                                        MagnificationGesture()
                                            .onChanged { value in
                                                scale = lastScale * value
                                            }
                                            .onEnded { _ in
                                                lastScale = scale
                                                // Reset if zoomed out too much
                                                if scale < 1.0 {
                                                    withAnimation {
                                                        scale = 1.0
                                                        lastScale = 1.0
                                                    }
                                                }
                                                // Limit max zoom
                                                if scale > 4.0 {
                                                    withAnimation {
                                                        scale = 4.0
                                                        lastScale = 4.0
                                                    }
                                                }
                                            }
                                    )
                                    .onTapGesture(count: 2) {
                                        // Double tap to reset zoom
                                        withAnimation {
                                            scale = 1.0
                                            lastScale = 1.0
                                        }
                                    }
                            case .failure:
                                Image(systemName: "photo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .foregroundColor(.white)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .tag(index)
                    }
                }
                #if os(iOS)
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                #endif
                
                Spacer()
                
                // Navigation controls
                HStack(spacing: 40) {
                    Button(action: onPrevious) {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                    .disabled(selectedIndex == 0)
                    .opacity(selectedIndex == 0 ? 0.3 : 1.0)
                    
                    Text("\(selectedIndex + 1) of \(images.count)")
                        .foregroundColor(.white)
                        .font(.headline)
                    
                    Button(action: onNext) {
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                    .disabled(selectedIndex == images.count - 1)
                    .opacity(selectedIndex == images.count - 1 ? 0.3 : 1.0)
                }
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Preview

@available(iOS 15.0, macOS 12.0, *)
struct PropertyDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PropertyDetailView(
                viewModel: PropertyDetailViewModel(
                    property: Property(
                        address: Address(
                            street: "123 Main St",
                            city: "San Francisco",
                            state: "CA",
                            zipCode: "94102",
                            country: "USA"
                        ),
                        price: 1250000,
                        propertyType: .house,
                        description: "Beautiful Victorian home in the heart of San Francisco",
                        specifications: PropertySpecifications(
                            bedrooms: 3,
                            bathrooms: 2.5,
                            squareFeet: 2000,
                            lotSize: 0.15,
                            yearBuilt: 1920
                        ),
                        location: Coordinate(latitude: 37.7749, longitude: -122.4194),
                        sellerId: "seller123"
                    ),
                    propertyRepository: MockPropertyRepository(),
                    userProfileRepository: UserProfileRepository(
                        localDataSource: LocalDataSource(persistenceController: PersistenceController.preview),
                        remoteDataSource: MockRemoteDataSource()
                    )
                )
            )
        }
    }
}
