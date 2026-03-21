#if canImport(UIKit)
import SwiftUI
import MapKit

/// Map view displaying property listings with markers and clustering
@available(iOS 15.0, macOS 12.0, *)
struct MapView: View {
    @StateObject private var viewModel: MapViewModel
    @StateObject private var locationManager: LocationManager
    @State private var showingFilters = false
    @State private var filterViewModel: PropertyListViewModel
    private let propertyRepository: PropertyRepositoryProtocol
    private let userProfileRepository: UserProfileRepositoryProtocol
    
    init(repository: PropertyRepositoryProtocol, userProfileRepository: UserProfileRepositoryProtocol) {
        self.propertyRepository = repository
        self.userProfileRepository = userProfileRepository
        let locationManager = LocationManager()
        _locationManager = StateObject(wrappedValue: locationManager)
        _viewModel = StateObject(wrappedValue: MapViewModel(
            repository: repository,
            locationManager: locationManager
        ))
        _filterViewModel = State(initialValue: PropertyListViewModel(repository: repository))
    }
    
    var body: some View {
        ZStack {
            // Map
            MapViewRepresentable(
                viewModel: viewModel,
                locationManager: locationManager
            )
            .ignoresSafeArea()
            
            // Top controls
            VStack {
                HStack {
                    Spacer()
                    
                    // Filter button
                    Button(action: { showingFilters = true }) {
                        Image(systemName: viewModel.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding()
                    
                    // Center on user location button
                    Button(action: { viewModel.centerOnUserLocation() }) {
                        Image(systemName: "location.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding(.trailing)
                }
                
                Spacer()
            }
            
            // Property preview card
            if let property = viewModel.selectedProperty {
                VStack {
                    Spacer()
                    PropertyPreviewCard(property: property, propertyRepository: propertyRepository, userProfileRepository: userProfileRepository) {
                        viewModel.deselectProperty()
                    }
                    .padding()
                }
            }
            
            // Loading indicator
            if viewModel.isLoading {
                LoadingIndicator(style: .overlay, message: "Loading properties...")
                    .fadeInOnAppear()
            }
        }
        .sheet(isPresented: $showingFilters) {
            PropertyFiltersView(viewModel: filterViewModel)
        }
        .task {
            await viewModel.loadProperties()
        }
        .onChange(of: filterViewModel.filters) { _, newFilters in
            viewModel.filters = newFilters
            Task {
                await viewModel.applyFilters()
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }
}
#endif

#if canImport(UIKit)
/// UIKit MapView wrapper for SwiftUI
@available(iOS 15.0, macOS 12.0, *)
struct MapViewRepresentable: UIViewRepresentable {
    @ObservedObject var viewModel: MapViewModel
    @ObservedObject var locationManager: LocationManager
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none
        
        // Register annotation views
        mapView.register(
            PropertyMarkerView.self,
            forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier
        )
        mapView.register(
            PropertyClusterView.self,
            forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier
        )
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update region
        if mapView.region.center.latitude != viewModel.region.center.latitude ||
           mapView.region.center.longitude != viewModel.region.center.longitude {
            mapView.setRegion(viewModel.region, animated: true)
        }
        
        // Update annotations
        let currentAnnotations = Set(mapView.annotations.compactMap { $0 as? PropertyAnnotation })
        let newAnnotations = Set(viewModel.annotations)
        
        let toRemove = currentAnnotations.subtracting(newAnnotations)
        let toAdd = newAnnotations.subtracting(currentAnnotations)
        
        mapView.removeAnnotations(Array(toRemove))
        mapView.addAnnotations(Array(toAdd))
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        let viewModel: MapViewModel
        
        init(viewModel: MapViewModel) {
            self.viewModel = viewModel
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let annotation = view.annotation as? PropertyAnnotation else { return }
            
            Task { @MainActor in
                viewModel.selectProperty(annotation.property)
            }
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            Task { @MainActor in
                await viewModel.updateVisibleAnnotations(for: mapView.region)
            }
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // Don't customize user location annotation
            if annotation is MKUserLocation {
                return nil
            }
            
            if let cluster = annotation as? MKClusterAnnotation {
                let view = mapView.dequeueReusableAnnotationView(
                    withIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier,
                    for: annotation
                ) as? PropertyClusterView ?? PropertyClusterView(annotation: annotation, reuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
                
                return view
            }
            
            if let propertyAnnotation = annotation as? PropertyAnnotation {
                let view = mapView.dequeueReusableAnnotationView(
                    withIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier,
                    for: annotation
                ) as? PropertyMarkerView ?? PropertyMarkerView(annotation: annotation, reuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
                
                view.clusteringIdentifier = MapViewModel.clusteringIdentifier
                return view
            }
            
            return nil
        }
    }
}
#endif

#if canImport(UIKit)
/// Custom marker view for individual properties
@available(iOS 15.0, macOS 12.0, *)
class PropertyMarkerView: MKMarkerAnnotationView {
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        
        markerTintColor = .systemBlue
        glyphImage = UIImage(systemName: "house.fill")
        displayPriority = .required
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Custom cluster view for grouped properties
@available(iOS 15.0, macOS 12.0, *)
class PropertyClusterView: MKMarkerAnnotationView {
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        
        markerTintColor = .systemPurple
        displayPriority = .required
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForDisplay() {
        super.prepareForDisplay()
        
        if let cluster = annotation as? MKClusterAnnotation {
            let count = cluster.memberAnnotations.count
            glyphText = "\(count)"
        }
    }
}

/// Property preview card shown when a marker is selected
@available(iOS 15.0, macOS 12.0, *)
struct PropertyPreviewCard: View {
    let property: Property
    let propertyRepository: PropertyRepositoryProtocol
    let userProfileRepository: UserProfileRepositoryProtocol
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationLink(destination: PropertyDetailView(viewModel: PropertyDetailViewModel(property: property, propertyRepository: propertyRepository, userProfileRepository: userProfileRepository))) {
            HStack(spacing: 12) {
                // Property image
                if let firstImage = property.images.first {
                    AsyncImage(url: firstImage.url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.3)
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "house.fill")
                                .foregroundColor(.gray)
                        )
                }
                
                // Property details
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatPrice(property.price))
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(property.address.street)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Text("\(property.address.city), \(property.address.province)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        if let bedrooms = property.specifications.bedrooms {
                            Label("\(bedrooms)", systemImage: "bed.double.fill")
                                .font(.caption)
                        }
                        if let bathrooms = property.specifications.bathrooms {
                            Label(String(format: "%.1f", bathrooms), systemImage: "shower.fill")
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 8)
        }
        .buttonStyle(PlainButtonStyle())
        .overlay(
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
                    .padding(8)
            }
            .offset(x: 8, y: -8),
            alignment: .topTrailing
        )
    }
    
    private func formatPrice(_ price: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: price as NSDecimalNumber) ?? "$\(price)"
    }
}
#endif
