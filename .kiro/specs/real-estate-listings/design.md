# Design Document

## Overview

The Real Estate Listings iOS application is a native iOS app built with SwiftUI that enables property sellers to list properties and buyers to discover them through location-based search. The app integrates both user-generated listings and external data sources (MLS, third-party APIs) into a unified browsing experience with map visualization.

**Key Technologies:**
- SwiftUI for UI layer
- MapKit for map visualization
- Combine for reactive data flow
- Core Data for local persistence
- URLSession for networking
- Swift Concurrency (async/await) for asynchronous operations

**Architecture Pattern:** MVVM (Model-View-ViewModel) with Repository pattern for data access

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     Presentation Layer                   │
│  (SwiftUI Views + ViewModels)                           │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                     Business Logic Layer                 │
│  (Use Cases / Interactors)                              │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                     Data Layer                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │  Repository  │  │   API Client │  │  Core Data   │ │
│  │   Pattern    │  │   Services   │  │   Storage    │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                  AI Services Layer (Future)              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │ Recommenda-  │  │   NL Search  │  │  Content Gen │ │
│  │  tion Engine │  │   Service    │  │   Service    │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────┘
```

### Layer Responsibilities

**Presentation Layer:**
- SwiftUI views for UI rendering
- ViewModels manage view state and user interactions
- Navigation coordination

**Business Logic Layer:**

- Use cases encapsulate business rules
- Data transformation and validation
- Orchestration of data sources

**Data Layer:**
- Repository pattern abstracts data sources
- API clients handle external integrations
- Core Data manages local persistence and caching
- Data source aggregation and deduplication

## Components and Interfaces

### Core Components

#### 1. Authentication Module
- **AuthenticationService**: Handles login, registration, session management
- **AuthViewModel**: Manages authentication UI state
- **KeychainManager**: Securely stores credentials and tokens

#### 2. Property Listing Module
- **PropertyRepository**: Aggregates listings from multiple sources
- **UserListingService**: CRUD operations for user-generated listings
- **ExternalListingService**: Fetches data from MLS/third-party APIs
- **ListingViewModel**: Manages listing display and filtering
- **PropertyDetailViewModel**: Handles individual property view state

#### 3. Map Module
- **MapViewModel**: Manages map state, markers, and clustering
- **LocationManager**: Handles user location and permissions
- **MapAnnotationView**: Custom marker views for properties

#### 4. User Profile Module
- **ProfileRepository**: User profile data access
- **ProfileViewModel**: Profile editing and display
- **ImageUploadService**: Handles profile photo uploads

#### 5. Favorites Module
- **FavoritesRepository**: Manages saved properties
- **FavoritesViewModel**: Favorites list state management

#### 6. Network Module
- **APIClient**: Base networking layer with error handling
- **MLSAPIClient**: MLS-specific integration
- **ThirdPartyAPIClient**: Integration with Zillow, Realtor.com, etc.
- **NetworkMonitor**: Tracks connectivity status

#### 7. AI Services Module (Extensibility Layer - Future)
- **AIServiceProtocol**: Base protocol for AI service integration
- **RecommendationEngine**: Property recommendations based on user behavior
- **NaturalLanguageSearchService**: Parse natural language queries into filters
- **ContentGenerationService**: Generate property descriptions from data
- **ChatbotService**: Handle user questions about properties
- **PricePredictionService**: Market analysis and price predictions

### Key Interfaces

```swift
// Repository Protocol
protocol PropertyRepositoryProtocol {
    func fetchProperties(filters: PropertyFilters) async throws -> [Property]
    func createProperty(_ property: Property) async throws -> Property
    func updateProperty(_ property: Property) async throws
    func deleteProperty(id: String) async throws
}

// External API Protocol
protocol ExternalListingAPIProtocol {
    func fetchListings(parameters: SearchParameters) async throws -> [ExternalListing]
    func normalizeToProperty(_ listing: ExternalListing) -> Property
}

// Location Service Protocol
protocol LocationServiceProtocol {
    var currentLocation: CLLocation? { get }
    func requestLocationPermission()
    func startUpdatingLocation()
}

// AI Service Protocol (Extensibility)
protocol AIServiceProtocol {
    var isAvailable: Bool { get }
    func configure(apiKey: String)
}

protocol RecommendationEngineProtocol: AIServiceProtocol {
    func getRecommendations(for user: UserProfile, limit: Int) async throws -> [Property]
}

