# Navigation System

This directory contains the navigation infrastructure for the RealDeal app, including tab-based navigation, deep linking, and navigation coordination.

## Components

### NavigationCoordinator

The `NavigationCoordinator` is the central hub for managing navigation across the app. It:

- Maintains navigation state for all tabs
- Provides methods for programmatic navigation
- Handles deep link routing
- Manages navigation paths for each tab

**Usage:**

```swift
// Access the coordinator from any view via environment
@EnvironmentObject var coordinator: NavigationCoordinator

// Navigate to a property detail
coordinator.navigateToPropertyDetail(propertyId: "property-123")

// Navigate to property creation
coordinator.navigateToPropertyCreation()

// Navigate to a user profile
coordinator.navigateToProfile(userId: "user-456", isOwnProfile: false)

// Pop to root of current tab
coordinator.popToRoot()
```

### MainTabView

The `MainTabView` is the root view of the app that sets up the tab structure with:

- Browse tab (property listings)
- Map tab (map view with property markers)
- Favorites tab (saved properties)
- My Listings tab (seller's properties)
- Profile tab (user profile)

Each tab has its own `NavigationStack` with independent navigation paths managed by the coordinator.

### DeepLinkHelper

The `DeepLinkHelper` provides utilities for:

- Generating deep link URLs
- Parsing incoming deep link URLs
- Creating shareable content with deep links

**URL Scheme:** `realdeal://`

**Supported Deep Links:**

- `realdeal://property/{propertyId}` - Navigate to property detail
- `realdeal://profile/{userId}?own=true` - Navigate to user profile
- `realdeal://create-property` - Navigate to property creation

**Example:**

```swift
// Generate a deep link URL
if let url = DeepLinkHelper.propertyDetailURL(propertyId: "property-123") {
    // Share or use the URL: realdeal://property/property-123
}

// Generate shareable text with deep link
let shareText = DeepLinkHelper.shareableText(for: property, includeURL: true)
```

## Navigation Flow

### Tab Navigation

Each tab maintains its own navigation stack, allowing users to navigate independently within each tab without losing their place when switching tabs.

```
TabView
├── Browse Tab (NavigationStack)
│   ├── PropertyListView
│   └── PropertyDetailView
├── Map Tab (NavigationStack)
│   ├── MapView
│   └── PropertyDetailView
├── Favorites Tab (NavigationStack)
│   ├── FavoritesListView
│   └── PropertyDetailView
├── My Listings Tab (NavigationStack)
│   ├── MyListingsView
│   ├── PropertyDetailView
│   ├── PropertyCreationView
│   └── PropertyEditView
└── Profile Tab (NavigationStack)
    ├── ProfileView
    └── ProfileEditView
```

### Deep Linking

Deep links are handled by the `NavigationCoordinator` via the `.onOpenURL` modifier in `MainTabView`. When a deep link is opened:

1. The URL is parsed to extract the destination type and parameters
2. The coordinator switches to the appropriate tab
3. The coordinator pushes the destination onto that tab's navigation stack

**Example Flow:**

```
User taps: realdeal://property/abc-123
    ↓
MainTabView receives URL via .onOpenURL
    ↓
NavigationCoordinator.handleDeepLink(url:)
    ↓
Coordinator switches to Browse tab
    ↓
Coordinator pushes PropertyDetailView(propertyId: "abc-123")
```

### Cross-Tab Navigation

The coordinator provides methods for navigating from any tab to any destination:

```swift
// From any tab, navigate to a property detail
// The coordinator will switch to the appropriate tab and push the view
coordinator.navigateToPropertyDetail(propertyId: "property-123", from: .browse)

// Navigate to property creation (always goes to My Listings tab)
coordinator.navigateToPropertyCreation()
```

## Destination Types

The `NavigationCoordinator.Destination` enum defines all possible navigation destinations:

- `.propertyDetail(propertyId:)` - View property details
- `.propertyCreation` - Create a new property listing
- `.propertyEdit(propertyId:)` - Edit an existing property
- `.profileView(userId:, isOwnProfile:)` - View a user profile
- `.profileEdit` - Edit the current user's profile
- `.login` - Login screen
- `.registration` - Registration screen

## Adding New Destinations

To add a new navigation destination:

1. Add a new case to `NavigationCoordinator.Destination` enum
2. Add a navigation method to `NavigationCoordinator` if needed
3. Add the view builder case in `MainTabView.destinationView(for:)`
4. Optionally add a deep link URL generator in `DeepLinkHelper`

**Example:**

```swift
// 1. Add to Destination enum
enum Destination: Hashable {
    // ... existing cases
    case settings
}

// 2. Add navigation method
func navigateToSettings() {
    selectedTab = .profile
    profileNavigationPath.append(Destination.settings)
}

// 3. Add view builder case
@ViewBuilder
private func destinationView(for destination: NavigationCoordinator.Destination) -> some View {
    switch destination {
    // ... existing cases
    case .settings:
        SettingsView()
    }
}

// 4. Add deep link support (optional)
static func settingsURL() -> URL? {
    var components = URLComponents()
    components.scheme = scheme
    components.path = "/settings"
    return components.url
}
```

## Testing Deep Links

### Simulator

Use the `xcrun simctl` command to test deep links in the simulator:

```bash
xcrun simctl openurl booted "realdeal://property/test-property-123"
```

### Device

1. Create a test HTML file with a link:
   ```html
   <a href="realdeal://property/test-property-123">Open Property</a>
   ```
2. Host it or email it to yourself
3. Tap the link on your device

### Notes App

1. Open Notes app
2. Type the deep link URL: `realdeal://property/test-property-123`
3. Tap the link

## Best Practices

1. **Use the Coordinator**: Always use the `NavigationCoordinator` for programmatic navigation instead of directly manipulating navigation paths
2. **Environment Object**: Access the coordinator via `@EnvironmentObject` in views that need navigation
3. **Deep Link Testing**: Test all deep links thoroughly on both simulator and device
4. **Navigation State**: The coordinator maintains navigation state, so avoid storing navigation state in individual views
5. **Tab Switching**: When navigating cross-tab, always specify the target tab to ensure consistent behavior

## Future Enhancements

- Universal Links support (https://realdeal.com/property/123)
- Navigation analytics tracking
- Navigation state persistence (restore navigation on app restart)
- Animated tab transitions
- Custom navigation transitions
