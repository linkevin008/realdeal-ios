import Foundation
import CoreData

@available(iOS 15.0, macOS 12.0, *)
class LocalDataSource: LocalDataSourceProtocol {
    private let persistenceController: PersistenceController
    
    private var context: NSManagedObjectContext {
        persistenceController.container.viewContext
    }
    
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }
    
    // MARK: - Properties
    
    func fetchProperties(filters: PropertyFilters?) async throws -> [Property] {
        return try await context.perform {
            let request = PropertyEntity.fetchRequest()
            
            // Build predicate based on filters
            var predicates: [NSPredicate] = []
            
            if let filters = filters {
                // Status filter - always exclude deleted and sold (sold properties should not appear in buyer searches)
                predicates.append(NSPredicate(format: "status != %@ AND status != %@", 
                                             PropertyStatus.deleted.rawValue, 
                                             PropertyStatus.sold.rawValue))
                
                // Price range filter
                if let priceMin = filters.priceMin {
                    predicates.append(NSPredicate(format: "price >= %@", priceMin as NSDecimalNumber))
                }
                if let priceMax = filters.priceMax {
                    predicates.append(NSPredicate(format: "price <= %@", priceMax as NSDecimalNumber))
                }
                
                // Property type filter
                if let propertyTypes = filters.propertyTypes, !propertyTypes.isEmpty {
                    let typeStrings = propertyTypes.map { $0.rawValue }
                    predicates.append(NSPredicate(format: "propertyType IN %@", typeStrings))
                }
                
                // Bedrooms filter
                if let minBedrooms = filters.minBedrooms {
                    predicates.append(NSPredicate(format: "specBedrooms >= %d", minBedrooms))
                }
                
                // Bathrooms filter
                if let minBathrooms = filters.minBathrooms {
                    predicates.append(NSPredicate(format: "specBathrooms >= %f", minBathrooms))
                }
                
                // Source filter
                if let sources = filters.sources, !sources.isEmpty {
                    let sourceStrings = sources.map { $0.rawValue }
                    predicates.append(NSPredicate(format: "source IN %@", sourceStrings))
                }
                
                // Seller ID filter
                if let sellerId = filters.sellerId {
                    predicates.append(NSPredicate(format: "sellerId == %@", sellerId))
                }
                
                // Location radius filter
                if let locationRadius = filters.locationRadius {
                    // Calculate bounding box for efficiency
                    let center = locationRadius.center
                    let radiusInDegrees = locationRadius.radiusInMiles / 69.0 // Approximate miles to degrees
                    
                    let minLat = center.latitude - radiusInDegrees
                    let maxLat = center.latitude + radiusInDegrees
                    let minLon = center.longitude - radiusInDegrees
                    let maxLon = center.longitude + radiusInDegrees
                    
                    predicates.append(NSPredicate(format: "latitude >= %f AND latitude <= %f AND longitude >= %f AND longitude <= %f",
                                                 minLat, maxLat, minLon, maxLon))
                }
            } else {
                // Default: exclude deleted and sold properties (sold properties should not appear in buyer searches)
                predicates.append(NSPredicate(format: "status != %@ AND status != %@", 
                                             PropertyStatus.deleted.rawValue, 
                                             PropertyStatus.sold.rawValue))
            }
            
            if !predicates.isEmpty {
                request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            }
            
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            
            let entities = try self.context.fetch(request)
            var properties = entities.compactMap { try? self.mapToProperty($0) }
            
            // Apply location radius filter with precise distance calculation
            if let locationRadius = filters?.locationRadius {
                properties = properties.filter { property in
                    let distance = GeoUtils.distance(
                        from: locationRadius.center,
                        to: property.location
                    )
                    return distance <= locationRadius.radiusInMiles
                }
            }
            
            return properties
        }
    }
    
    func saveProperty(_ property: Property) async throws {
        try await context.perform {
            let request = PropertyEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", property.id)
            
            let entity: PropertyEntity
            if let existingEntity = try self.context.fetch(request).first {
                entity = existingEntity
            } else {
                entity = PropertyEntity(context: self.context)
                entity.id = property.id
            }
            
            self.mapToEntity(property: property, entity: entity)
            
            try self.context.save()
        }
    }
    
    func saveProperties(_ properties: [Property]) async throws {
        try await context.perform {
            for property in properties {
                let request = PropertyEntity.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", property.id)
                
                let entity: PropertyEntity
                if let existingEntity = try self.context.fetch(request).first {
                    entity = existingEntity
                } else {
                    entity = PropertyEntity(context: self.context)
                    entity.id = property.id
                }
                
                self.mapToEntity(property: property, entity: entity)
            }
            
            try self.context.save()
        }
    }
    
    func deleteProperty(id: String) async throws {
        try await context.perform {
            let request = PropertyEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id)
            
            if let entity = try self.context.fetch(request).first {
                self.context.delete(entity)
                try self.context.save()
            }
        }
    }
    
    func getProperty(id: String) async throws -> Property? {
        return try await context.perform {
            let request = PropertyEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id)
            
            guard let entity = try self.context.fetch(request).first else {
                return nil
            }
            
            return try self.mapToProperty(entity)
        }
    }
    
    // MARK: - User Profiles
    
    func saveUserProfile(_ profile: UserProfile) async throws {
        try await context.perform {
            let request = UserProfileEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", profile.id)
            
            let entity: UserProfileEntity
            if let existingEntity = try self.context.fetch(request).first {
                entity = existingEntity
            } else {
                entity = UserProfileEntity(context: self.context)
                entity.id = profile.id
            }
            
            self.mapToEntity(profile: profile, entity: entity)
            
            try self.context.save()
        }
    }
    
    func getUserProfile(id: String) async throws -> UserProfile? {
        return try await context.perform {
            let request = UserProfileEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id)
            
            guard let entity = try self.context.fetch(request).first else {
                return nil
            }
            
            return try self.mapToProfile(entity)
        }
    }
    
    func deleteUserProfile(id: String) async throws {
        try await context.perform {
            let request = UserProfileEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id)
            
            if let entity = try self.context.fetch(request).first {
                self.context.delete(entity)
                try self.context.save()
            }
        }
    }
    
    // MARK: - Favorites
    
    func saveFavorite(_ favorite: Favorite) async throws {
        try await context.perform {
            let request = FavoriteEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", favorite.id)
            
            let entity: FavoriteEntity
            if let existingEntity = try self.context.fetch(request).first {
                entity = existingEntity
            } else {
                entity = FavoriteEntity(context: self.context)
                entity.id = favorite.id
            }
            
            entity.userId = favorite.userId
            entity.propertyId = favorite.propertyId
            entity.savedAt = favorite.savedAt
            
            try self.context.save()
        }
    }
    
    func getFavorites(userId: String) async throws -> [Favorite] {
        return try await context.perform {
            let request = FavoriteEntity.fetchRequest()
            request.predicate = NSPredicate(format: "userId == %@", userId)
            request.sortDescriptors = [NSSortDescriptor(key: "savedAt", ascending: false)]
            
            let entities = try self.context.fetch(request)
            return entities.map { entity in
                Favorite(
                    id: entity.id,
                    userId: entity.userId,
                    propertyId: entity.propertyId,
                    savedAt: entity.savedAt
                )
            }
        }
    }
    
    func deleteFavorite(id: String) async throws {
        try await context.perform {
            let request = FavoriteEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id)
            
            if let entity = try self.context.fetch(request).first {
                self.context.delete(entity)
                try self.context.save()
            }
        }
    }
    
    func isFavorite(propertyId: String, userId: String) async throws -> Bool {
        return try await context.perform {
            let request = FavoriteEntity.fetchRequest()
            request.predicate = NSPredicate(format: "userId == %@ AND propertyId == %@", userId, propertyId)
            request.fetchLimit = 1
            
            let count = try self.context.count(for: request)
            return count > 0
        }
    }
    
    func deleteFavoritesByPropertyId(propertyId: String) async throws {
        try await context.perform {
            let request = FavoriteEntity.fetchRequest()
            request.predicate = NSPredicate(format: "propertyId == %@", propertyId)
            
            let entities = try self.context.fetch(request)
            for entity in entities {
                self.context.delete(entity)
            }
            
            if !entities.isEmpty {
                try self.context.save()
            }
        }
    }
    
    // MARK: - Mapping Helpers
    
    private func mapToProperty(_ entity: PropertyEntity) throws -> Property {
        let address = Address(
            street: entity.addressStreet,
            city: entity.addressCity,
            province: entity.addressProvince,
            postalCode: entity.addressPostalCode,
            country: entity.addressCountry
        )
        
        let specifications = PropertySpecifications(
            bedrooms: entity.specBedrooms > 0 ? Int(entity.specBedrooms) : nil,
            bathrooms: entity.specBathrooms > 0 ? entity.specBathrooms : nil,
            squareFeet: entity.specSquareFeet > 0 ? Int(entity.specSquareFeet) : nil,
            lotSize: entity.specLotSize > 0 ? entity.specLotSize : nil,
            yearBuilt: entity.specYearBuilt > 0 ? Int(entity.specYearBuilt) : nil
        )
        
        var images: [PropertyImage] = []
        if let imagesData = entity.imagesData {
            images = (try? JSONDecoder().decode([PropertyImage].self, from: imagesData)) ?? []
        }
        
        let location = Coordinate(
            latitude: entity.latitude,
            longitude: entity.longitude
        )
        
        guard let propertyType = PropertyType(rawValue: entity.propertyType),
              let source = ListingSource(rawValue: entity.source),
              let status = PropertyStatus(rawValue: entity.status) else {
            throw NSError(domain: "LocalDataSource", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid enum value"])
        }
        
        return Property(
            id: entity.id,
            address: address,
            price: entity.price as Decimal,
            currency: entity.currency.isEmpty ? "CAD" : entity.currency,
            propertyType: propertyType,
            description: entity.propertyDescription,
            specifications: specifications,
            images: images,
            location: location,
            source: source,
            sellerId: entity.sellerId,
            status: status,
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt
        )
    }
    
    private func mapToEntity(property: Property, entity: PropertyEntity) {
        entity.addressStreet = property.address.street
        entity.addressCity = property.address.city
        entity.addressProvince = property.address.province
        entity.addressPostalCode = property.address.postalCode
        entity.addressCountry = property.address.country
        entity.price = property.price as NSDecimalNumber
        entity.currency = property.currency
        entity.propertyType = property.propertyType.rawValue
        entity.propertyDescription = property.description
        entity.specBedrooms = Int32(property.specifications.bedrooms ?? 0)
        entity.specBathrooms = property.specifications.bathrooms ?? 0
        entity.specSquareFeet = Int32(property.specifications.squareFeet ?? 0)
        entity.specLotSize = property.specifications.lotSize ?? 0
        entity.specYearBuilt = Int32(property.specifications.yearBuilt ?? 0)
        entity.imagesData = try? JSONEncoder().encode(property.images)
        entity.latitude = property.location.latitude
        entity.longitude = property.location.longitude
        entity.source = property.source.rawValue
        entity.sellerId = property.sellerId
        entity.status = property.status.rawValue
        entity.createdAt = property.createdAt
        entity.updatedAt = property.updatedAt
    }
    
    private func mapToProfile(_ entity: UserProfileEntity) throws -> UserProfile {
        guard let role = UserRole(rawValue: entity.role) else {
            throw NSError(domain: "LocalDataSource", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid role value"])
        }
        
        let visibility = ProfileVisibility(
            showEmail: entity.visibilityShowEmail,
            showPhone: entity.visibilityShowPhone,
            showListings: entity.visibilityShowListings
        )
        
        let profilePhotoURL: URL?
        if let urlString = entity.profilePhotoURLString {
            profilePhotoURL = URL(string: urlString)
        } else {
            profilePhotoURL = nil
        }
        
        return UserProfile(
            id: entity.id,
            name: entity.name,
            email: entity.email,
            phoneNumber: entity.phoneNumber,
            profilePhotoURL: profilePhotoURL,
            role: role,
            visibilitySettings: visibility,
            createdAt: entity.createdAt
        )
    }

    private func mapToEntity(profile: UserProfile, entity: UserProfileEntity) {
        entity.name = profile.name
        entity.email = profile.email
        entity.phoneNumber = profile.phoneNumber
        entity.profilePhotoURLString = profile.profilePhotoURL?.absoluteString
        entity.role = profile.role.rawValue
        entity.visibilityShowEmail = profile.visibilitySettings.showEmail
        entity.visibilityShowPhone = profile.visibilitySettings.showPhone
        entity.visibilityShowListings = profile.visibilitySettings.showListings
        entity.createdAt = profile.createdAt
    }
    
}