protocol NaturalLanguageSearchProtocol: AIServiceProtocol {
    func parseQuery(_ query: String) async throws -> PropertyFilters
}

protocol ContentGenerationProtocol: AIServiceProtocol {
    func generateDescription(for property: Property) async throws -> String
}
```

## Data Models

### Core Models

#### Property
```swift
struct Property: Identifiable, Codable {
    let id: String
    var address: Address
    var price: Decimal
    var propertyType: PropertyType
    var description: String
    var specifications: PropertySpecifications
    var images: [PropertyImage]
    var location: Coordinate
    var source: ListingSource
    var sellerId: String?
    var status: PropertyStatus
    var createdAt: Date
    var updatedAt: Date
}

struct Address: Codable {
    var street: String
    var city: String
    var state: String
    var zipCode: String
    var country: String
}

struct PropertySpecifications: Codable {
    var bedrooms: Int?
    var bathrooms: Double?
    var squareFeet: Int?
    var lotSize: Double?
    var yearBuilt: Int?
}

enum PropertyType: String, Codable {
    case house
    case apartment
    case condo
    case land
    case commercial
}

enum ListingSource: String, Codable {
    case userGenerated
    case mls
    case zillow
    case realtor
    case other
}

enum PropertyStatus: String, Codable {
    case active
    case pending
    case sold
    case deleted
}
```

#### User Profile
```swift
struct UserProfile: Identifiable, Codable {
    let id: String
    var name: String
    var email: String
    var phoneNumber: String?
    var profilePhotoURL: URL?
    var role: UserRole
    var visibilitySettings: ProfileVisibility
    var createdAt: Date
}

enum UserRole: String, Codable {
    case buyer
    case seller
    case both
}

struct ProfileVisibility: Codable {
    var showEmail: Bool
    var showPhone: Bool
    var showListings: Bool
}
```

#### Property Filters
```swift
struct PropertyFilters: Codable {
    var priceRange: ClosedRange<Decimal>?
    var propertyTypes: Set<PropertyType>?
    var locationRadius: LocationRadius?
    var minBedrooms: Int?
    var minBathrooms: Double?
    var sources: Set<ListingSource>?
}

