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

    // MARK: - Dependencies

    private let propertyRepository: PropertyRepositoryProtocol

    // MARK: - Init

    init(propertyRepository: PropertyRepositoryProtocol) {
        self.propertyRepository = propertyRepository
    }

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
        case propertyDetail(property: Property)
        case propertyCreation
        case propertyEdit(property: Property)
        case profileView(userId: String, isOwnProfile: Bool)
        case profileEdit
        case login
        case registration
    }

    // MARK: - Navigation Methods

    /// Navigate to a property detail view from any tab
    func navigateToPropertyDetail(property: Property, from tab: AppTab? = nil) {
        let destination = Destination.propertyDetail(property: property)

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
    func navigateToPropertyEdit(property: Property) {
        selectedTab = .myListings
        myListingsNavigationPath.append(Destination.propertyEdit(property: property))
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

    // MARK: - Deep Linking

    /// Handle a deep link URL from either the custom scheme (realdeal://) or Universal Links (https://realdeal.app).
    ///
    /// Supported routes:
    ///   realdeal://property/{id}          → property detail
    ///   realdeal://profile/{id}           → seller profile
    ///   realdeal://search?type=...        → browse tab with filters (future)
    ///   realdeal://create-property        → new listing form
    func handleDeepLink(url: URL) {
        guard let parsed = DeepLinkHelper.parseDeepLink(url) else { return }

        switch parsed.type {
        case "property":
            guard let propertyId = parsed.id else { return }
            Task {
                if let property = try? await propertyRepository.getProperty(id: propertyId) {
                    navigateToPropertyDetail(property: property, from: .browse)
                }
            }

        case "profile":
            guard let userId = parsed.id else { return }
            let isOwn = parsed.parameters["own"] == "true"
            navigateToProfile(userId: userId, isOwnProfile: isOwn)

        case "create-property":
            navigateToPropertyCreation()

        case "search":
            selectedTab = .browse

        default:
            break
        }
    }
}
