import SwiftUI

/// Generic empty state view component
@available(iOS 15.0, macOS 12.0, *)
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 64, weight: .light))
                .foregroundColor(.gray)
            
            // Text content
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            
            // Action button
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Specific empty states for different screens
@available(iOS 15.0, macOS 12.0, *)
extension EmptyStateView {
    
    /// Empty state for property listings
    static func noProperties(onRefresh: (() -> Void)? = nil) -> EmptyStateView {
        EmptyStateView(
            icon: "house.slash",
            title: "No Properties Found",
            message: "There are no properties matching your criteria. Try adjusting your filters or check back later.",
            actionTitle: onRefresh != nil ? "Refresh" : nil,
            action: onRefresh
        )
    }
    
    /// Empty state for favorites
    static func noFavorites(onBrowse: (() -> Void)? = nil) -> EmptyStateView {
        EmptyStateView(
            icon: "heart.slash",
            title: "No Favorites Yet",
            message: "Properties you favorite will appear here. Start browsing to find your dream home!",
            actionTitle: onBrowse != nil ? "Browse Properties" : nil,
            action: onBrowse
        )
    }
    
    /// Empty state for search results
    static func noSearchResults(searchTerm: String, onClearFilters: (() -> Void)? = nil) -> EmptyStateView {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "No Results Found",
            message: "We couldn't find any properties matching '\(searchTerm)'. Try different keywords or clear your filters.",
            actionTitle: onClearFilters != nil ? "Clear Filters" : nil,
            action: onClearFilters
        )
    }
    
    /// Empty state for seller listings
    static func noSellerListings(onCreateListing: (() -> Void)? = nil) -> EmptyStateView {
        EmptyStateView(
            icon: "plus.circle",
            title: "No Listings Yet",
            message: "You haven't created any property listings. Start by adding your first property to reach potential buyers.",
            actionTitle: onCreateListing != nil ? "Create Listing" : nil,
            action: onCreateListing
        )
    }
    
    /// Empty state for map view
    static func noMapProperties(onRefresh: (() -> Void)? = nil) -> EmptyStateView {
        EmptyStateView(
            icon: "map",
            title: "No Properties in Area",
            message: "There are no properties in the current map area. Try zooming out or moving to a different location.",
            actionTitle: onRefresh != nil ? "Refresh" : nil,
            action: onRefresh
        )
    }
    
    /// Empty state for network error
    static func networkError(onRetry: (() -> Void)? = nil) -> EmptyStateView {
        EmptyStateView(
            icon: "wifi.slash",
            title: "Connection Error",
            message: "Unable to load data. Please check your internet connection and try again.",
            actionTitle: onRetry != nil ? "Try Again" : nil,
            action: onRetry
        )
    }
    
    /// Empty state for offline mode
    static func offline(onRefresh: (() -> Void)? = nil) -> EmptyStateView {
        EmptyStateView(
            icon: "icloud.slash",
            title: "You're Offline",
            message: "Some features may not be available. Connect to the internet to see the latest properties.",
            actionTitle: onRefresh != nil ? "Refresh" : nil,
            action: onRefresh
        )
    }
    
    /// Empty state for profile not found
    static func profileNotFound(onCreate: (() -> Void)? = nil) -> EmptyStateView {
        EmptyStateView(
            icon: "person.crop.circle.badge.exclamationmark",
            title: "Profile Not Found",
            message: "We couldn't find your profile information. Create a new profile to get started.",
            actionTitle: onCreate != nil ? "Create Profile" : nil,
            action: onCreate
        )
    }
}

/// Compact empty state for smaller spaces
@available(iOS 15.0, macOS 12.0, *)
struct CompactEmptyStateView: View {
    let icon: String
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(.gray)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Previews

#Preview("Empty States") {
    TabView {
        EmptyStateView.noProperties()
            .tabItem {
                Label("No Properties", systemImage: "house")
            }
        
        EmptyStateView.noFavorites()
            .tabItem {
                Label("No Favorites", systemImage: "heart")
            }
        
        EmptyStateView.networkError()
            .tabItem {
                Label("Network Error", systemImage: "wifi.slash")
            }
    }
}

#Preview("Compact Empty State") {
    CompactEmptyStateView(
        icon: "magnifyingglass",
        message: "No results found"
    )
}