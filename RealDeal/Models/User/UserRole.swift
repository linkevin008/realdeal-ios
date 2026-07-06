import Foundation

enum UserRole: String, Codable, CaseIterable {
    case buyer
    case homeowner  // Owner-listed — individual selling their own property

    var displayName: String {
        switch self {
        case .buyer: return "Buyer"
        case .homeowner: return "Owner"
        }
    }

    var canCreateListings: Bool {
        switch self {
        case .buyer: return false
        case .homeowner: return true
        }
    }
}
