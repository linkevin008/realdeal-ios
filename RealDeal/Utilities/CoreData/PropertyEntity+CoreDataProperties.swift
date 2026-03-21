import Foundation
import CoreData

extension PropertyEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<PropertyEntity> {
        return NSFetchRequest<PropertyEntity>(entityName: "PropertyEntity")
    }
    
    @NSManaged public var id: String
    @NSManaged public var addressStreet: String
    @NSManaged public var addressCity: String
    @NSManaged public var addressProvince: String
    @NSManaged public var addressPostalCode: String
    @NSManaged public var addressCountry: String
    @NSManaged public var price: NSDecimalNumber
    @NSManaged public var propertyType: String
    @NSManaged public var propertyDescription: String
    @NSManaged public var specBedrooms: Int32
    @NSManaged public var specBathrooms: Double
    @NSManaged public var specSquareFeet: Int32
    @NSManaged public var specLotSize: Double
    @NSManaged public var specYearBuilt: Int32
    @NSManaged public var imagesData: Data?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var currency: String
    @NSManaged public var source: String
    @NSManaged public var sellerId: String?
    @NSManaged public var status: String
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
}

extension PropertyEntity: Identifiable {
    
}
