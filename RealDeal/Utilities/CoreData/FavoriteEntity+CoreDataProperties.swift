import Foundation
import CoreData

extension FavoriteEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<FavoriteEntity> {
        return NSFetchRequest<FavoriteEntity>(entityName: "FavoriteEntity")
    }
    
    @NSManaged public var id: String
    @NSManaged public var userId: String
    @NSManaged public var propertyId: String
    @NSManaged public var savedAt: Date
}

extension FavoriteEntity: Identifiable {
    
}
