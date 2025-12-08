import Foundation

struct Favorite: Identifiable, Codable, Equatable {
    let id: String
    let userId: String
    let propertyId: String
    let savedAt: Date
    
    init(id: String = UUID().uuidString, userId: String, propertyId: String, savedAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.propertyId = propertyId
        self.savedAt = savedAt
    }
}
