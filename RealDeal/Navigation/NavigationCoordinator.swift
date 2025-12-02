import SwiftUI
import Combine

/// Coordinator for managing complex navigation flows across the app
@available(iOS 17.0, macOS 12.0, *)
@MainActor
class NavigationCoordinator: ObservableObject {
    // MARK: - Published Properties
    
    /// Current selected tab
    @Published var selectedTab: AppTab = .browse
    
    /// Navigation paths for each tab
    @Published var browseNavigationPath = NavigationPath()
    @Published var mapNavigationPath = NavigationPath()
    @Published var favoritesNavigationPath = NavigationPath()
    @Published var myListingsNavigationPath = NavigationPath()
    @Published var profileNavigationPath = NavigationPath()
    
    // MARK: - Tab Definition
    
    enum AppTab: String, CaseIterable {
        case browse
        case map
        case favorites
        case myListings
        case profile
        
        var title: String {
            switch self {
            case .browse: return "Browse"
            case .map: return "Map"
            case .favorites: return "Favorites"
            case .myListings: return "My Listings"
            case .profile: return "Profile"
            }
        }
        
        var icon: String {
            switch self {
            case .browse: return "list.bullet"
            case .map: return "map"
            case .favorites: return "heart.fill"
            case .myListings: return "house.fill"
            case .profile: return "person.fill"
            }
        }
    }
    
    // MARK: - Navigation Destinations
    
    enum Destination: Hashable {
        case propertyDetail(propertyId: String)
        case propertyCreation
        case propertyEdit(propertyId: String)
        case profileView(userId: String, isOwnProfile: Bool)
        case profileEdit
        case login
        case registration
    }
    
    // MARK: - Navigation Methods
    
    /// Navigate to a property detail view from any tab
    func navigateToPropertyDetail(propertyId: String, from tab: AppTab? = nil) {
        let destination = Destination.propertyDetail(propertyId: propertyId)
        
        if let tab = tab {
            selectedTab = tab
        }
        
        switch selectedTab {
        case .browse:
            browseNavigationPath.append(destination)
        case .map:
            mapNavigationPath.append(destination)
        case .favorites:
            favoritesNavigationPath.append(destination)
        case .myListings:
            myListingsNavigationPath.append(destination)
        case .profile:
            profileNavigationPath.append(destination)
        }
    }
    
    /// Navigate to property creation
    func navigateToPropertyCreation() {
        selectedTab = .myListings
        myListingsNavigationPath.append(Destination.propertyCreation)
    }
    
    /// Navigate to property edit
    func navigateToPropertyEdit(propertyId: String) {
        selectedTab = .myListings
        myListingsNavigationPath.append(Destination.propertyEdit(propertyId: propertyId))
    }
    
    /// Navigate to a user profile
    func navigateToProfile(userId: String, isOwnProfile: Bool) {
        if isOwnProfile {
            selectedTab = .profile
        } else {
            let destination = Destination.profileView(userId: userId, isOwnProfile: false)
            
            switch selectedTab {
            case .browse:
                browseNavigationPath.append(destination)
            case .map:
                mapNavigationPath.append(destination)
            case .favorites:
                favoritesNavigationPath.append(destination)
            case .myListings:
                myListingsNavigationPath.append(destination)
            case .profile:
                profileNavigationPath.append(destination)
            }
        }
    }
    
    /// Navigate to profile edit
    func navigateToProfileEdit() {
        selectedTab = .profile
        profileNavigationPath.append(Destination.profileEdit)
    }
    
    /// Pop to root of current tab
    func popToRoot() {
        switch selectedTab {
        case .browse:
            browseNavigationPath = NavigationPath()
        case .map:
            mapNavigationPath = NavigationPath()
        case .favorites:
            favoritesNavigationPath = NavigationPath()
        case .myListings:
            myListingsNavigationPath = NavigationPath()
        case .profile:
            profileNavigationPath = NavigationPath()
        }
    }
    
    /// Pop to root of all tabs
    func popAllToRoot() {
        browseNavigationPath = NavigationPath()
        mapNavigationPath = NavigationPath()
        favoritesNavigationPath = NavigationPath()
        myListingsNavigationPath = NavigationPath()
        profileNavigationPath = NavigationPath()
    }
    
    /// Handle deep link URL
    func handleDeepLink(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return
        }
        
        // Expected format: realdeal://property/{propertyId}
        // or realdeal://profile/{userId}
        
        let pathComponents = components.path.split(separator: "/")
        
        guard pathComponents.count >= 2 else {
            return
        }
        
        let type = String(pathComponents[0])
        let id = String(pathComponents[1])
        
        switch type {
        case "property":
            navigateToPropertyDetail(propertyId: id, from: .browse)
        case "profile":
            let isOwnProfile = components.queryItems?.first(where: { $0.name == "own" })?.value == "true"
            navigateToProfile(userId: id, isOwnProfile: isOwnProfile)
        default:
            break
        }
    }
}
