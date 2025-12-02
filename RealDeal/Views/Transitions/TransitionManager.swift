import SwiftUI

/// Centralized transition management for consistent animations throughout the app
@available(iOS 15.0, macOS 12.0, *)
struct TransitionManager {
    
    // MARK: - Standard Transitions
    
    /// Smooth slide transition for navigation
    static let slideTransition = AnyTransition.asymmetric(
        insertion: .move(edge: .trailing).combined(with: .opacity),
        removal: .move(edge: .leading).combined(with: .opacity)
    )
    
    /// Fade transition for content changes
    static let fadeTransition = AnyTransition.opacity
    
    /// Scale transition for modal presentations
    static let scaleTransition = AnyTransition.scale(scale: 0.8)
        .combined(with: .opacity)
    
    /// Slide up transition for sheets and overlays
    static let slideUpTransition = AnyTransition.move(edge: .bottom)
        .combined(with: .opacity)
    
    /// Slide down transition for dismissals
    static let slideDownTransition = AnyTransition.move(edge: .top)
        .combined(with: .opacity)
    
    // MARK: - Loading State Transitions
    
    /// Transition for loading states
    static let loadingTransition = AnyTransition.opacity
        .animation(AnimationUtilities.gentleEase)
    
    /// Transition for skeleton views
    static let skeletonTransition = AnyTransition.opacity
        .animation(AnimationUtilities.slowFade)
    
    /// Transition for content appearing after loading
    static let contentTransition = AnyTransition.opacity
        .combined(with: .move(edge: .top))
        .animation(AnimationUtilities.smoothSpring)
    
    // MARK: - List Transitions
    
    /// Transition for list items
    static let listItemTransition = AnyTransition.asymmetric(
        insertion: .move(edge: .trailing).combined(with: .opacity),
        removal: .move(edge: .leading).combined(with: .opacity)
    )
    
    /// Transition for adding items to lists
    static let addItemTransition = AnyTransition.scale(scale: 0.8)
        .combined(with: .opacity)
        .animation(AnimationUtilities.smoothSpring)
    
    /// Transition for removing items from lists
    static let removeItemTransition = AnyTransition.scale(scale: 0.8)
        .combined(with: .opacity)
        .animation(AnimationUtilities.quickBounce)
    
    // MARK: - Error State Transitions
    
    /// Transition for error messages
    static let errorTransition = AnyTransition.move(edge: .top)
        .combined(with: .opacity)
        .animation(AnimationUtilities.quickBounce)
    
    /// Transition for success messages
    static let successTransition = AnyTransition.scale(scale: 0.8)
        .combined(with: .opacity)
        .animation(AnimationUtilities.smoothSpring)
    
    // MARK: - Modal Transitions
    
    /// Transition for modal sheets
    static let modalTransition = AnyTransition.move(edge: .bottom)
        .animation(AnimationUtilities.smoothSpring)
    
    /// Transition for alert overlays
    static let alertTransition = AnyTransition.scale(scale: 0.8)
        .combined(with: .opacity)
        .animation(AnimationUtilities.quickBounce)
    
    // MARK: - Custom Transition Builders
    
    /// Create a custom slide transition with specified edge
    static func slideTransition(from edge: Edge) -> AnyTransition {
        AnyTransition.move(edge: edge)
            .combined(with: .opacity)
            .animation(AnimationUtilities.smoothSpring)
    }
    
    /// Create a custom scale transition with specified scale
    static func scaleTransition(scale: CGFloat) -> AnyTransition {
        AnyTransition.scale(scale: scale)
            .combined(with: .opacity)
            .animation(AnimationUtilities.smoothSpring)
    }
    
    /// Create a custom rotation transition
    static func rotationTransition(angle: Angle) -> AnyTransition {
        AnyTransition.modifier(
            active: RotationModifier(angle: angle, opacity: 0),
            identity: RotationModifier(angle: .zero, opacity: 1)
        )
        .animation(AnimationUtilities.smoothSpring)
    }
}

// MARK: - Custom Transition Modifiers

