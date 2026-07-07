import Foundation

enum OfferStatus: String, Codable {
    case pending, accepted, rejected, withdrawn
}

struct Offer: Codable, Identifiable {
    let id: String
    let propertyId: String
    let buyerId: String
    let amount: Double
    let message: String?
    let status: OfferStatus
    let createdAt: Date
    let updatedAt: Date
    let property: Property?
    let buyer: UserProfile?
}