struct LocationRadius {
    var center: Coordinate
    var radiusInMiles: Double
}
```

#### Favorite
```swift
struct Favorite: Identifiable, Codable {
    let id: String
    let userId: String
    let propertyId: String
    let savedAt: Date
}
```


## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Property creation with valid data succeeds
*For any* valid property data (address, price, description, property type), creating a new property listing should result in a stored listing with matching data.
**Validates: Requirements 1.1**

### Property 2: Image association persistence
*For any* property listing and valid images, uploading images should result in those images being associated with the correct property listing when retrieved.
**Validates: Requirements 1.2**

### Property 3: Invalid property data is rejected
*For any* property data with missing required fields or invalid formats, attempting to create a listing should be rejected with appropriate validation errors.
**Validates: Requirements 1.3, 1.5**

### Property 4: Property listing persistence round-trip
*For any* valid property listing, saving it and then retrieving it should return an equivalent listing with all data intact.
**Validates: Requirements 1.4**

### Property 5: Seller listing filtering
*For any* set of property listings created by different sellers, querying for a specific seller's listings should return only listings created by that seller.
**Validates: Requirements 2.1**

### Property 6: Property update persistence round-trip
*For any* existing property listing and valid updates, updating the listing and then retrieving it should reflect all changes.
**Validates: Requirements 2.3**

### Property 7: Property deletion removes from storage
*For any* property listing, deleting it should result in the listing no longer appearing in any queries or storage.
**Validates: Requirements 2.4**

### Property 8: Sold listings excluded from buyer searches
*For any* property listing marked as sold, it should not appear in buyer search results.
**Validates: Requirements 2.5**

### Property 9: Active listings appear as map markers
*For any* set of active property listings, all should appear as markers on the map view.
**Validates: Requirements 3.1**

### Property 10: Marker clustering for nearby properties
*For any* set of properties with coordinates within clustering distance, they should be clustered with an accurate count displayed.
**Validates: Requirements 3.5**

### Property 11: Price range filter correctness
*For any* price range filter and set of listings, all returned results should have prices within the specified range.
**Validates: Requirements 4.1**

### Property 12: Property type filter correctness
*For any* set of property type filters and listings, all returned results should match one of the selected property types.
**Validates: Requirements 4.2**

### Property 13: Location radius filter correctness
*For any* location radius filter and set of listings, all returned results should be within the specified distance from the center point.
**Validates: Requirements 4.3**

### Property 14: Multiple filter conjunction
*For any* combination of filters (price, type, location) and set of listings, all returned results should satisfy all applied filters simultaneously.
**Validates: Requirements 4.4**

### Property 15: Filter clearing restores all active listings
*For any* set of applied filters, clearing them should result in all active listings being displayed.
**Validates: Requirements 4.5**

### Property 16: Property detail display completeness
*For any* property listing, the detail view should contain all required fields: address, price, description, and specifications.
**Validates: Requirements 5.1**

### Property 17: All property images displayed
*For any* property listing with associated images, the gallery view should display all images.
**Validates: Requirements 5.2**

### Property 18: Timestamp display in property details
*For any* property listing, the detail view should display both creation date and last updated date.
**Validates: Requirements 5.5**

### Property 19: Valid credentials authenticate successfully
*For any* valid user credentials, authentication should succeed and grant access to the application.
**Validates: Requirements 6.1**

### Property 20: Invalid credentials are rejected
*For any* invalid user credentials, authentication should fail with an appropriate error message.
**Validates: Requirements 6.2**

### Property 21: Registration validation enforcement
*For any* registration attempt, email format and password strength requirements should be validated and enforced.
**Validates: Requirements 6.3**

### Property 22: Profile creation persistence round-trip
*For any* valid profile data (name, email, phone, photo), creating a profile and then retrieving it should return equivalent data.
**Validates: Requirements 7.1**

### Property 23: Profile update persistence round-trip
*For any* existing profile and valid updates, updating the profile and then retrieving it should reflect all changes.
**Validates: Requirements 7.2**

### Property 24: Seller profile display completeness
*For any* seller profile, the profile view should display contact information and active listings count.
**Validates: Requirements 7.3**

### Property 25: Profile photo validation
*For any* uploaded profile photo, the image format and size should be validated before storage, rejecting invalid images.
**Validates: Requirements 7.4**

### Property 26: Profile visibility settings enforcement
*For any* user profile with visibility settings, when displayed to other users, only information marked as visible should be shown.
**Validates: Requirements 7.5**

### Property 27: External listing normalization
*For any* external API response, the data should be correctly normalized to the internal Property format with all required fields mapped.
**Validates: Requirements 8.1**

### Property 28: Listing source attribution
*For any* property listing, the display should clearly indicate the data source (MLS, Zillow, user-generated, etc.).
**Validates: Requirements 8.2**

### Property 29: External data validation
*For any* external API data, all fields should be validated and sanitized before storage, rejecting invalid data.
**Validates: Requirements 8.3**

### Property 30: Multi-source listing aggregation
*For any* set of enabled external APIs, listings should be fetched from all configured sources.
**Validates: Requirements 9.1**

### Property 31: Duplicate listing elimination
*For any* aggregated listings from multiple sources, the merged results should contain no duplicate properties.
**Validates: Requirements 9.2**

### Property 32: Conflict resolution prioritization
*For any* conflicting listing data from different sources, the configured prioritization rules should be applied correctly.
**Validates: Requirements 9.5**

### Property 33: Offline cache accessibility
*For any* previously loaded property listings, they should remain accessible from cache when the app is offline.
**Validates: Requirements 10.3**

### Property 34: Favorite addition
*For any* property listing and buyer, marking the listing as favorite should add it to the buyer's favorites list.
**Validates: Requirements 11.1**

### Property 35: Favorites retrieval completeness
*For any* buyer with saved favorites, querying their favorites should return all favorited property listings.
**Validates: Requirements 11.2**

### Property 36: Favorite removal
*For any* favorited property listing, removing it from favorites should result in it no longer appearing in the buyer's favorites list.
**Validates: Requirements 11.3**

### Property 37: Cascading favorite deletion
*For any* favorited property listing that is deleted by the seller, it should be automatically removed from all buyers' favorites lists.
**Validates: Requirements 11.4**

### Property 38: Favorite status indication
*For any* property listing, the display should correctly indicate whether it is currently favorited by the viewing user.
**Validates: Requirements 11.5**

## Error Handling

### Error Categories

**Network Errors:**
- Connection timeout
- No internet connectivity
- API rate limiting
- Server errors (5xx)
- Invalid responses

**Validation Errors:**
- Missing required fields
- Invalid data formats
- Image size/format violations
- Authentication failures

**Business Logic Errors:**
- Duplicate listings
- Unauthorized access
- Resource not found
- Conflict resolution failures

### Error Handling Strategy

1. **User-Facing Errors**: Display clear, actionable error messages in the UI
2. **Retry Logic**: Implement exponential backoff for transient failures
3. **Offline Support**: Cache data and queue operations for later sync
4. **Logging**: Log errors for debugging without exposing sensitive data
5. **Graceful Degradation**: Continue functioning with reduced capability when services are unavailable

### Error Recovery

```swift
enum AppError: Error {
    case network(NetworkError)
    case validation(ValidationError)
    case authentication(AuthError)
    case notFound
    case unauthorized
    case unknown(Error)
    
