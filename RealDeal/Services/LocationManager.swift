import Foundation
import CoreLocation
import Combine

/// Manages location permissions and updates for the application
@available(iOS 15.0, macOS 12.0, *)
@MainActor
class LocationManager: NSObject, ObservableObject, LocationServiceProtocol {
    // MARK: - Published Properties
    
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var errorMessage: String?
    
    // MARK: - Properties
    
    private let locationManager: CLLocationManager
    
    // MARK: - Initialization
    
    override init() {
        self.locationManager = CLLocationManager()
        self.authorizationStatus = locationManager.authorizationStatus
        
        super.init()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 100 // Update every 100 meters
    }
    
    // MARK: - Public Methods
    
    /// Request location permission from the user
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    /// Start updating location
    func startUpdatingLocation() {
        #if os(iOS)
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            errorMessage = "Location permission not granted"
            return
        }
        #elseif os(macOS)
        guard authorizationStatus == .authorizedAlways else {
            errorMessage = "Location permission not granted"
            return
        }
        #endif
        
        locationManager.startUpdatingLocation()
    }
    
    /// Stop updating location
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    /// Check if location services are available
    var isLocationAvailable: Bool {
        #if os(iOS)
        return authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
        #elseif os(macOS)
        return authorizationStatus == .authorizedAlways
        #else
        return false
        #endif
    }
}

// MARK: - CLLocationManagerDelegate

@available(iOS 15.0, macOS 12.0, *)
extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.last else { return }
            self.currentLocation = location
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.errorMessage = "Failed to get location: \(error.localizedDescription)"
        }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
            
            // Automatically start updating if authorized
            #if os(iOS)
            if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
                self.startUpdatingLocation()
            }
            #elseif os(macOS)
            if manager.authorizationStatus == .authorizedAlways {
                self.startUpdatingLocation()
            }
            #endif
        }
    }
}
