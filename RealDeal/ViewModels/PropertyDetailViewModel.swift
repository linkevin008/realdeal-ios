import Foundation
import Combine

/// ViewModel for managing property detail view state
@MainActor
@available(iOS 15.0, macOS 12.0, *)
class PropertyDetailViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var property: Property
    @Published var sellerProfile: UserProfile?
    @Published var isLoadingProfile: Bool = false
    @Published var errorMessage: String?
    @Published var selectedImageIndex: Int = 0
    @Published var isShowingFullScreenImage: Bool = false
    @Published var isFavorite: Bool = false
    
    // MARK: - Properties
    
    private let propertyRepository: PropertyRepositoryProtocol
    private let userProfileRepository: UserProfileRepositoryProtocol
    private let favoritesRepository: FavoritesRepositoryProtocol?
    private let currentUserId: String?
    
    // MARK: - Initialization
    
    init(
        property: Property,
        propertyRepository: PropertyRepositoryProtocol,
        userProfileRepository: UserProfileRepositoryProtocol,
        favoritesRepository: FavoritesRepositoryProtocol? = nil,
        currentUserId: String? = nil
    ) {
        self.property = property
        self.propertyRepository = propertyRepository
        self.userProfileRepository = userProfileRepository
        self.favoritesRepository = favoritesRepository
        self.currentUserId = currentUserId
    }
    
    // MARK: - Actions
    
    /// Load seller profile information
    func loadSellerProfile() async {
        guard let sellerId = property.sellerId else {
            return
        }
        
        isLoadingProfile = true
        errorMessage = nil
        
        do {
            sellerProfile = try await userProfileRepository.fetchUserProfile(id: sellerId)
        } catch let error as AppError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = "Failed to load seller information."
        }
        
        isLoadingProfile = false
    }
    
    /// Check if property is favorited
    func checkFavoriteStatus() async {
        guard let favoritesRepository = favoritesRepository,
              let userId = currentUserId else {
            return
        }
        
        do {
            isFavorite = try await favoritesRepository.isFavorite(propertyId: property.id, userId: userId)
        } catch {
            // Silently fail - not critical
            isFavorite = false
        }
    }
    
    /// Toggle favorite status
    func toggleFavorite() async {
        guard let favoritesRepository = favoritesRepository,
              let userId = currentUserId else {
            return
        }
        
        do {
            if isFavorite {
                // Find and remove the favorite
                let favorites = try await favoritesRepository.fetchFavorites(userId: userId)
                if let favorite = favorites.first(where: { $0.propertyId == property.id }) {
                    try await favoritesRepository.removeFavorite(id: favorite.id)
                    isFavorite = false
                }
            } else {
                // Add to favorites
                let favorite = Favorite(userId: userId, propertyId: property.id)
                try await favoritesRepository.addFavorite(favorite)
                isFavorite = true
            }
        } catch let error as AppError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = "Failed to update favorite status."
        }
    }
    
    /// Refresh property data
    func refreshProperty() async {
        do {
            if let updatedProperty = try await propertyRepository.getProperty(id: property.id) {
                property = updatedProperty
            }
        } catch {
            // Silently fail - we already have the property data
        }
    }
    
    /// Show full-screen image at index
    func showFullScreenImage(at index: Int) {
        selectedImageIndex = index
        isShowingFullScreenImage = true
    }
    
    /// Navigate to next image
    func nextImage() {
        if selectedImageIndex < property.images.count - 1 {
            selectedImageIndex += 1
        }
    }
    
    /// Navigate to previous image
    func previousImage() {
        if selectedImageIndex > 0 {
            selectedImageIndex -= 1
        }
    }
    
    // MARK: - Computed Properties
    
    /// Formatted price string
    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: property.price as NSDecimalNumber) ?? "$0"
    }
    
    /// Formatted address string
    var formattedAddress: String {
        "\(property.address.street), \(property.address.city), \(property.address.state) \(property.address.zipCode)"
    }
    
    /// Formatted property type
    var formattedPropertyType: String {
        property.propertyType.rawValue.capitalized
    }
    
    /// Formatted specifications
    var formattedSpecifications: String {
        var specs: [String] = []
        
        if let bedrooms = property.specifications.bedrooms {
            specs.append("\(bedrooms) bed")
        }
        
        if let bathrooms = property.specifications.bathrooms {
            specs.append("\(bathrooms) bath")
        }
        
        if let sqft = property.specifications.squareFeet {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            if let formatted = formatter.string(from: NSNumber(value: sqft)) {
                specs.append("\(formatted) sqft")
            }
        }
        
        return specs.joined(separator: " • ")
    }
    
    /// Formatted lot size
    var formattedLotSize: String? {
        guard let lotSize = property.specifications.lotSize else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        if let formatted = formatter.string(from: NSNumber(value: lotSize)) {
            return "\(formatted) acres"
        }
        return nil
    }
    
    /// Formatted year built
    var formattedYearBuilt: String? {
        guard let year = property.specifications.yearBuilt else { return nil }
        return "Built in \(year)"
    }
    
    /// Formatted created date
    var formattedCreatedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return "Listed on \(formatter.string(from: property.createdAt))"
    }
    
    /// Formatted updated date
    var formattedUpdatedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return "Updated on \(formatter.string(from: property.updatedAt))"
    }
    
    /// Check if property has images
    var hasImages: Bool {
        !property.images.isEmpty
    }
    
    /// Sorted images by order
    var sortedImages: [PropertyImage] {
        property.images.sorted { $0.order < $1.order }
    }
    
    /// Seller contact information (respecting visibility settings)
    var visibleSellerEmail: String? {
        guard let profile = sellerProfile else { return nil }
        return profile.visibilitySettings.showEmail ? profile.email : nil
    }
    
    var visibleSellerPhone: String? {
        guard let profile = sellerProfile else { return nil }
        return profile.visibilitySettings.showPhone ? profile.phoneNumber : nil
    }
}
