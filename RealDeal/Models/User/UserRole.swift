import Foundation

enum UserRole: String, Codable, CaseIterable {
    case buyer
    case agent      // Licensed real estate agent managing listings on behalf of clients
    case homeowner  // Owner-listed — individual selling their own property

    var displayName: String {
        switch self {
        case .buyer: return "Buyer"
        case .agent: return "Agent"
        case .homeowner: return "Owner"
        }
    }

    var canCreateListings: Bool {
        switch self {
        case .buyer: return false
        case .agent, .homeowner: return true
        }
    }

    var requiresLicenseNumber: Bool {
        return self == .agent
    }
}
