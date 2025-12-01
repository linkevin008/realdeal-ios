import Foundation
import Network
import Combine

@available(iOS 15.0, macOS 12.0, *)
class NetworkMonitor: ObservableObject {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    @Published private(set) var isConnected: Bool = true
    @Published private(set) var connectionType: NWInterface.InterfaceType?
    @Published private(set) var isExpensive: Bool = false
    @Published private(set) var isConstrained: Bool = false
    
    /// Indicates if the connection was recently lost
    @Published private(set) var wasRecentlyDisconnected: Bool = false
    
    /// Indicates if the connection was recently restored
    @Published private(set) var wasRecentlyReconnected: Bool = false
    
    private var previousConnectionState: Bool = true
    private var reconnectionTimer: Timer?
    
    static let shared = NetworkMonitor()
    
    private init() {
        startMonitoring()
    }
    
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                let newConnectionState = path.status == .satisfied
                
                // Detect connection state changes
                if self.previousConnectionState != newConnectionState {
                    if newConnectionState {
                        // Connection restored
                        self.wasRecentlyReconnected = true
                        self.wasRecentlyDisconnected = false
                        
                        // Reset flag after 3 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            self.wasRecentlyReconnected = false
                        }
                    } else {
                        // Connection lost
                        self.wasRecentlyDisconnected = true
                        self.wasRecentlyReconnected = false
                        
                        // Reset flag after 3 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            self.wasRecentlyDisconnected = false
                        }
                    }
                }
                
                self.previousConnectionState = newConnectionState
                self.isConnected = newConnectionState
                self.connectionType = path.availableInterfaces.first?.type
                self.isExpensive = path.isExpensive
                self.isConstrained = path.isConstrained
            }
        }
        monitor.start(queue: queue)
    }
    
    func stopMonitoring() {
        monitor.cancel()
        reconnectionTimer?.invalidate()
    }
    
    /// Check if network is available and throw error if not
    func requireConnection() throws {
        guard isConnected else {
            throw AppError.network(.noInternetConnection)
        }
    }
    
    /// Get a user-friendly description of the connection type
    var connectionDescription: String {
        guard isConnected else {
            return "No connection"
        }
        
        switch connectionType {
        case .wifi:
            return "Wi-Fi"
        case .cellular:
            return isExpensive ? "Cellular (metered)" : "Cellular"
        case .wiredEthernet:
            return "Ethernet"
        case .loopback:
            return "Loopback"
        case .other:
            return "Other"
        case .none:
            return "Connected"
        @unknown default:
            return "Connected"
        }
    }
}
