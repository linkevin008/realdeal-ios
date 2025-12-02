import SwiftUI

/// Example view demonstrating comprehensive error handling patterns
@available(iOS 15.0, macOS 12.0, *)
struct ErrorHandlingExampleView: View {
    @StateObject private var viewModel = ExampleViewModel()
    @ObservedObject var networkMonitor = NetworkMonitor.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Network status banner
                // NetworkStatusBanner(networkMonitor: networkMonitor)
                
                // Error banner (persistent)
                if let error = viewModel.persistentError {
                    ErrorBannerView(
                        error: error,
                        onDismiss: {
                            viewModel.dismissError()
                        },
                        onRetry: {
                            Task {
                                await viewModel.retryLastOperation()
                            }
                        }
                    )
                    .padding(.horizontal)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Content
                ScrollView {
                    VStack(spacing: 16) {
                        // Example: Load data button
                        Button("Load Data") {
                            Task {
                                await viewModel.loadData()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.isLoading)
                        
                        // Example: Load with timeout
                        Button("Load with Timeout") {
                            Task {
                                await viewModel.loadDataWithTimeout()
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(viewModel.isLoading)
                        
                        // Example: Trigger validation error
                        Button("Trigger Validation Error") {
                            Task {
                                await viewModel.triggerValidationError()
                            }
                        }
                        .buttonStyle(.bordered)
                        
                        // Loading indicator
                        if viewModel.isLoading {
                            ProgressView("Loading...")
                                .padding()
                        }
                        
                        // Success message
                        if let message = viewModel.successMessage {
                            Text(message)
                                .foregroundColor(.green)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.green.opacity(0.1))
                                )
                        }
                        
                        // Inline error example
                        if let inlineError = viewModel.inlineError {
                            InlineErrorView(message: inlineError)
                        }
                    }
                    .padding()
                }
                
                Spacer()
            }
            .navigationTitle("Error Handling Demo")
            .animation(.easeInOut, value: viewModel.persistentError != nil)
            .animation(.easeInOut, value: networkMonitor.isConnected)
        }
        // Alert-based error handling
        .errorAlert(error: $viewModel.alertError) {
            Task {
                await viewModel.retryLastOperation()
            }
        }
    }
}

/// Example ViewModel demonstrating error handling patterns
@MainActor
@available(iOS 15.0, macOS 12.0, *)
class ExampleViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var alertError: AppError?
    @Published var persistentError: AppError?
    @Published var inlineError: String?
    @Published var successMessage: String?
    
    private var lastOperation: (() async -> Void)?
    
    /// Example: Load data with retry logic
    func loadData() async {
        isLoading = true
        persistentError = nil
        successMessage = nil
        
        lastOperation = { [weak self] in
            await self?.loadData()
        }
        
        do {
            // Simulate network request with retry
            try await RetryExecutor.execute(policy: .default) {
                // Simulate random failure for demo
                if Bool.random() {
                    throw AppError.network(.connectionTimeout)
                }
                
                // Simulate delay
                try await Task.sleep(nanoseconds: 1_000_000_000)
            }
            
            successMessage = "Data loaded successfully!"
            
            // Clear success message after 3 seconds
            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                self.successMessage = nil
            }
            
        } catch let error as AppError {
            persistentError = error
        } catch {
            persistentError = AppError.unknown(error.localizedDescription)
        }
        
        isLoading = false
    }
    
    /// Example: Load data with timeout
    func loadDataWithTimeout() async {
        isLoading = true
        alertError = nil
        successMessage = nil
        
        lastOperation = { [weak self] in
            await self?.loadDataWithTimeout()
        }
        
        do {
            // Simulate network request with timeout
            try await RetryExecutor.executeWithTimeout(
                policy: .default,
                timeout: 5.0
            ) {
                // Simulate long-running operation
                try await Task.sleep(nanoseconds: 10_000_000_000)
            }
            
            successMessage = "Data loaded successfully!"
            
        } catch let error as AppError {
            alertError = error
        } catch {
            alertError = AppError.unknown(error.localizedDescription)
        }
        
        isLoading = false
    }
    
    /// Example: Trigger validation error
    func triggerValidationError() async {
        inlineError = ValidationError.missingRequiredField("Email").userMessage
        
        // Clear inline error after 5 seconds
        Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            self.inlineError = nil
        }
    }
    
    /// Retry the last operation
    func retryLastOperation() async {
        dismissError()
        await lastOperation?()
    }
    
    /// Dismiss current error
    func dismissError() {
        persistentError = nil
        alertError = nil
        inlineError = nil
    }
}

#Preview {
    ErrorHandlingExampleView()
}
