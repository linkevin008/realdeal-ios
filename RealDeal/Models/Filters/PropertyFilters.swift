import Foundation

struct PropertyFilters: Codable, Equatable {
    var priceMin: Decimal?
    var priceMax: Decimal?
    var propertyTypes: Set<PropertyType>?
    var locationRadius: LocationRadius?
    var minBedrooms: Int?
    var minBathrooms: Double?
    var sources: Set<ListingSource>?
    var sellerId: String?
    
    init(
        priceMin: Decimal? = nil,
        priceMax: Decimal? = nil,
        propertyTypes: Set<PropertyType>? = nil,
        locationRadius: LocationRadius? = nil,
        minBedrooms: Int? = nil,
        minBathrooms: Double? = nil,
        sources: Set<ListingSource>? = nil,
        sellerId: String? = nil
    ) {
        self.priceMin = priceMin
        self.priceMax = priceMax
        self.propertyTypes = propertyTypes
        self.locationRadius = locationRadius
        self.minBedrooms = minBedrooms
        self.minBathrooms = minBathrooms
        self.sources = sources
        self.sellerId = sellerId
    }
}

struct LocationRadius: Codable, Equatable {
    var center: Coordinate
    var radiusInMiles: Double
}
