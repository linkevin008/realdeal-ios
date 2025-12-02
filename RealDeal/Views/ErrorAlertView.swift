import SwiftUI

/// View modifier for displaying error alerts
@available(iOS 15.0, macOS 12.0, *)
struct ErrorAlert: ViewModifier {
    @Binding var error: AppError?
    var retryAction: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .alert(
                "Error",
                isPresented: Binding(
                    get: { error != nil },
                    set: { if !$0 { error = nil } }
                ),
                presenting: error
            ) { error in
                if error.isRetryable, let retry = retryAction {
                    Button("Retry") {
                        retry()
                    }
                    Button("Cancel", role: .cancel) {
                        self.error = nil
                    }
                } else {
                    Button("OK", role: .cancel) {
                        self.error = nil
                    }
                }
            } message: { error in
                Text(error.userMessage)
            }
    }
}

@available(iOS 15.0, macOS 12.0, *)
extension View {
    /// Display an error alert with optional retry action
    /// - Parameters:
    ///   - error: Binding to the error to display
    ///   - retryAction: Optional action to execute when user taps retry
    func errorAlert(error: Binding<AppError?>, retryAction: (() -> Void)? = nil) -> some View {
        modifier(ErrorAlert(error: error, retryAction: retryAction))
    }
}

/// View modifier for displaying error messages from strings
@available(iOS 15.0, macOS 12.0, *)
struct ErrorMessageAlert: ViewModifier {
    @Binding var errorMessage: String?
    var retryAction: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .alert(
                "Error",
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { if !$0 { errorMessage = nil } }
                )
            ) {
                if let retry = retryAction {
                    Button("Retry") {
                        retry()
                    }
                    Button("Cancel", role: .cancel) {
                        errorMessage = nil
                    }
                } else {
                    Button("OK", role: .cancel) {
                        errorMessage = nil
                    }
                }
            } message: {
                if let message = errorMessage {
                    Text(message)
                }
            }
    }
}

@available(iOS 15.0, macOS 12.0, *)
extension View {
    /// Display an error alert from a string message with optional retry action
    /// - Parameters:
    ///   - errorMessage: Binding to the error message to display
    ///   - retryAction: Optional action to execute when user taps retry
    func errorMessageAlert(errorMessage: Binding<String?>, retryAction: (() -> Void)? = nil) -> some View {
        modifier(ErrorMessageAlert(errorMessage: errorMessage, retryAction: retryAction))
    }
}

/// Inline error message view for forms and inputs
@available(iOS 15.0, macOS 12.0, *)
struct InlineErrorView: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
                .font(.caption)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.red)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.red.opacity(0.1))
        )
    }
}

#Preview("Error Alert") {
    VStack {
        Text("Content")
    }
    .errorAlert(error: .constant(AppError.network(.noInternetConnection)))
}

#Preview("Inline Error") {
    InlineErrorView(message: "This field is required")
        .padding()
}

#Preview("Error Banner") {
    VStack {
        ErrorBannerView(
            error: AppError.network(.noInternetConnection),
            onDismiss: {},
            onRetry: {}
        )
        .padding()
        
        Spacer()
    }
}
