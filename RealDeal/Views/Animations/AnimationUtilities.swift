import SwiftUI

/// Collection of reusable animations for the app
@available(iOS 15.0, macOS 12.0, *)
struct AnimationUtilities {
    
    // MARK: - Standard Animations
    
    /// Smooth spring animation for UI interactions
    static let smoothSpring = Animation.spring(
        response: 0.6,
        dampingFraction: 0.8,
        blendDuration: 0
    )
    
    /// Quick bounce animation for button presses
    static let quickBounce = Animation.spring(
        response: 0.3,
        dampingFraction: 0.6,
        blendDuration: 0
    )
    
    /// Gentle ease animation for content transitions
    static let gentleEase = Animation.easeInOut(duration: 0.4)
    
    /// Fast fade animation for overlays
    static let fastFade = Animation.easeInOut(duration: 0.2)
    
    /// Slow fade animation for content loading
    static let slowFade = Animation.easeInOut(duration: 0.8)
    
    // MARK: - Loading Animations
    
    /// Pulsing animation for loading indicators
    static let pulse = Animation
        .easeInOut(duration: 1.0)
        .repeatForever(autoreverses: true)
    
    /// Rotation animation for spinners
    static let rotation = Animation
        .linear(duration: 1.0)
        .repeatForever(autoreverses: false)
    
    /// Shimmer animation for skeleton views
    static let shimmer = Animation
        .linear(duration: 1.5)
        .repeatForever(autoreverses: false)
    
    // MARK: - Transition Animations
    
    /// Slide in from bottom transition
    static let slideInFromBottom = AnyTransition.move(edge: .bottom)
        .combined(with: .opacity)
    
    /// Slide in from top transition
    static let slideInFromTop = AnyTransition.move(edge: .top)
        .combined(with: .opacity)
    
    /// Scale and fade transition
    static let scaleAndFade = AnyTransition.scale(scale: 0.8)
        .combined(with: .opacity)
    
    /// Push transition for navigation-like animations
    static let push = AnyTransition.asymmetric(
        insertion: .move(edge: .trailing).combined(with: .opacity),
        removal: .move(edge: .leading).combined(with: .opacity)
    )
}

/// View modifier for fade-in animation on appear
@available(iOS 15.0, macOS 12.0, *)
struct FadeInOnAppear: ViewModifier {
    @State private var opacity: Double = 0
    let delay: Double
    
    init(delay: Double = 0) {
        self.delay = delay
    }
    
    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .onAppear {
                withAnimation(AnimationUtilities.gentleEase.delay(delay)) {
                    opacity = 1
                }
            }
    }
}

/// View modifier for slide-in animation on appear
@available(iOS 15.0, macOS 12.0, *)
struct SlideInOnAppear: ViewModifier {
    @State private var offset: CGFloat = 50
    @State private var opacity: Double = 0
    let delay: Double
    
    init(delay: Double = 0) {
        self.delay = delay
    }
    
    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .opacity(opacity)
            .onAppear {
                withAnimation(AnimationUtilities.smoothSpring.delay(delay)) {
                    offset = 0
                    opacity = 1
                }
            }
    }
}

/// View modifier for scale-in animation on appear
@available(iOS 15.0, macOS 12.0, *)
struct ScaleInOnAppear: ViewModifier {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    let delay: Double
    
    init(delay: Double = 0) {
        self.delay = delay
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(AnimationUtilities.smoothSpring.delay(delay)) {
                    scale = 1
                    opacity = 1
                }
            }
    }
}

/// View modifier for staggered list animations
@available(iOS 15.0, macOS 12.0, *)
struct StaggeredListAnimation: ViewModifier {
    let index: Int
    let staggerDelay: Double
    
    init(index: Int, staggerDelay: Double = 0.1) {
        self.index = index
        self.staggerDelay = staggerDelay
    }
    
    func body(content: Content) -> some View {
        content
            .modifier(SlideInOnAppear(delay: Double(index) * staggerDelay))
    }
}

/// View modifier for button press animation
@available(iOS 15.0, macOS 12.0, *)
struct ButtonPressAnimation: ViewModifier {
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) { _ in
                // On press
                withAnimation(AnimationUtilities.quickBounce) {
                    isPressed = true
                }
            } onPressingChanged: { pressing in
                if !pressing {
                    // On release
                    withAnimation(AnimationUtilities.quickBounce) {
                        isPressed = false
                    }
                }
            }
    }
}

/// View modifier for shake animation (for errors)
@available(iOS 15.0, macOS 12.0, *)
struct ShakeAnimation: ViewModifier {
    @State private var offset: CGFloat = 0
    let trigger: Bool
    
