import Foundation
import Combine

/// Centralized loading state management for the application
@MainActor
@available(iOS 15.0, macOS 12.0, *)
class LoadingStateManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isLoading: Bool = false
    @Published var loadingMessage: String?
    @Published var loadingOperations: Set<String> = []
    
    // MARK: - Private Properties
    
    private var operationCounts: [String: Int] = [:]
    
    // MARK: - Public Methods
    
    /// Start a loading operation with an optional message
    func startLoading(operation: String, message: String? = nil) {
        operationCounts[operation, default: 0] += 1
        loadingOperations.insert(operation)
        
        if let message = message {
            loadingMessage = message
        }
        
        updateLoadingState()
    }
    
    /// Stop a loading operation
    func stopLoading(operation: String) {
        guard let count = operationCounts[operation], count > 0 else {
            return
        }
        
        operationCounts[operation] = count - 1
        
        if operationCounts[operation] == 0 {
            operationCounts.removeValue(forKey: operation)
            loadingOperations.remove(operation)
        }
        
        updateLoadingState()
    }
    
    /// Stop all loading operations
    func stopAllLoading() {
        operationCounts.removeAll()
        loadingOperations.removeAll()
        updateLoadingState()
    }
    
    /// Check if a specific operation is loading
    func isLoading(operation: String) -> Bool {
        return loadingOperations.contains(operation)
    }
    
    /// Execute an async operation with automatic loading state management
    func withLoading<T>(
        operation: String,
        message: String? = nil,
        task: () async throws -> T
    ) async rethrows -> T {
        startLoading(operation: operation, message: message)
        defer { stopLoading(operation: operation) }
        return try await task()
    }
    
    // MARK: - Private Methods
    
    private func updateLoadingState() {
        let wasLoading = isLoading
        isLoading = !loadingOperations.isEmpty
        
        // Clear message when no operations are running
        if loadingOperations.isEmpty {
            loadingMessage = nil
        }
        
        // Log state changes for debugging
        if wasLoading != isLoading {
            print("LoadingStateManager: isLoading changed to \(isLoading), operations: \(loadingOperations)")
        }
    }
}

// MARK: - Loading Operation Constants

extension LoadingStateManager {
    
    /// Common loading operation identifiers
    enum Operation {
        static let fetchProperties = "fetchProperties"
        static let createProperty = "createProperty"
        static let updateProperty = "updateProperty"
        static let deleteProperty = "deleteProperty"
        
        static let loadProfile = "loadProfile"
        static let createProfile = "createProfile"
        static let updateProfile = "updateProfile"
        static let deleteProfile = "deleteProfile"
        
        static let loadFavorites = "loadFavorites"
        static let addFavorite = "addFavorite"
        static let removeFavorite = "removeFavorite"
        
        static let uploadImage = "uploadImage"
        static let deleteImage = "deleteImage"
        
        static let authenticate = "authenticate"
        static let signOut = "signOut"
        
        static let applyFilters = "applyFilters"
        static let loadMap = "loadMap"
        
        static let sync = "sync"
        static let refresh = "refresh"
    }
}

// MARK: - View Modifier for Loading States

@available(iOS 15.0, macOS 12.0, *)
struct LoadingStateModifier: ViewModifier {
    @ObservedObject var loadingManager: LoadingStateManager
    let style: LoadingIndicator.Style
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(loadingManager.isLoading)
                .opacity(loadingManager.isLoading ? 0.6 : 1.0)
            
            if loadingManager.isLoading {
                LoadingIndicator(
                    style: style,
                    message: loadingManager.loadingMessage
                )
                .fadeInOnAppear()
            }
        }
    }
}

@available(iOS 15.0, macOS 12.0, *)
extension View {
    /// Apply loading state management to a view
    func loadingState(
        _ manager: LoadingStateManager,
        style: LoadingIndicator.Style = .overlay
    ) -> some View {
        modifier(LoadingStateModifier(loadingManager: manager, style: style))
    }
}

// MARK: - Loading State Publisher

@available(iOS 15.0, macOS 12.0, *)
extension LoadingStateManager {
    
    /// Publisher for loading state changes
    var loadingStatePublisher: AnyPublisher<Bool, Never> {
        $isLoading.eraseToAnyPublisher()
    }
    
    /// Publisher for loading message changes
    var loadingMessagePublisher: AnyPublisher<String?, Never> {
        $loadingMessage.eraseToAnyPublisher()
    }
    
    /// Publisher for specific operation loading state
    func operationPublisher(for operation: String) -> AnyPublisher<Bool, Never> {
        $loadingOperations
            .map { $0.contains(operation) }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}