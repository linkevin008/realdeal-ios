import Foundation
import CoreLocation

protocol LocationServiceProtocol {
    var currentLocation: CLLocation? { get }
    func requestLocationPermission()
    func startUpdatingLocation()
    func stopUpdatingLocation()
}
