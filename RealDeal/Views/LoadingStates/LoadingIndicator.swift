import SwiftUI

/// Custom loading indicator with different styles
@available(iOS 15.0, macOS 12.0, *)
struct LoadingIndicator: View {
    enum Style {
        case standard
        case large
        case overlay
        case inline
    }
    
    let style: Style
    let message: String?
    
    init(style: Style = .standard, message: String? = nil) {
        self.style = style
        self.message = message
    }
    
    var body: some View {
        switch style {
        case .standard:
            standardIndicator
        case .large:
            largeIndicator
        case .overlay:
            overlayIndicator
        case .inline:
            inlineIndicator
        }
    }
    
    private var standardIndicator: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.blue)
            
            if let message = message {
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var largeIndicator: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.blue)
            
            if let message = message {
                Text(message)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    private var overlayIndicator: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                if let message = message {
                    Text(message)
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.8))
            )
        }
    }
    
    private var inlineIndicator: some View {
        HStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.8)
                .tint(.blue)
            
            if let message = message {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

/// Pulsing loading indicator for buttons
@available(iOS 15.0, macOS 12.0, *)
struct PulsingLoadingIndicator: View {
    @State private var isPulsing = false
    
    var body: some View {
        Circle()
            .fill(Color.blue.opacity(0.6))
            .frame(width: 20, height: 20)
            .scaleEffect(isPulsing ? 1.2 : 0.8)
            .opacity(isPulsing ? 0.4 : 1.0)
            .animation(
                Animation.easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

/// Spinning loading indicator
@available(iOS 15.0, macOS 12.0, *)
struct SpinningLoadingIndicator: View {
    @State private var isRotating = false
    
    var body: some View {
        Image(systemName: "arrow.2.circlepath")
            .font(.title2)
            .foregroundColor(.blue)
            .rotationEffect(.degrees(isRotating ? 360 : 0))
            .animation(
                Animation.linear(duration: 1.0)
                    .repeatForever(autoreverses: false),
                value: isRotating
            )
            .onAppear {
                isRotating = true
            }
    }
}

/// Loading state for async images
@available(iOS 15.0, macOS 12.0, *)
struct ImageLoadingPlaceholder: View {
    let width: CGFloat?
    let height: CGFloat
    
    init(width: CGFloat? = nil, height: CGFloat = 200) {
        self.width = width
        self.height = height
    }
    
    var body: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: width, height: height)
            .overlay(
                VStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.gray)
                    
                    Text("Loading...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            )
    }
}

/// Pull-to-refresh loading indicator
@available(iOS 15.0, macOS 12.0, *)
struct PullToRefreshIndicator: View {
    let isRefreshing: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            if isRefreshing {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(.blue)
                
                Text("Refreshing...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Image(systemName: "arrow.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Pull to refresh")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Previews

#Preview("Loading Indicators") {
    VStack(spacing: 40) {
        LoadingIndicator(style: .standard, message: "Loading...")
        
        LoadingIndicator(style: .inline, message: "Saving...")
        
        PulsingLoadingIndicator()
        
        SpinningLoadingIndicator()
        
        ImageLoadingPlaceholder(height: 100)
        
        PullToRefreshIndicator(isRefreshing: true)
    }
    .padding()
}

#Preview("Overlay Loading") {
    ZStack {
        VStack {
            Text("Background Content")
            Spacer()
        }
        
        LoadingIndicator(style: .overlay, message: "Processing...")
    }
}