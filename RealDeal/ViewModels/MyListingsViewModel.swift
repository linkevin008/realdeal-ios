import Foundation
import Combine

/// ViewModel for managing seller's property listings
@MainActor
@available(iOS 15.0, macOS 12.0, *)
class MyListingsViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var properties: [Property] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Filter by status
    @Published var selectedStatus: PropertyStatus? = nil
    
    // MARK: - Properties
    
    let service: PropertyListingService
    let currentUserId: String
    
    // MARK: - Initialization
    
    init(service: PropertyListingService, currentUserId: String) {
        self.service = service
        self.currentUserId = currentUserId
    }
    
    // MARK: - Actions
    
    /// Load all properties for the current seller
    func loadProperties() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let allProperties = try await service.fetchSellerProperties(sellerId: currentUserId)
            properties = allProperties
        } catch let error as AppError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = "Failed to load your listings. Please try again."
        }
        
        isLoading = false
    }
    
    /// Delete a property
    func deleteProperty(_ property: Property) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await service.deleteProperty(id: property.id)
            properties.removeAll { $0.id == property.id }
        } catch let error as AppError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = "Failed to delete property. Please try again."
        }
        
        isLoading = false
    }
    
    /// Update property status
    func updatePropertyStatus(_ property: Property, status: PropertyStatus) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await service.updatePropertyStatus(propertyId: property.id, status: status)
            
            // Update local copy
            if let index = properties.firstIndex(where: { $0.id == property.id }) {
                properties[index].status = status
            }
        } catch let error as AppError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = "Failed to update property status. Please try again."
        }
        
        isLoading = false
    }
    
    // MARK: - Computed Properties
    
    /// Get filtered properties based on selected status
    var filteredProperties: [Property] {
        guard let status = selectedStatus else {
            return properties
        }
        return properties.filter { $0.status == status }
    }
    
    /// Count of properties by status
    var activeCount: Int {
        properties.filter { $0.status == .active }.count
    }
    
    var pendingCount: Int {
        properties.filter { $0.status == .pending }.count
    }
    
    var soldCount: Int {
        properties.filter { $0.status == .sold }.count
    }
}