@available(iOS 15.0, macOS 12.0, *)
struct RotationModifier: ViewModifier {
    let angle: Angle
    let opacity: Double
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(angle)
            .opacity(opacity)
    }
}

@available(iOS 15.0, macOS 12.0, *)
struct SlideScaleModifier: ViewModifier {
    let offset: CGSize
    let scale: CGFloat
    let opacity: Double
    
    func body(content: Content) -> some View {
        content
            .offset(offset)
            .scaleEffect(scale)
            .opacity(opacity)
    }
}

// MARK: - View Extensions for Transitions

@available(iOS 15.0, macOS 12.0, *)
extension View {
    
    /// Apply smooth slide transition
    func smoothSlideTransition() -> some View {
        transition(TransitionManager.slideTransition)
    }
    
    /// Apply fade transition
    func fadeTransition() -> some View {
        transition(TransitionManager.fadeTransition)
    }
    
    /// Apply scale transition
    func scaleTransition() -> some View {
        transition(TransitionManager.scaleTransition)
    }
    
    /// Apply loading state transition
    func loadingTransition() -> some View {
        transition(TransitionManager.loadingTransition)
    }
    
    /// Apply content transition (for appearing after loading)
    func contentTransition() -> some View {
        transition(TransitionManager.contentTransition)
    }
    
    /// Apply list item transition
    func listItemTransition() -> some View {
        transition(TransitionManager.listItemTransition)
    }
    
    /// Apply error message transition
    func errorTransition() -> some View {
        transition(TransitionManager.errorTransition)
    }
    
    /// Apply success message transition
    func successTransition() -> some View {
        transition(TransitionManager.successTransition)
    }
    
    /// Apply modal transition
    func modalTransition() -> some View {
        transition(TransitionManager.modalTransition)
    }
    
    /// Apply custom slide transition from specified edge
    func slideTransition(from edge: Edge) -> some View {
        transition(TransitionManager.slideTransition(from: edge))
    }
}

// MARK: - Conditional Transitions

@available(iOS 15.0, macOS 12.0, *)
extension View {
    
    /// Apply transition conditionally based on a boolean
    func conditionalTransition<T: ViewModifier>(
        _ condition: Bool,
        transition: AnyTransition,
        modifier: T
    ) -> some View {
        Group {
            if condition {
                self.transition(transition)
            } else {
                self.modifier(modifier)
            }
        }
    }
    
    /// Apply different transitions for different states
    func stateTransition<T: Equatable>(
        state: T,
        transitions: [T: AnyTransition]
    ) -> some View {
        Group {
            if let transition = transitions[state] {
                self.transition(transition)
            } else {
                self
            }
        }
    }
}

// MARK: - Transition Timing

@available(iOS 15.0, macOS 12.0, *)
struct TransitionTiming {
    static let instant: Double = 0.0
    static let fast: Double = 0.2
    static let normal: Double = 0.3
    static let slow: Double = 0.5
    static let verySlow: Double = 0.8
}

// MARK: - Transition Presets for Common UI Patterns

@available(iOS 15.0, macOS 12.0, *)
extension TransitionManager {
    
    /// Transition preset for property cards appearing in lists
    static let propertyCardTransition = AnyTransition.asymmetric(
        insertion: .move(edge: .bottom).combined(with: .opacity),
        removal: .scale(scale: 0.8).combined(with: .opacity)
    )
    
    /// Transition preset for filter panels
    static let filterPanelTransition = AnyTransition.move(edge: .bottom)
        .animation(AnimationUtilities.smoothSpring)
    
    /// Transition preset for map annotations
    static let mapAnnotationTransition = AnyTransition.scale(scale: 0.5)
        .combined(with: .opacity)
        .animation(AnimationUtilities.quickBounce)
    
    /// Transition preset for profile photos
    static let profilePhotoTransition = AnyTransition.scale(scale: 0.8)
        .combined(with: .opacity)
        .animation(AnimationUtilities.gentleEase)
    
    /// Transition preset for favorite buttons
    static let favoriteTransition = AnyTransition.scale(scale: 0.5)
        .animation(AnimationUtilities.quickBounce)
}