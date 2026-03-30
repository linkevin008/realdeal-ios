import Foundation

@available(iOS 15.0, macOS 12.0, *)
final class APIRemoteDataSource: RemoteDataSourceProtocol {
    private let client: APIClient
    // Maps favorite.id → (userId, propertyId) so removeFavorite can call the right endpoint
    private var favoriteIndex: [String: (userId: String, propertyId: String)] = [:]

    init(client: APIClient) {
        self.client = client
    }

    // MARK: - Properties

    func fetchProperties(filters: PropertyFilters?) async throws -> [Property] {
        var queryItems: [URLQueryItem] = []
        if let f = filters {
            if let v = f.priceMin {
                queryItems.append(URLQueryItem(name: "price_min", value: "\(v)"))
            }
            if let v = f.priceMax {
                queryItems.append(URLQueryItem(name: "price_max", value: "\(v)"))
            }
            if let types = f.propertyTypes {
                types.forEach { queryItems.append(URLQueryItem(name: "type", value: $0.rawValue)) }
            }
            if let lr = f.locationRadius {
                queryItems.append(URLQueryItem(name: "lat", value: "\(lr.center.latitude)"))
                queryItems.append(URLQueryItem(name: "lon", value: "\(lr.center.longitude)"))
                queryItems.append(URLQueryItem(name: "radius_miles", value: "\(lr.radiusInMiles)"))
            }
            if let v = f.minBedrooms {
                queryItems.append(URLQueryItem(name: "bedrooms_min", value: "\(v)"))
            }
            if let v = f.minBathrooms {
                queryItems.append(URLQueryItem(name: "bathrooms_min", value: "\(v)"))
            }
            if let sources = f.sources {
                sources.forEach { queryItems.append(URLQueryItem(name: "source", value: $0.apiValue)) }
            }
            if let v = f.sellerId {
                queryItems.append(URLQueryItem(name: "seller_id", value: v))
            }
        }
        let envelope: ListEnvelope<APIProperty> = try await client.get(
            "api/v1/properties",
            queryItems: queryItems
        )
        return envelope.data.map { $0.asProperty() }
    }

    func getProperty(id: String) async throws -> Property? {
        let envelope: Envelope<APIProperty> = try await client.get("api/v1/properties/\(id)")
        return envelope.data.asProperty()
    }

    func createProperty(_ property: Property) async throws -> Property {
        let body = CreatePropertyBody(from: property)
        let envelope: Envelope<APIProperty> = try await client.post(
            "api/v1/properties",
            body: body,
            requiresAuth: true
        )
        return envelope.data.asProperty()
    }

    func updateProperty(_ property: Property) async throws {
        let body = UpdatePropertyBody(from: property)
        let _: Envelope<APIProperty> = try await client.put(
            "api/v1/properties/\(property.id)",
            body: body,
            requiresAuth: true
        )
    }

    func deleteProperty(id: String) async throws {
        try await client.delete("api/v1/properties/\(id)", requiresAuth: true)
    }

    // MARK: - Users

    func fetchUserProfile(id: String) async throws -> UserProfile {
        let envelope: Envelope<APIUser> = try await client.get(
            "api/v1/users/\(id)",
            requiresAuth: true
        )
        return UserProfile(apiUser: envelope.data)
    }

    func updateUserProfile(_ profile: UserProfile) async throws {
        let body = UpdateUserBody(from: profile)
        let _: Envelope<APIUser> = try await client.put(
            "api/v1/users/\(profile.id)",
            body: body,
            requiresAuth: true
        )
    }

    // MARK: - Favorites

    func fetchFavorites(userId: String) async throws -> [Favorite] {
        let envelope: ListEnvelope<APIFavorite> = try await client.get(
            "api/v1/users/\(userId)/favorites",
            requiresAuth: true
        )
        let favorites = envelope.data.map { $0.asFavorite() }
        favorites.forEach { favoriteIndex[$0.id] = (userId: $0.userId, propertyId: $0.propertyId) }
        return favorites
    }

    func addFavorite(_ favorite: Favorite) async throws {
        struct Body: Encodable { let propertyId: String }
        let _: Envelope<APIFavorite> = try await client.post(
            "api/v1/users/\(favorite.userId)/favorites",
            body: Body(propertyId: favorite.propertyId),
            requiresAuth: true
        )
        favoriteIndex[favorite.id] = (userId: favorite.userId, propertyId: favorite.propertyId)
    }

    func removeFavorite(id: String) async throws {
        guard let entry = favoriteIndex[id] else {
            // If not in cache, nothing to remove on remote
            return
        }
        try await client.delete(
            "api/v1/users/\(entry.userId)/favorites/\(entry.propertyId)",
            requiresAuth: true
        )
        favoriteIndex.removeValue(forKey: id)
    }

    // MARK: - Images (not supported by this backend)

    func uploadImage(_ imageData: Data, path: String) async throws -> URL {
        throw APIError.notSupported
    }

    func deleteImage(url: URL) async throws {
        throw APIError.notSupported
    }
}

// MARK: - Private DTOs

private struct Envelope<T: Decodable>: Decodable {
    let data: T
}

private struct ListEnvelope<T: Decodable>: Decodable {
    let data: [T]
}

private struct APIProperty: Decodable {
    let id: String
    let street: String
    let city: String
    let state: String
    let zipCode: String
    let country: String
    let price: Decimal
    let propertyType: String
    let description: String
    let bedrooms: Int?
    let bathrooms: Double?
    let squareFeet: Int?
    let lotSize: Double?
    let yearBuilt: Int?
    let latitude: Double
    let longitude: Double
    let source: String
    let sellerId: String?
    let status: String
    let createdAt: Date
    let updatedAt: Date
    let images: [APIPropertyImage]

