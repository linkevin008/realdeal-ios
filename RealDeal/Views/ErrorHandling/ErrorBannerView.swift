import SwiftUI

/// A banner view for displaying error messages with consistent styling
@available(iOS 15.0, macOS 12.0, *)
struct ErrorBannerView: View {
    let error: AppError
    let onDismiss: () -> Void
    let onRetry: (() -> Void)?
    
    @State private var isVisible = false
    
    init(
        error: AppError,
        onDismiss: @escaping () -> Void,
        onRetry: (() -> Void)? = nil
    ) {
        self.error = error
        self.onDismiss = onDismiss
        self.onRetry = onRetry
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Error icon
                Image(systemName: errorIcon)
                    .font(.title2)
                    .foregroundColor(errorColor)
                
                // Error content
                VStack(alignment: .leading, spacing: 4) {
                    Text(errorTitle)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(error.userMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 8) {
                    if let onRetry = onRetry {
                        Button("Retry") {
                            onRetry()
                        }
                        .compactButtonStyle()
                    }
                    
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .iconButtonStyle()
                }
            }
            .padding()
            .background(backgroundColor)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .padding(.horizontal)
        .offset(y: isVisible ? 0 : -100)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(AnimationUtilities.smoothSpring) {
                isVisible = true
            }
            
            // Auto-dismiss after 5 seconds for non-critical errors
            if !error.isCritical {
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    dismissWithAnimation()
                }
            }
        }
        .onTapGesture {
            dismissWithAnimation()
        }
    }
    
    // MARK: - Private Properties
    
    private var errorIcon: String {
        switch error.severity {
        case .low:
            return "info.circle.fill"
        case .medium:
            return "exclamationmark.triangle.fill"
        case .high:
            return "xmark.circle.fill"
        case .critical:
            return "exclamationmark.octagon.fill"
        }
    }
    
    private var errorColor: Color {
        switch error.severity {
        case .low:
            return .blue
        case .medium:
            return .orange
        case .high:
            return .red
        case .critical:
            return .red
        }
    }
    
    private var backgroundColor: Color {
        switch error.severity {
        case .low:
            return Color.blue.opacity(0.1)
        case .medium:
            return Color.orange.opacity(0.1)
        case .high:
            return Color.red.opacity(0.1)
        case .critical:
            return Color.red.opacity(0.2)
        }
    }
    
    private var errorTitle: String {
        switch error.severity {
        case .low:
            return "Information"
        case .medium:
            return "Warning"
        case .high:
            return "Error"
        case .critical:
            return "Critical Error"
        }
    }
    
    // MARK: - Private Methods
    
    private func dismissWithAnimation() {
        withAnimation(AnimationUtilities.gentleEase) {
            isVisible = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

/// Success banner view for positive feedback
@available(iOS 15.0, macOS 12.0, *)
struct SuccessBannerView: View {
    let message: String
    let onDismiss: () -> Void
    
    @State private var isVisible = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Success icon
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                
                // Success message
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                // Dismiss button
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .iconButtonStyle()
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .padding(.horizontal)
        .offset(y: isVisible ? 0 : -100)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(AnimationUtilities.smoothSpring) {
                isVisible = true
            }
            
            // Auto-dismiss after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                dismissWithAnimation()
            }
        }
        .onTapGesture {
            dismissWithAnimation()
        }
    }
    
    private func dismissWithAnimation() {
        withAnimation(AnimationUtilities.gentleEase) {
            isVisible = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

/// Toast notification view for brief messages
@available(iOS 15.0, macOS 12.0, *)
struct ToastView: View {
    let message: String
    let type: ToastType
    let onDismiss: () -> Void
    
    @State private var isVisible = false
    
    enum ToastType {
        case info
        case success
        case warning
        case error
        
        var icon: String {
            switch self {
            case .info: return "info.circle.fill"
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .info: return .blue
            case .success: return .green
            case .warning: return .orange
            case .error: return .red
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: type.icon)
                .font(.caption)
                .foregroundColor(type.color)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(2)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        )
        .scaleEffect(isVisible ? 1 : 0.8)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(AnimationUtilities.quickBounce) {
                isVisible = true
            }
            
            // Auto-dismiss after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                dismissWithAnimation()
            }
        }
    }
    
    private func dismissWithAnimation() {
        withAnimation(AnimationUtilities.quickBounce) {
            isVisible = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
}

// MARK: - Error Extensions

extension AppError {
    var severity: ErrorSeverity {
        switch self {
        case .network(.connectionTimeout), .network(.noInternetConnection):
            return .medium
        case .network(.serverError), .network(.invalidResponse):
            return .high
        case .network:
            return .medium
        case .validation:
            return .low
        case .authentication(.invalidCredentials):
            return .medium
        case .authentication(.sessionExpired):
            return .high
        case .authentication:
            return .medium
        case .storage:
            return .medium
        case .dataCorruption:
            return .critical
        case .notFound:
            return .medium
        case .unauthorized:
            return .high
        case .conflict:
            return .medium
        case .unknown:
            return .critical
        }
    }
    
    var isCritical: Bool {
        severity == .critical
    }
}

enum ErrorSeverity {
    case low
    case medium
    case high
    case critical
}

// MARK: - View Extensions

@available(iOS 15.0, macOS 12.0, *)
extension View {
    /// Show an error banner overlay
    func errorBanner(
        error: Binding<AppError?>,
        onRetry: (() -> Void)? = nil
    ) -> some View {
        ZStack(alignment: .top) {
            self
            
            if let currentError = error.wrappedValue {
                ErrorBannerView(
                    error: currentError,
                    onDismiss: {
                        error.wrappedValue = nil
                    },
                    onRetry: onRetry
                )
                .zIndex(1000)
                .errorTransition()
            }
        }
    }
    
    /// Show a success banner overlay
    func successBanner(
        message: Binding<String?>,
        onDismiss: (() -> Void)? = nil
    ) -> some View {
        ZStack(alignment: .top) {
            self
            
            if let successMessage = message.wrappedValue {
                SuccessBannerView(
                    message: successMessage,
                    onDismiss: {
                        message.wrappedValue = nil
                        onDismiss?()
                    }
                )
                .zIndex(1000)
                .successTransition()
            }
        }
    }
    
    /// Show a toast notification overlay
    func toast(
        message: Binding<String?>,
        type: ToastView.ToastType = .info
    ) -> some View {
        ZStack(alignment: .bottom) {
            self
            
            if let toastMessage = message.wrappedValue {
                ToastView(
                    message: toastMessage,
                    type: type,
                    onDismiss: {
                        message.wrappedValue = nil
                    }
                )
                .padding(.bottom, 100) // Above tab bar
                .zIndex(1000)
            }
        }
    }
}

// MARK: - Previews

#Preview("Error Banner") {
    VStack {
        Spacer()
    }
    .errorBanner(
        error: .constant(AppError.network(.connectionTimeout)),
        onRetry: {}
    )
}

#Preview("Success Banner") {
    VStack {
        Spacer()
    }
    .successBanner(
        message: .constant("Property saved successfully!")
    )
}

#Preview("Toast Notifications") {
    VStack(spacing: 20) {
        ToastView(message: "Info message", type: .info, onDismiss: {})
        ToastView(message: "Success message", type: .success, onDismiss: {})
        ToastView(message: "Warning message", type: .warning, onDismiss: {})
        ToastView(message: "Error message", type: .error, onDismiss: {})
    }
    .padding()
}