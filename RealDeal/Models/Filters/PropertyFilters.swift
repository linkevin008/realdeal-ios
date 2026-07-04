import Foundation

struct PropertyFilters: Codable, Equatable {
    /// Free-text search across street, city, and description (server-side via
    /// the lookup service's `q` parameter).
    var searchText: String?
    var priceMin: Decimal?
    var priceMax: Decimal?
    var propertyTypes: Set<PropertyType>?
    var locationRadius: LocationRadius?
    var minBedrooms: Int?
    var minBathrooms: Double?
    var sources: Set<ListingSource>?
    var sellerId: String?
    
    init(
        searchText: String? = nil,
        priceMin: Decimal? = nil,
        priceMax: Decimal? = nil,
        propertyTypes: Set<PropertyType>? = nil,
        locationRadius: LocationRadius? = nil,
        minBedrooms: Int? = nil,
        minBathrooms: Double? = nil,
        sources: Set<ListingSource>? = nil,
        sellerId: String? = nil
    ) {
        self.searchText = searchText
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
