import SwiftUI

/// Central import file for all UI components and styles
/// This file provides easy access to all custom UI components

// The UI components are defined in this module, so no need for imports
// They are available directly

// All UI components are defined in this module and available directly

/// Quick access to commonly used UI components
@available(iOS 15.0, macOS 12.0, *)
extension View {
    // MARK: - Loading States
    
    /// Show skeleton loading for property cards
    static func propertyCardSkeleton() -> some View {
        PropertyCardSkeleton()
    }
    
    /// Show skeleton loading for property lists
    static func propertyListSkeleton(itemCount: Int = 3) -> some View {
        PropertyListSkeleton(itemCount: itemCount)
    }
    
    /// Show skeleton loading for profiles
    static func profileSkeleton() -> some View {
        ProfileSkeleton()
    }
    
    // MARK: - Empty States
    
    /// Show empty state for no properties
    static func noPropertiesEmpty(onRefresh: (() -> Void)? = nil) -> some View {
        EmptyStateView.noProperties(onRefresh: onRefresh)
    }
    
    /// Show empty state for no favorites
    static func noFavoritesEmpty(onBrowse: (() -> Void)? = nil) -> some View {
        EmptyStateView.noFavorites(onBrowse: onBrowse)
    }
    
    /// Show empty state for network error
    static func networkErrorEmpty(onRetry: (() -> Void)? = nil) -> some View {
        EmptyStateView.networkError(onRetry: onRetry)
    }
    
    // MARK: - Loading Indicators
    
    /// Standard loading indicator
    static func standardLoading(message: String? = nil) -> some View {
        LoadingIndicator(style: .standard, message: message)
    }
    
    /// Large loading indicator
    static func largeLoading(message: String? = nil) -> some View {
        LoadingIndicator(style: .large, message: message)
    }
    
    /// Overlay loading indicator
    static func overlayLoading(message: String? = nil) -> some View {
        LoadingIndicator(style: .overlay, message: message)
    }
    
    /// Inline loading indicator
    static func inlineLoading(message: String? = nil) -> some View {
        LoadingIndicator(style: .inline, message: message)
    }
}

/// Commonly used color palette for the app
@available(iOS 15.0, macOS 12.0, *)
extension Color {
    static let realDealPrimary = Color.blue
    static let realDealSecondary = Color.gray
    static let realDealAccent = Color.green
    static let realDealError = Color.red
    static let realDealWarning = Color.orange
    static let realDealSuccess = Color.green
    
    // Background colors
    static let realDealBackground = Color(.systemBackground)
    static let realDealSecondaryBackground = Color(.secondarySystemBackground)
    static let realDealTertiaryBackground = Color(.tertiarySystemBackground)
    
    // Text colors
    static let realDealPrimaryText = Color.primary
    static let realDealSecondaryText = Color.secondary
    static let realDealTertiaryText = Color(.tertiaryLabel)
}

/// Commonly used fonts for the app
@available(iOS 15.0, macOS 12.0, *)
extension Font {
    static let realDealTitle = Font.largeTitle.weight(.bold)
    static let realDealHeadline = Font.title2.weight(.semibold)
    static let realDealSubheadline = Font.headline.weight(.medium)
    static let realDealBody = Font.body
    static let realDealCaption = Font.caption
    static let realDealButton = Font.headline.weight(.semibold)
}

/// Commonly used spacing values
@available(iOS 15.0, macOS 12.0, *)
struct RealDealSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

/// Commonly used corner radius values
@available(iOS 15.0, macOS 12.0, *)
struct RealDealCornerRadius {
    static let sm: CGFloat = 4
    static let md: CGFloat = 8
    static let lg: CGFloat = 12
    static let xl: CGFloat = 16
    static let round: CGFloat = 50
}

/// Commonly used shadow styles
@available(iOS 15.0, macOS 12.0, *)
extension View {
    func realDealCardShadow() -> some View {
        shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    func realDealButtonShadow() -> some View {
        shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
    }
    
    func realDealFloatingShadow() -> some View {
        shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Preview Helpers

#Preview("UI Components Showcase") {
    ScrollView {
        VStack(spacing: RealDealSpacing.lg) {
            // Loading States Section
            VStack(alignment: .leading, spacing: RealDealSpacing.md) {
                Text("Loading States")
                    .font(.realDealHeadline)
                
                HStack(spacing: RealDealSpacing.md) {
                    LoadingIndicator(style: .standard, message: "Loading...")
                    LoadingIndicator(style: .inline, message: "Saving...")
                    PulsingLoadingIndicator()
                    SpinningLoadingIndicator()
                }
            }
            
            Divider()
            
            // Button Styles Section
            VStack(alignment: .leading, spacing: RealDealSpacing.md) {
                Text("Button Styles")
                    .font(.realDealHeadline)
                
                VStack(spacing: RealDealSpacing.sm) {
                    Button("Primary Button") {}
                        .primaryButtonStyle()
                    
                    Button("Secondary Button") {}
                        .secondaryButtonStyle()
                    
                    Button("Destructive Button") {}
                        .destructiveButtonStyle()
                    
                    Button("Compact Button") {}
                        .compactButtonStyle()
                }
            }
            
            Divider()
            
            // Empty States Section
            VStack(alignment: .leading, spacing: RealDealSpacing.md) {
                Text("Empty States")
                    .font(.realDealHeadline)
                
                CompactEmptyStateView(
                    icon: "heart.slash",
                    message: "No favorites yet"
                )
            }
            
            Divider()
            
            // Colors Section
            VStack(alignment: .leading, spacing: RealDealSpacing.md) {
                Text("Color Palette")
                    .font(.realDealHeadline)
                
                HStack(spacing: RealDealSpacing.sm) {
                    ColorSwatch(color: .realDealPrimary, name: "Primary")
                    ColorSwatch(color: .realDealSecondary, name: "Secondary")
                    ColorSwatch(color: .realDealAccent, name: "Accent")
                    ColorSwatch(color: .realDealError, name: "Error")
                }
            }
        }
        .padding(RealDealSpacing.lg)
    }
}

@available(iOS 15.0, macOS 12.0, *)
struct ColorSwatch: View {
    let color: Color
    let name: String
    
    var body: some View {
        VStack(spacing: RealDealSpacing.xs) {
            RoundedRectangle(cornerRadius: RealDealCornerRadius.sm)
                .fill(color)
                .frame(width: 40, height: 40)
            
            Text(name)
                .font(.caption)
                .foregroundColor(.realDealSecondaryText)
        }
    }
}