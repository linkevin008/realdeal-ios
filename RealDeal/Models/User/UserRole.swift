import Foundation

enum UserRole: String, Codable, CaseIterable {
    case buyer
    case agent      // Licensed real estate agent managing listings on behalf of clients
    case homeowner  // FSBO (For Sale By Owner) — individual listing their own property

    var displayName: String {
        switch self {
        case .buyer: return "Buyer"
        case .agent: return "Agent"
        case .homeowner: return "Homeowner (FSBO)"
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
