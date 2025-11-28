import Foundation

struct UserProfile: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var email: String
    var phoneNumber: String?
    var profilePhotoURL: URL?
    var role: UserRole
    var visibilitySettings: ProfileVisibility
    var createdAt: Date
    
    init(
        id: String = UUID().uuidString,
        name: String,
        email: String,
        phoneNumber: String? = nil,
        profilePhotoURL: URL? = nil,
        role: UserRole = .buyer,
        visibilitySettings: ProfileVisibility = ProfileVisibility(),
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.phoneNumber = phoneNumber
        self.profilePhotoURL = profilePhotoURL
        self.role = role
        self.visibilitySettings = visibilitySettings
        self.createdAt = createdAt
    }
}

enum UserRole: String, Codable {
    case buyer
    case seller
    case both
}

struct ProfileVisibility: Codable, Equatable {
    var showEmail: Bool
    var showPhone: Bool
    var showListings: Bool
    
    init(showEmail: Bool = true, showPhone: Bool = true, showListings: Bool = true) {
        self.showEmail = showEmail
        self.showPhone = showPhone
        self.showListings = showListings
    }
}
