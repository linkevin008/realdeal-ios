import Foundation
import MapKit

/// Custom annotation for displaying properties on the map
@available(iOS 15.0, macOS 12.0, *)
class PropertyAnnotation: NSObject, MKAnnotation {
    let property: Property
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: property.location.latitude,
            longitude: property.location.longitude
        )
    }
    
    var title: String? {
        property.address.street
    }
    
    var subtitle: String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        
        let priceString = formatter.string(from: property.price as NSDecimalNumber) ?? "$\(property.price)"
        return "\(priceString) • \(property.propertyType.rawValue.capitalized)"
    }
    
    init(property: Property) {
        self.property = property
        super.init()
    }
}


