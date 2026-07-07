import Foundation

enum ViewingRequestStatus: String, Codable {
    case pending, accepted, declined, cancelled
}

/// A buyer's request to view a property during a specific slot. The seller
/// approves (pending -> accepted/declined); only one buyer per slot may hold
/// an accepted request at a time. Buyers may cancel while pending or accepted.
struct ViewingRequest: Codable, Identifiable, Equatable {
    let id: String
    let slotId: String
    let propertyId: String
    let buyerId: String
    let message: String?
    let status: ViewingRequestStatus
    let createdAt: Date
    let slot: ViewingSlot?
    let buyer: UserProfile?
    let property: Property?

    init(
        id: String,
        slotId: String,
        propertyId: String,
        buyerId: String,
        message: String? = nil,
        status: ViewingRequestStatus,
        createdAt: Date,
        slot: ViewingSlot? = nil,
        buyer: UserProfile? = nil,
        property: Property? = nil
    ) {
        self.id = id
        self.slotId = slotId
        self.propertyId = propertyId
        self.buyerId = buyerId
        self.message = message
        self.status = status
        self.createdAt = createdAt
        self.slot = slot
        self.buyer = buyer
        self.property = property
    }
}