    var userMessage: String {
        // User-friendly error messages
    }
    
    var isRetryable: Bool {
        // Determine if operation can be retried
    }
}
```

## Testing Strategy

### Unit Testing

Unit tests will verify specific examples, edge cases, and error conditions for individual components:

- **Model validation**: Test property creation with valid/invalid data
- **Data transformation**: Test external listing normalization
- **Filter logic**: Test individual filter operations
- **Authentication**: Test login/registration flows
- **Repository operations**: Test CRUD operations with mocked data sources

**Framework**: XCTest

### Property-Based Testing

Property-based tests will verify universal properties that should hold across all inputs. Each property-based test will:

- Run a minimum of 100 iterations with randomly generated inputs
- Be tagged with a comment referencing the specific correctness property from this design document
- Use the format: `// Feature: real-estate-listings, Property X: [property description]`
- Implement exactly one correctness property per test

**Framework**: swift-check (Swift property-based testing library)

**Key Property Tests:**
- Round-trip properties for persistence (create/retrieve, update/retrieve)
- Filter correctness across random data sets
- Data normalization from various external formats
- Validation rules enforcement with random invalid inputs
- Deduplication with random duplicate data

### Integration Testing

- API client integration with mock servers
- Core Data persistence layer
- MapKit integration
- Authentication flow end-to-end

### UI Testing

- Navigation flows
- Form validation feedback
- Map interaction
- Image gallery functionality

**Framework**: XCTest UI Testing

## Backend Integration Strategy

The application is designed to be **backend-agnostic**, using the Repository pattern to abstract data sources. This allows you to plug in any backend service (Firebase, Supabase, custom REST API, etc.) without changing business logic or UI code.

### Data Storage Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Repository Layer                      │
│              (Backend-Agnostic Interface)                │
└─────────────────────────────────────────────────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        ▼                 ▼                 ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│  Core Data   │  │   Remote     │  │   External   │
│   (Local     │  │   Backend    │  │     APIs     │
│   Cache)     │  │  (Firebase/  │  │  (MLS, etc.) │
│              │  │   Custom)    │  │              │
└──────────────┘  └──────────────┘  └──────────────┘
```

### Backend Integration Points

**1. Remote Data Source Protocol**
```swift
protocol RemoteDataSourceProtocol {
    // Properties
    func fetchProperties(filters: PropertyFilters) async throws -> [Property]
    func createProperty(_ property: Property) async throws -> Property
    func updateProperty(_ property: Property) async throws
    func deleteProperty(id: String) async throws
    
    // Users
    func fetchUserProfile(id: String) async throws -> UserProfile
    func updateUserProfile(_ profile: UserProfile) async throws
    
    // Favorites
    func fetchFavorites(userId: String) async throws -> [Favorite]
    func addFavorite(_ favorite: Favorite) async throws
    func removeFavorite(id: String) async throws
    