    func body(content: Content) -> some View {
        content
            .offset(x: offset)
            .onChange(of: trigger) { _, _ in
                shake()
            }
    }
    
    private func shake() {
        let animation = Animation.easeInOut(duration: 0.1)
        
        withAnimation(animation) {
            offset = -5
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(animation) {
                offset = 5
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(animation) {
                offset = -3
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(animation) {
                offset = 0
            }
        }
    }
}

/// View modifier for loading state transition
@available(iOS 15.0, macOS 12.0, *)
struct LoadingStateTransition: ViewModifier {
    let isLoading: Bool
    
    func body(content: Content) -> some View {
        content
            .opacity(isLoading ? 0.6 : 1.0)
            .animation(AnimationUtilities.gentleEase, value: isLoading)
    }
}

/// View modifier for success state animation
@available(iOS 15.0, macOS 12.0, *)
struct SuccessAnimation: ViewModifier {
    @State private var scale: CGFloat = 1
    @State private var opacity: Double = 1
    let trigger: Bool
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .opacity(opacity)
            .onChange(of: trigger) { _, _ in
                if trigger {
                    animateSuccess()
                }
            }
    }
    
    private func animateSuccess() {
        // Quick scale up
        withAnimation(Animation.easeOut(duration: 0.2)) {
            scale = 1.1
        }
        
        // Scale back down
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(Animation.easeInOut(duration: 0.3)) {
                scale = 1.0
            }
        }
    }
}

// MARK: - View Extensions

@available(iOS 15.0, macOS 12.0, *)
extension View {
    /// Fade in animation on appear
    func fadeInOnAppear(delay: Double = 0) -> some View {
        modifier(FadeInOnAppear(delay: delay))
    }
    
    /// Slide in animation on appear
    func slideInOnAppear(delay: Double = 0) -> some View {
        modifier(SlideInOnAppear(delay: delay))
    }
    
    /// Scale in animation on appear
    func scaleInOnAppear(delay: Double = 0) -> some View {
        modifier(ScaleInOnAppear(delay: delay))
    }
    
    /// Staggered animation for list items
    func staggeredListAnimation(index: Int, staggerDelay: Double = 0.1) -> some View {
        modifier(StaggeredListAnimation(index: index, staggerDelay: staggerDelay))
    }
    
    /// Button press animation
    func buttonPressAnimation() -> some View {
        modifier(ButtonPressAnimation())
    }
    
    /// Shake animation for errors
    func shakeAnimation(trigger: Bool) -> some View {
        modifier(ShakeAnimation(trigger: trigger))
    }
    
    /// Loading state transition
    func loadingStateTransition(isLoading: Bool) -> some View {
        modifier(LoadingStateTransition(isLoading: isLoading))
    }
    
    /// Success animation
    func successAnimation(trigger: Bool) -> some View {
        modifier(SuccessAnimation(trigger: trigger))
    }
}

// MARK: - Animated Containers

/// Container that animates its children with staggered delays
@available(iOS 15.0, macOS 12.0, *)
struct AnimatedVStack<Content: View>: View {
    let alignment: HorizontalAlignment
    let spacing: CGFloat?
    let staggerDelay: Double
    let content: Content
    
    init(
        alignment: HorizontalAlignment = .center,
        spacing: CGFloat? = nil,
        staggerDelay: Double = 0.1,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.staggerDelay = staggerDelay
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: alignment, spacing: spacing) {
            content
        }
    }
}

/// Container for animated list items
@available(iOS 15.0, macOS 12.0, *)
struct AnimatedList<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable {
    let data: Data
    let content: (Int, Data.Element) -> Content
    
    init(_ data: Data, @ViewBuilder content: @escaping (Int, Data.Element) -> Content) {
        self.data = data
        self.content = content
    }
    
    var body: some View {
        LazyVStack(spacing: 16) {
            ForEach(Array(data.enumerated()), id: \.element.id) { index, item in
                content(index, item)
                    .staggeredListAnimation(index: index)
            }
        }
    }
}

// MARK: - Previews

#Preview("Animations") {
    ScrollView {
        VStack(spacing: 30) {
            Text("Fade In Animation")
                .font(.headline)
                .fadeInOnAppear(delay: 0.2)
            
            Text("Slide In Animation")
                .font(.headline)
                .slideInOnAppear(delay: 0.4)
            
            Text("Scale In Animation")
                .font(.headline)
                .scaleInOnAppear(delay: 0.6)
            
            Button("Press Me") {}
                .primaryButtonStyle()
                .buttonPressAnimation()
            
            VStack(spacing: 16) {
                ForEach(0..<3) { index in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.3))
                        .frame(height: 60)
                        .staggeredListAnimation(index: index)
                }
            }
        }
        .padding()
    }
}