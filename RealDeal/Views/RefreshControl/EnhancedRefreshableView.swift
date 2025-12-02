import SwiftUI

/// Enhanced refreshable view with custom styling and animations
@available(iOS 15.0, macOS 12.0, *)
struct EnhancedRefreshableView<Content: View>: View {
    let content: Content
    let onRefresh: () async -> Void
    let refreshMessage: String
    
    @State private var isRefreshing = false
    @State private var refreshOffset: CGFloat = 0
    @State private var refreshRotation: Double = 0
    
    init(
        refreshMessage: String = "Pull to refresh",
        onRefresh: @escaping () async -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.refreshMessage = refreshMessage
        self.onRefresh = onRefresh
        self.content = content()
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Custom refresh indicator
                refreshIndicator
                
                // Main content
                content
            }
        }
        .refreshable {
            await performRefresh()
        }
    }
    
    @ViewBuilder
    private var refreshIndicator: some View {
        if isRefreshing {
            VStack(spacing: 8) {
                Image(systemName: "arrow.clockwise")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .rotationEffect(.degrees(refreshRotation))
                    .animation(
                        Animation.linear(duration: 1.0)
                            .repeatForever(autoreverses: false),
                        value: refreshRotation
                    )
                
                Text(refreshMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 16)
            .onAppear {
                refreshRotation = 360
            }
            .onDisappear {
                refreshRotation = 0
            }
        }
    }
    
    private func performRefresh() async {
        isRefreshing = true
        await onRefresh()
        
        // Add a small delay for better UX
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        withAnimation(AnimationUtilities.gentleEase) {
            isRefreshing = false
        }
    }
}

/// Pull-to-refresh indicator with custom styling
@available(iOS 15.0, macOS 12.0, *)
struct CustomRefreshIndicator: View {
    let isRefreshing: Bool
    let progress: CGFloat // 0.0 to 1.0
    let message: String
    
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                    .frame(width: 32, height: 32)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: isRefreshing ? 1 : progress)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 32, height: 32)
                    .rotationEffect(.degrees(isRefreshing ? rotationAngle : -90))
                    .animation(
                        isRefreshing ? 
                            Animation.linear(duration: 1.0).repeatForever(autoreverses: false) :
                            Animation.easeInOut(duration: 0.2),
                        value: isRefreshing ? rotationAngle : progress
                    )
                
                // Center icon
                if isRefreshing {
                    ProgressView()
                        .scaleEffect(0.6)
                        .tint(.blue)
                } else {
                    Image(systemName: progress >= 1.0 ? "arrow.down" : "arrow.up")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .scaleEffect(progress >= 1.0 ? 1.2 : 1.0)
                        .animation(AnimationUtilities.quickBounce, value: progress >= 1.0)
                }
            }
            
            Text(refreshText)
                .font(.caption)
                .foregroundColor(.secondary)
                .animation(AnimationUtilities.gentleEase, value: isRefreshing)
        }
        .padding(.vertical, 8)
        .onAppear {
            if isRefreshing {
                rotationAngle = 360
            }
        }
        .onChange(of: isRefreshing) { _, newValue in
            if newValue {
                rotationAngle = 360
            } else {
                rotationAngle = 0
            }
        }
    }
    
    private var refreshText: String {
        if isRefreshing {
            return "Refreshing..."
        } else if progress >= 1.0 {
            return "Release to refresh"
        } else {
            return message
        }
    }
}

/// Haptic feedback manager for refresh interactions
@available(iOS 15.0, macOS 12.0, *)
class RefreshHapticManager {
    #if os(iOS)
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    
    func prepareHaptics() {
        impactFeedback.prepare()
        selectionFeedback.prepare()
    }
    
    func triggerPullFeedback() {
        selectionFeedback.selectionChanged()
    }
    
    func triggerReleaseFeedback() {
        impactFeedback.impactOccurred()
    }
    
    func triggerCompletionFeedback() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    #else
    func prepareHaptics() {}
    func triggerPullFeedback() {}
    func triggerReleaseFeedback() {}
    func triggerCompletionFeedback() {}
    #endif
}

/// View modifier for enhanced refresh functionality
@available(iOS 15.0, macOS 12.0, *)
struct EnhancedRefreshModifier: ViewModifier {
    let onRefresh: () async -> Void
    let refreshMessage: String
    
    @State private var hapticManager = RefreshHapticManager()
    
    func body(content: Content) -> some View {
        content
            .refreshable {
                hapticManager.triggerReleaseFeedback()
                await onRefresh()
                hapticManager.triggerCompletionFeedback()
            }
            .onAppear {
                hapticManager.prepareHaptics()
            }
    }
}

@available(iOS 15.0, macOS 12.0, *)
extension View {
    /// Add enhanced refresh functionality with haptic feedback
    func enhancedRefreshable(
        message: String = "Pull to refresh",
        onRefresh: @escaping () async -> Void
    ) -> some View {
        modifier(EnhancedRefreshModifier(onRefresh: onRefresh, refreshMessage: message))
    }
}

// MARK: - Previews

#Preview("Enhanced Refreshable") {
    EnhancedRefreshableView(
        refreshMessage: "Pull to refresh properties",
        onRefresh: {
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        }
    ) {
        LazyVStack(spacing: 16) {
            ForEach(0..<10) { index in
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.1))
                    .frame(height: 100)
                    .overlay(
                        Text("Item \(index + 1)")
                            .font(.headline)
                    )
            }
        }
        .padding()
    }
}

#Preview("Custom Refresh Indicator") {
    VStack(spacing: 40) {
        CustomRefreshIndicator(
            isRefreshing: false,
            progress: 0.3,
            message: "Pull to refresh"
        )
        
        CustomRefreshIndicator(
            isRefreshing: false,
            progress: 1.0,
            message: "Pull to refresh"
        )
        
        CustomRefreshIndicator(
            isRefreshing: true,
            progress: 1.0,
            message: "Pull to refresh"
        )
    }
    .padding()
}