    func asProperty() -> Property {
        Property(
            id: id,
            address: Address(street: street, city: city, province: state, postalCode: zipCode, country: country),
            price: price,
            propertyType: PropertyType(rawValue: propertyType) ?? .house,
            description: description,
            specifications: PropertySpecifications(
                bedrooms: bedrooms,
                bathrooms: bathrooms,
                squareFeet: squareFeet,
                lotSize: lotSize,
                yearBuilt: yearBuilt
            ),
            images: images.compactMap { $0.asPropertyImage() },
            location: Coordinate(latitude: latitude, longitude: longitude),
            source: ListingSource(apiValue: source),
            sellerId: sellerId,
            status: PropertyStatus(rawValue: status) ?? .active,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

private struct APIPropertyImage: Decodable {
    let id: String
    let url: String
    let order: Int

    func asPropertyImage() -> PropertyImage? {
        guard let imageURL = URL(string: url) else { return nil }
        return PropertyImage(id: id, url: imageURL, order: order)
    }
}

private struct APIUser: Decodable {
    let id: String
    let name: String
    let email: String
    let phoneNumber: String?
    let profilePhotoUrl: String?
    let role: String
    let showEmail: Bool
    let showPhone: Bool
    let showListings: Bool
    let createdAt: Date
}

private struct APIFavorite: Decodable {
    let id: String
    let userId: String
    let propertyId: String
    let savedAt: Date

    func asFavorite() -> Favorite {
        Favorite(id: id, userId: userId, propertyId: propertyId, savedAt: savedAt)
    }
}

// MARK: - Request Bodies

private struct CreatePropertyBody: Encodable {
    let street: String
    let city: String
    let state: String
    let zipCode: String
    let country: String
    let price: Decimal
    let propertyType: String
    let description: String
    let bedrooms: Int?
    let bathrooms: Double?
    let squareFeet: Int?
    let lotSize: Double?
    let yearBuilt: Int?
    let latitude: Double
    let longitude: Double
    let source: String
    let images: [ImageBody]

    struct ImageBody: Encodable { let url: String; let order: Int }

    init(from p: Property) {
        street = p.address.street
        city = p.address.city
        state = p.address.province
        zipCode = p.address.postalCode
        country = p.address.country
        price = p.price
        propertyType = p.propertyType.rawValue
        description = p.description
        bedrooms = p.specifications.bedrooms
        bathrooms = p.specifications.bathrooms
        squareFeet = p.specifications.squareFeet
        lotSize = p.specifications.lotSize
        yearBuilt = p.specifications.yearBuilt
        latitude = p.location.latitude
        longitude = p.location.longitude
        source = p.source.apiValue
        images = p.images.map { ImageBody(url: $0.url.absoluteString, order: $0.order) }
    }
}

private struct UpdatePropertyBody: Encodable {
    let street: String?
    let city: String?
    let state: String?
    let zipCode: String?
    let country: String?
    let price: Decimal?
    let propertyType: String?
    let description: String?
    let bedrooms: Int?
    let bathrooms: Double?
    let squareFeet: Int?
    let lotSize: Double?
    let yearBuilt: Int?
    let status: String?

    init(from p: Property) {
        street = p.address.street
        city = p.address.city
        state = p.address.province
        zipCode = p.address.postalCode
        country = p.address.country
        price = p.price
        propertyType = p.propertyType.rawValue
        description = p.description
        bedrooms = p.specifications.bedrooms
        bathrooms = p.specifications.bathrooms
        squareFeet = p.specifications.squareFeet
        lotSize = p.specifications.lotSize
        yearBuilt = p.specifications.yearBuilt
        status = p.status.rawValue
    }
}

private struct UpdateUserBody: Encodable {
    let name: String?
    let phoneNumber: String?
    let profilePhotoUrl: String?
    let role: String?
    let showEmail: Bool?
    let showPhone: Bool?
    let showListings: Bool?

    init(from profile: UserProfile) {
        name = profile.name
        phoneNumber = profile.phoneNumber
        profilePhotoUrl = profile.profilePhotoURL?.absoluteString
        role = profile.role.apiValue
        showEmail = profile.visibilitySettings.showEmail
        showPhone = profile.visibilitySettings.showPhone
        showListings = profile.visibilitySettings.showListings
    }
}

// MARK: - Model Mapping Helpers

private extension UserProfile {
    init(apiUser: APIUser) {
        self.init(
            id: apiUser.id,
            name: apiUser.name,
            email: apiUser.email,
            phoneNumber: apiUser.phoneNumber,
            profilePhotoURL: apiUser.profilePhotoUrl.flatMap(URL.init(string:)),
            role: UserRole(apiRole: apiUser.role),
            visibilitySettings: ProfileVisibility(
                showEmail: apiUser.showEmail,
                showPhone: apiUser.showPhone,
                showListings: apiUser.showListings
            ),
            createdAt: apiUser.createdAt
        )
    }
}

private extension UserRole {
    var apiValue: String {
        switch self {
        case .buyer: return "buyer"
        case .agent, .homeowner: return "seller"
        }
    }

    init(apiRole: String) {
        switch apiRole {
        case "buyer": self = .buyer
        default: self = .homeowner
        }
    }
}

private extension ListingSource {
    var apiValue: String {
        switch self {
        case .userGenerated: return "user_generated"
        case .mls: return "mls"
        case .zillow: return "zillow"
        case .realtor: return "realtor"
        case .crea, .fsbo, .other: return "other"
        }
    }

    init(apiValue: String) {
        switch apiValue {
        case "user_generated": self = .userGenerated
        case "mls": self = .mls
        case "zillow": self = .zillow
        case "realtor": self = .realtor
        default: self = .other
        }
    }
}
