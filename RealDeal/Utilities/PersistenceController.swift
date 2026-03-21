import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    
    /// Preview instance for SwiftUI previews and testing
    static let preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        return controller
    }()
    
    var container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        // Try to load the model from various bundle locations
        let managedObjectModel: NSManagedObjectModel
        
        if let modelURL = Bundle.main.url(forResource: "RealDeal", withExtension: "momd"),
           let model = NSManagedObjectModel(contentsOf: modelURL) {
            managedObjectModel = model
        } else {
            // Create model programmatically as fallback
            managedObjectModel = Self.createModel()
        }
        
        container = NSPersistentContainer(name: "RealDeal", managedObjectModel: managedObjectModel)
        
        container = NSPersistentContainer(name: "RealDeal", managedObjectModel: managedObjectModel)
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Configure migration options
            let description = container.persistentStoreDescriptions.first
            description?.shouldMigrateStoreAutomatically = true
            description?.shouldInferMappingModelAutomatically = true
            
            // Set model version identifier for future migrations
            description?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        }
        
        let containerRef = container
        container.loadPersistentStores { description, error in
            if let error = error {
                // In production, handle this more gracefully
                // For now, we'll log and attempt recovery
                print("Core Data store failed to load: \(error)")
                
                // Attempt to delete and recreate the store as a last resort
                if let storeURL = description.url {
                    try? FileManager.default.removeItem(at: storeURL)
                    
                    // Try loading again
                    containerRef.loadPersistentStores { _, secondError in
                        if let secondError = secondError {
                            fatalError("Failed to load Core Data stack after recovery attempt: \(secondError)")
                        }
                    }
                }
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Configure for better performance
        container.viewContext.undoManager = nil
        container.viewContext.shouldDeleteInaccessibleFaults = true
    }
    
    /// Creates a background context for performing operations off the main thread
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.undoManager = nil
        return context
    }
    
    /// Saves the view context if there are changes
    func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save context: \(error)")
            }
        }
    }
    
    /// Creates the Core Data model programmatically
    private static func createModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        
        // Create PropertyEntity
        let propertyEntity = NSEntityDescription()
        propertyEntity.name = "PropertyEntity"
        propertyEntity.managedObjectClassName = "PropertyEntity"
        
        var propertyAttributes: [NSAttributeDescription] = []
        
        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .stringAttributeType
        idAttr.isOptional = false
        propertyAttributes.append(idAttr)
        
        let addressStreetAttr = NSAttributeDescription()
        addressStreetAttr.name = "addressStreet"
        addressStreetAttr.attributeType = .stringAttributeType
        addressStreetAttr.isOptional = false
        propertyAttributes.append(addressStreetAttr)
        
        let addressCityAttr = NSAttributeDescription()
        addressCityAttr.name = "addressCity"
        addressCityAttr.attributeType = .stringAttributeType
        addressCityAttr.isOptional = false
        propertyAttributes.append(addressCityAttr)
        
        let addressProvinceAttr = NSAttributeDescription()
        addressProvinceAttr.name = "addressProvince"
        addressProvinceAttr.attributeType = .stringAttributeType
        addressProvinceAttr.isOptional = false
        propertyAttributes.append(addressProvinceAttr)
        
        let addressPostalCodeAttr = NSAttributeDescription()
        addressPostalCodeAttr.name = "addressPostalCode"
        addressPostalCodeAttr.attributeType = .stringAttributeType
        addressPostalCodeAttr.isOptional = false
        propertyAttributes.append(addressPostalCodeAttr)
        
        let addressCountryAttr = NSAttributeDescription()
        addressCountryAttr.name = "addressCountry"
        addressCountryAttr.attributeType = .stringAttributeType
        addressCountryAttr.isOptional = false
        propertyAttributes.append(addressCountryAttr)
        
        let priceAttr = NSAttributeDescription()
        priceAttr.name = "price"
        priceAttr.attributeType = .decimalAttributeType
        priceAttr.isOptional = false
        propertyAttributes.append(priceAttr)
        
        let propertyTypeAttr = NSAttributeDescription()
        propertyTypeAttr.name = "propertyType"
        propertyTypeAttr.attributeType = .stringAttributeType
        propertyTypeAttr.isOptional = false
        propertyAttributes.append(propertyTypeAttr)
        
        let propertyDescriptionAttr = NSAttributeDescription()
        propertyDescriptionAttr.name = "propertyDescription"
        propertyDescriptionAttr.attributeType = .stringAttributeType
        propertyDescriptionAttr.isOptional = false
        propertyAttributes.append(propertyDescriptionAttr)
        
        let specBedroomsAttr = NSAttributeDescription()
        specBedroomsAttr.name = "specBedrooms"
        specBedroomsAttr.attributeType = .integer32AttributeType
        specBedroomsAttr.isOptional = true
        propertyAttributes.append(specBedroomsAttr)
        
        let specBathroomsAttr = NSAttributeDescription()
        specBathroomsAttr.name = "specBathrooms"
        specBathroomsAttr.attributeType = .doubleAttributeType
        specBathroomsAttr.isOptional = true
        propertyAttributes.append(specBathroomsAttr)
        
        let specSquareFeetAttr = NSAttributeDescription()
        specSquareFeetAttr.name = "specSquareFeet"
        specSquareFeetAttr.attributeType = .integer32AttributeType
        specSquareFeetAttr.isOptional = true
        propertyAttributes.append(specSquareFeetAttr)
        
        let specLotSizeAttr = NSAttributeDescription()
        specLotSizeAttr.name = "specLotSize"
        specLotSizeAttr.attributeType = .doubleAttributeType
        specLotSizeAttr.isOptional = true
        propertyAttributes.append(specLotSizeAttr)
        
        let specYearBuiltAttr = NSAttributeDescription()
        specYearBuiltAttr.name = "specYearBuilt"
        specYearBuiltAttr.attributeType = .integer32AttributeType
        specYearBuiltAttr.isOptional = true
        propertyAttributes.append(specYearBuiltAttr)
        
        let imagesDataAttr = NSAttributeDescription()
        imagesDataAttr.name = "imagesData"
        imagesDataAttr.attributeType = .binaryDataAttributeType
        imagesDataAttr.isOptional = true
        propertyAttributes.append(imagesDataAttr)
        
        let latitudeAttr = NSAttributeDescription()
        latitudeAttr.name = "latitude"
        latitudeAttr.attributeType = .doubleAttributeType
        latitudeAttr.isOptional = false
        propertyAttributes.append(latitudeAttr)
        
        let longitudeAttr = NSAttributeDescription()
        longitudeAttr.name = "longitude"
        longitudeAttr.attributeType = .doubleAttributeType
        longitudeAttr.isOptional = false
        propertyAttributes.append(longitudeAttr)
        
        let sourceAttr = NSAttributeDescription()
        sourceAttr.name = "source"
        sourceAttr.attributeType = .stringAttributeType
        sourceAttr.isOptional = false
        propertyAttributes.append(sourceAttr)
        
        let sellerIdAttr = NSAttributeDescription()
        sellerIdAttr.name = "sellerId"
        sellerIdAttr.attributeType = .stringAttributeType
        sellerIdAttr.isOptional = true
        propertyAttributes.append(sellerIdAttr)
        
        let statusAttr = NSAttributeDescription()
        statusAttr.name = "status"
        statusAttr.attributeType = .stringAttributeType
        statusAttr.isOptional = false
        propertyAttributes.append(statusAttr)
        
        let createdAtAttr = NSAttributeDescription()
        createdAtAttr.name = "createdAt"
        createdAtAttr.attributeType = .dateAttributeType
        createdAtAttr.isOptional = false
        propertyAttributes.append(createdAtAttr)
        
        let updatedAtAttr = NSAttributeDescription()
        updatedAtAttr.name = "updatedAt"
        updatedAtAttr.attributeType = .dateAttributeType
        updatedAtAttr.isOptional = false
        propertyAttributes.append(updatedAtAttr)
        
        propertyEntity.properties = propertyAttributes
        
        // Create UserProfileEntity
        let userProfileEntity = NSEntityDescription()
        userProfileEntity.name = "UserProfileEntity"
        userProfileEntity.managedObjectClassName = "UserProfileEntity"
        
        var userProfileAttributes: [NSAttributeDescription] = []
        
        let userIdAttr = NSAttributeDescription()
        userIdAttr.name = "id"
        userIdAttr.attributeType = .stringAttributeType
        userIdAttr.isOptional = false
        userProfileAttributes.append(userIdAttr)
        
        let nameAttr = NSAttributeDescription()
        nameAttr.name = "name"
        nameAttr.attributeType = .stringAttributeType
        nameAttr.isOptional = false
        userProfileAttributes.append(nameAttr)
        
        let emailAttr = NSAttributeDescription()
        emailAttr.name = "email"
        emailAttr.attributeType = .stringAttributeType
        emailAttr.isOptional = false
        userProfileAttributes.append(emailAttr)
        
        let phoneNumberAttr = NSAttributeDescription()
        phoneNumberAttr.name = "phoneNumber"
        phoneNumberAttr.attributeType = .stringAttributeType
        phoneNumberAttr.isOptional = true
        userProfileAttributes.append(phoneNumberAttr)
        
        let profilePhotoURLStringAttr = NSAttributeDescription()
        profilePhotoURLStringAttr.name = "profilePhotoURLString"
        profilePhotoURLStringAttr.attributeType = .stringAttributeType
        profilePhotoURLStringAttr.isOptional = true
        userProfileAttributes.append(profilePhotoURLStringAttr)
        
        let roleAttr = NSAttributeDescription()
        roleAttr.name = "role"
        roleAttr.attributeType = .stringAttributeType
        roleAttr.isOptional = false
        userProfileAttributes.append(roleAttr)

        let licenseNumberAttr = NSAttributeDescription()
        licenseNumberAttr.name = "licenseNumber"
        licenseNumberAttr.attributeType = .stringAttributeType
        licenseNumberAttr.isOptional = true
        userProfileAttributes.append(licenseNumberAttr)

        let visibilityShowEmailAttr = NSAttributeDescription()
        visibilityShowEmailAttr.name = "visibilityShowEmail"
        visibilityShowEmailAttr.attributeType = .booleanAttributeType
        visibilityShowEmailAttr.isOptional = false
        userProfileAttributes.append(visibilityShowEmailAttr)
        
        let visibilityShowPhoneAttr = NSAttributeDescription()
        visibilityShowPhoneAttr.name = "visibilityShowPhone"
        visibilityShowPhoneAttr.attributeType = .booleanAttributeType
        visibilityShowPhoneAttr.isOptional = false
        userProfileAttributes.append(visibilityShowPhoneAttr)
        
        let visibilityShowListingsAttr = NSAttributeDescription()
        visibilityShowListingsAttr.name = "visibilityShowListings"
        visibilityShowListingsAttr.attributeType = .booleanAttributeType
        visibilityShowListingsAttr.isOptional = false
        userProfileAttributes.append(visibilityShowListingsAttr)
        
        let userCreatedAtAttr = NSAttributeDescription()
        userCreatedAtAttr.name = "createdAt"
        userCreatedAtAttr.attributeType = .dateAttributeType
        userCreatedAtAttr.isOptional = false
        userProfileAttributes.append(userCreatedAtAttr)
        
        userProfileEntity.properties = userProfileAttributes
        
        // Create FavoriteEntity
        let favoriteEntity = NSEntityDescription()
        favoriteEntity.name = "FavoriteEntity"
        favoriteEntity.managedObjectClassName = "FavoriteEntity"
        
        var favoriteAttributes: [NSAttributeDescription] = []
        
        let favIdAttr = NSAttributeDescription()
        favIdAttr.name = "id"
        favIdAttr.attributeType = .stringAttributeType
        favIdAttr.isOptional = false
        favoriteAttributes.append(favIdAttr)
        
        let favUserIdAttr = NSAttributeDescription()
        favUserIdAttr.name = "userId"
        favUserIdAttr.attributeType = .stringAttributeType
        favUserIdAttr.isOptional = false
        favoriteAttributes.append(favUserIdAttr)
        
        let favPropertyIdAttr = NSAttributeDescription()
        favPropertyIdAttr.name = "propertyId"
        favPropertyIdAttr.attributeType = .stringAttributeType
        favPropertyIdAttr.isOptional = false
        favoriteAttributes.append(favPropertyIdAttr)
        
        let savedAtAttr = NSAttributeDescription()
        savedAtAttr.name = "savedAt"
        savedAtAttr.attributeType = .dateAttributeType
        savedAtAttr.isOptional = false
        favoriteAttributes.append(savedAtAttr)
        
        favoriteEntity.properties = favoriteAttributes
        
        model.entities = [propertyEntity, userProfileEntity, favoriteEntity]
        
        return model
    }
}
