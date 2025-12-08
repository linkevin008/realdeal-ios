import Foundation

struct Property: Identifiable, Codable, Equatable, Hashable {
    let id: String
    var address: Address
    var price: Decimal
    var propertyType: PropertyType
    var description: String
    var specifications: PropertySpecifications
    var images: [PropertyImage]
    var location: Coordinate
    var source: ListingSource
    var sellerId: String?
    var status: PropertyStatus
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: String = UUID().uuidString,
        address: Address,
        price: Decimal,
        propertyType: PropertyType,
        description: String,
        specifications: PropertySpecifications = PropertySpecifications(),
        images: [PropertyImage] = [],
        location: Coordinate,
        source: ListingSource = .userGenerated,
        sellerId: String? = nil,
        status: PropertyStatus = .active,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.address = address
        self.price = price
        self.propertyType = propertyType
        self.description = description
        self.specifications = specifications
        self.images = images
        self.location = location
        self.source = source
        self.sellerId = sellerId
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct Address: Codable, Equatable, Hashable {
    var street: String
    var city: String
    var state: String
    var zipCode: String?
    var postalCode: String?
    var country: String
}

struct PropertySpecifications: Codable, Equatable, Hashable {
    var bedrooms: Int?
    var bathrooms: Double?
    var squareFeet: Int?
    var lotSize: Double?
    var yearBuilt: Int?
}

struct PropertyImage: Codable, Equatable, Identifiable, Hashable {
    let id: String
    var url: URL
    var order: Int
    
    init(id: String = UUID().uuidString, url: URL, order: Int = 0) {
        self.id = id
        self.url = url
        self.order = order
    }
}

struct Coordinate: Codable, Equatable, Hashable {
    var latitude: Double
    var longitude: Double
}
