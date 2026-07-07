import Foundation

/// A one-off dated time window a seller posts on their listing for buyers to
/// request a viewing against. No recurrence — each slot is a single dated
/// occurrence. `booked` reflects whether an accepted request already holds it
/// (the backend computes this; it is not client-derived).
struct ViewingSlot: Codable, Identifiable, Equatable {
    let id: String
    let propertyId: String
    let startTime: Date
    let endTime: Date
    let booked: Bool
}
