import Foundation
import CoreData

extension UserProfileEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserProfileEntity> {
        return NSFetchRequest<UserProfileEntity>(entityName: "UserProfileEntity")
    }
    
    @NSManaged public var id: String
    @NSManaged public var name: String
    @NSManaged public var email: String
    @NSManaged public var phoneNumber: String?
    @NSManaged public var profilePhotoURLString: String?
    @NSManaged public var role: String
    @NSManaged public var licenseNumber: String?
    @NSManaged public var visibilityShowEmail: Bool
    @NSManaged public var visibilityShowPhone: Bool
    @NSManaged public var visibilityShowListings: Bool
    @NSManaged public var createdAt: Date
}

extension UserProfileEntity: Identifiable {
    
}
