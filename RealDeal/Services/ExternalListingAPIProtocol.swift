import Foundation

struct SearchParameters: Codable {
    var location: String?
    var radius: Double?
    var minPrice: Decimal?
    var maxPrice: Decimal?
    var propertyTypes: [String]?
}

struct ExternalListing: Codable {
    let id: String
    let rawData: [String: Any]
    
    enum CodingKeys: String, CodingKey {
        case id
    }
    
    init(id: String, rawData: [String: Any]) {
        self.id = id
        self.rawData = rawData
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        rawData = [:]
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
    }
}

protocol ExternalListingAPIProtocol {
    func fetchListings(parameters: SearchParameters) async throws -> [ExternalListing]
    func normalizeToProperty(_ listing: ExternalListing) -> Property
}