    // Images
    func uploadImage(_ imageData: Data, path: String) async throws -> URL
    func deleteImage(url: URL) async throws
}
```

**2. Authentication Service Protocol**
```swift
protocol AuthenticationServiceProtocol {
    func signIn(email: String, password: String) async throws -> AuthToken
    func signUp(email: String, password: String, profile: UserProfile) async throws -> AuthToken
    func signOut() async throws
    func refreshToken(_ token: AuthToken) async throws -> AuthToken
    var currentUser: UserProfile? { get }
}
```

**3. Implementation Options**

You can implement these protocols with any backend:

- **FirebaseRemoteDataSource**: Implements `RemoteDataSourceProtocol` using Firebase Firestore
- **SupabaseRemoteDataSource**: Implements using Supabase REST API
- **CustomAPIRemoteDataSource**: Implements using your own REST API
- **MockRemoteDataSource**: For testing and development

**4. Repository Implementation**

The repository coordinates between local cache (Core Data) and remote backend:

```swift
class PropertyRepository: PropertyRepositoryProtocol {
    private let localDataSource: LocalDataSourceProtocol
    private let remoteDataSource: RemoteDataSourceProtocol
    private let networkMonitor: NetworkMonitor
    
    func fetchProperties(filters: PropertyFilters) async throws -> [Property] {
        // Try remote first if online
        if networkMonitor.isConnected {
            let properties = try await remoteDataSource.fetchProperties(filters: filters)
            // Cache locally
            await localDataSource.saveProperties(properties)
            return properties
        }
        
        // Fall back to cache if offline
        return try await localDataSource.fetchProperties(filters: filters)
    }
}
```

### What's Included in Implementation

**Included:**
- Core Data schema and local persistence layer
- Repository interfaces and base implementations
- Protocol definitions for all backend services
- Mock implementations for testing
- Network monitoring and offline support
- Image caching layer

**Integration Points (You Provide):**
- Concrete backend implementation (Firebase, Supabase, custom API)
- Backend service configuration (API keys, endpoints)
- MLS API credentials and integration
- Third-party API keys (Zillow, etc.)
- Image storage service (S3, Firebase Storage, etc.)

### Configuration Management

```swift
struct BackendConfiguration {
    let baseURL: URL?
    let apiKey: String?
    let authEndpoint: String?
    let storageEndpoint: String?
    
    // Easy switching between backends
    static let firebase = BackendConfiguration(...)
    static let supabase = BackendConfiguration(...)
    static let custom = BackendConfiguration(...)
}
```

## Extensibility for AI Integration

The architecture is designed to support future AI agent capabilities without requiring major refactoring:

### AI Service Integration Points

1. **Protocol-Based Design**: All AI services implement `AIServiceProtocol`, allowing easy addition of new AI capabilities
2. **Dependency Injection**: ViewModels and use cases accept AI service protocols, making them optional and swappable
3. **Feature Flags**: AI features can be enabled/disabled via configuration
4. **Graceful Degradation**: App functions fully without AI services; they enhance rather than replace core functionality

### Future AI Capabilities

**Phase 1 (Near-term):**
- Smart property recommendations based on viewing history
- Natural language search parsing
- Automated property description generation

**Phase 2 (Medium-term):**
- Chatbot for property inquiries
- Price prediction and market analysis
- Image-based property feature detection

**Phase 3 (Long-term):**
- Virtual tour narration
- Document analysis for contracts
- Neighborhood insights and predictions

### Implementation Strategy

```swift
// Example: ViewModel with optional AI service
class PropertyListViewModel: ObservableObject {
    private let repository: PropertyRepositoryProtocol
    private let recommendationEngine: RecommendationEngineProtocol?
    
    init(
        repository: PropertyRepositoryProtocol,
        recommendationEngine: RecommendationEngineProtocol? = nil
    ) {
        self.repository = repository
        self.recommendationEngine = recommendationEngine
    }
    
    func loadProperties() async {
        // Load standard properties
        let properties = try await repository.fetchProperties()
        
        // Optionally enhance with AI recommendations
        if let engine = recommendationEngine, engine.isAvailable {
            let recommended = try? await engine.getRecommendations(for: currentUser, limit: 5)
            // Merge and display
        }
    }
}
```

## Performance Considerations

1. **Map Rendering**: Use marker clustering for large datasets
2. **Image Loading**: Lazy load images with caching
3. **Data Pagination**: Implement pagination for listing queries
4. **Background Sync**: Fetch external listings in background
5. **Core Data Optimization**: Use batch operations and proper indexing
6. **AI Service Caching**: Cache AI-generated content to reduce API calls

## Security Considerations

1. **Credential Storage**: Use Keychain for sensitive data
2. **API Keys**: Store in secure configuration, never in code
3. **Data Validation**: Sanitize all external inputs
4. **HTTPS Only**: Enforce secure connections
5. **Session Management**: Implement proper token expiration and refresh
