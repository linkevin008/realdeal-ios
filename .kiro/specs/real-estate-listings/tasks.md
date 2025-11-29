# Implementation Plan

- [x] 1. Set up project structure and core infrastructure
  - Create Xcode project with SwiftUI app template
  - Set up folder structure: Models, Views, ViewModels, Repositories, Services, Utilities
  - Configure Core Data stack with persistent container
  - Add swift-check dependency for property-based testing
  - Create base protocols for repository and service layers
  - _Requirements: All (foundational)_

- [x] 2. Implement core data models and validation
  - Create Property model with all fields (address, price, type, specifications, location, source, status)
  - Create UserProfile model with visibility settings
  - Create PropertyFilters model for search criteria
  - Create Favorite model for saved properties
  - Implement validation logic for required fields and data formats
  - _Requirements: 1.1, 1.3, 7.1_

- [x] 2.1 Write property test for property creation validation
  - **Property 3: Invalid property data is rejected**
  - **Validates: Requirements 1.3, 1.5**

- [x] 2.2 Write property test for profile creation validation
  - **Property 25: Profile photo validation**
  - **Validates: Requirements 7.4**

- [x] 3. Set up Core Data persistence layer
  - Create Core Data entities for Property, UserProfile, Favorite
  - Implement LocalDataSource with CRUD operations
  - Add Core Data indexes for common queries
  - Implement data migration strategy
  - _Requirements: 1.4, 2.3, 7.1, 7.2_

- [x] 3.1 Write property test for property persistence round-trip
  - **Property 4: Property listing persistence round-trip**
  - **Validates: Requirements 1.4**

- [x] 3.2 Write property test for profile persistence round-trip
  - **Property 22: Profile creation persistence round-trip**
  - **Validates: Requirements 7.1**

- [x] 4. Implement backend integration protocols
  - Create RemoteDataSourceProtocol with all CRUD operations
  - Create AuthenticationServiceProtocol for user authentication
  - Create ImageStorageProtocol for photo uploads
  - Implement MockRemoteDataSource for testing
  - Create BackendConfiguration for service setup
  - _Requirements: 1.4, 6.1, 6.2, 7.4_

- [x] 5. Build repository layer
  - Implement PropertyRepository coordinating local and remote data sources
  - Implement UserProfileRepository with cache-first strategy
  - Implement FavoritesRepository with sync logic
  - Add NetworkMonitor for connectivity tracking
  - Implement offline-first data access with fallback to cache
  - _Requirements: 1.4, 2.3, 10.3, 11.1_

- [x] 5.1 Write property test for update persistence round-trip
  - **Property 6: Property update persistence round-trip**
  - **Validates: Requirements 2.3**

- [x] 5.2 Write property test for profile update persistence round-trip
  - **Property 23: Profile update persistence round-trip**
  - **Validates: Requirements 7.2**

- [x] 5.3 Write property test for offline cache accessibility
  - **Property 33: Offline cache accessibility**
  - **Validates: Requirements 10.3**

- [ ] 6. Implement authentication module
  - Create AuthenticationService with sign in, sign up, sign out methods
  - Implement KeychainManager for secure credential storage
  - Create AuthViewModel managing authentication state
  - Build login and registration SwiftUI views
  - Add email and password validation logic
  - _Requirements: 6.1, 6.2, 6.3_

- [ ]* 6.1 Write property test for valid credentials authentication
  - **Property 19: Valid credentials authenticate successfully**
  - **Validates: Requirements 6.1**

- [ ]* 6.2 Write property test for invalid credentials rejection
  - **Property 20: Invalid credentials are rejected**
  - **Validates: Requirements 6.2**

- [ ]* 6.3 Write property test for registration validation
  - **Property 21: Registration validation enforcement**
  - **Validates: Requirements 6.3**

- [ ] 7. Build user profile module
  - Create ProfileRepository with CRUD operations
  - Implement ProfileViewModel managing profile state
  - Build profile creation and editing SwiftUI views
  - Add image picker for profile photo upload
  - Implement profile visibility settings UI
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [ ]* 7.1 Write property test for profile visibility enforcement
  - **Property 26: Profile visibility settings enforcement**
  - **Validates: Requirements 7.5**

- [ ]* 7.2 Write property test for seller profile display
  - **Property 24: Seller profile display completeness**
  - **Validates: Requirements 7.3**

- [ ] 8. Implement property listing creation and management
  - Create PropertyListingService with CRUD operations
  - Build PropertyCreationViewModel with validation
  - Create property creation form SwiftUI view with all fields
  - Add image picker for property photos with multi-select
  - Implement property editing functionality
  - Add property deletion with confirmation
  - _Requirements: 1.1, 1.2, 1.3, 1.5, 2.2, 2.3, 2.4_

- [ ]* 8.1 Write property test for property creation with valid data
  - **Property 1: Property creation with valid data succeeds**
  - **Validates: Requirements 1.1**

- [ ]* 8.2 Write property test for image association persistence
  - **Property 2: Image association persistence**
  - **Validates: Requirements 1.2**

- [ ]* 8.3 Write property test for property deletion
  - **Property 7: Property deletion removes from storage**
  - **Validates: Requirements 2.4**

- [ ] 9. Build seller listing management views
  - Create MyListingsViewModel fetching seller's properties
  - Build seller listings list view with property cards
  - Add status management (active, pending, sold)
  - Implement listing status update functionality
  - _Requirements: 2.1, 2.5_

- [ ]* 9.1 Write property test for seller listing filtering
  - **Property 5: Seller listing filtering**
  - **Validates: Requirements 2.1**

- [ ]* 9.2 Write property test for sold listings exclusion
  - **Property 8: Sold listings excluded from buyer searches**
  - **Validates: Requirements 2.5**

- [ ] 10. Implement property filtering system
  - Create FilterService applying multiple filter criteria
  - Build PropertyFilters model with price range, type, location radius
  - Implement filter combination logic (AND operation)
  - Add filter validation and sanitization
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

- [ ]* 10.1 Write property test for price range filter
  - **Property 11: Price range filter correctness**
  - **Validates: Requirements 4.1**

- [ ]* 10.2 Write property test for property type filter
  - **Property 12: Property type filter correctness**
  - **Validates: Requirements 4.2**

- [ ]* 10.3 Write property test for location radius filter
  - **Property 13: Location radius filter correctness**
  - **Validates: Requirements 4.3**

- [ ]* 10.4 Write property test for multiple filter conjunction
  - **Property 14: Multiple filter conjunction**
  - **Validates: Requirements 4.4**

- [ ]* 10.5 Write property test for filter clearing
  - **Property 15: Filter clearing restores all active listings**
  - **Validates: Requirements 4.5**

- [ ] 11. Build property search and browse interface
  - Create PropertyListViewModel with filtering and pagination
  - Build property list view with cards showing key details
  - Add filter UI with price sliders, type checkboxes, location radius
  - Implement search results display
  - Add pull-to-refresh functionality
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

- [ ] 12. Implement property detail view
  - Create PropertyDetailViewModel managing detail state
  - Build property detail view with all information sections
  - Add image gallery with horizontal scroll
  - Implement full-screen image viewer with zoom
  - Display timestamps (created, updated)
  - Show seller profile information with contact details
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 7.3_

- [ ]* 12.1 Write property test for property detail display
  - **Property 16: Property detail display completeness**
  - **Validates: Requirements 5.1**

- [ ]* 12.2 Write property test for image gallery display
  - **Property 17: All property images displayed**
  - **Validates: Requirements 5.2**

- [ ]* 12.3 Write property test for timestamp display
  - **Property 18: Timestamp display in property details**
  - **Validates: Requirements 5.5**

- [ ] 13. Implement MapKit integration
  - Create LocationManager handling permissions and location updates
  - Build MapViewModel managing map state and annotations
  - Create custom property marker annotations
  - Implement marker clustering for nearby properties
  - Add map view centering on user location
  - Implement dynamic marker updates based on visible region
  - _Requirements: 3.1, 3.3, 3.4, 3.5_

- [ ]* 13.1 Write property test for active listings as markers
  - **Property 9: Active listings appear as map markers**
  - **Validates: Requirements 3.1**

- [ ]* 13.2 Write property test for marker clustering
  - **Property 10: Marker clustering for nearby properties**
  - **Validates: Requirements 3.5**

- [ ] 14. Build map view interface
  - Create MapView with property markers
  - Add marker tap gesture showing property preview
  - Implement property preview card with basic details
  - Add navigation from preview to full property detail
  - Integrate filter controls with map view
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [ ] 15. Implement favorites functionality
  - Create FavoritesService with add/remove operations
  - Build FavoritesViewModel managing favorites state
  - Add favorite button to property cards and detail view
  - Implement favorites list view
  - Add cascade delete when property is removed
  - Show favorite status indicator on all property views
  - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5_

- [ ]* 15.1 Write property test for favorite addition
  - **Property 34: Favorite addition**
  - **Validates: Requirements 11.1**

- [ ]* 15.2 Write property test for favorites retrieval
  - **Property 35: Favorites retrieval completeness**
  - **Validates: Requirements 11.2**

- [ ]* 15.3 Write property test for favorite removal
  - **Property 36: Favorite removal**
  - **Validates: Requirements 11.3**

- [ ]* 15.4 Write property test for cascading favorite deletion
  - **Property 37: Cascading favorite deletion**
  - **Validates: Requirements 11.4**

- [ ]* 15.5 Write property test for favorite status indication
  - **Property 38: Favorite status indication**
  - **Validates: Requirements 11.5**

- [ ] 16. Implement external listing API integration
  - Create ExternalListingAPIProtocol for third-party integrations
  - Implement data normalization from external formats to Property model
  - Create MLSAPIClient for MLS integration (with mock for testing)
  - Add source attribution to all external listings
  - Implement data validation and sanitization for external data
  - _Requirements: 8.1, 8.2, 8.3_

- [ ]* 16.1 Write property test for external listing normalization
  - **Property 27: External listing normalization**
  - **Validates: Requirements 8.1**

- [ ]* 16.2 Write property test for listing source attribution
  - **Property 28: Listing source attribution**
  - **Validates: Requirements 8.2**

- [ ]* 16.3 Write property test for external data validation
  - **Property 29: External data validation**
  - **Validates: Requirements 8.3**

- [ ] 17. Build multi-source listing aggregation
  - Create AggregationService coordinating multiple data sources
  - Implement duplicate detection and removal logic
  - Add conflict resolution with configurable prioritization rules
  - Implement parallel fetching from multiple sources
  - Add source-specific error handling
  - _Requirements: 9.1, 9.2, 9.5_

- [ ]* 17.1 Write property test for multi-source aggregation
  - **Property 30: Multi-source listing aggregation**
  - **Validates: Requirements 9.1**

- [ ]* 17.2 Write property test for duplicate elimination
  - **Property 31: Duplicate listing elimination**
  - **Validates: Requirements 9.2**

- [ ]* 17.3 Write property test for conflict resolution
  - **Property 32: Conflict resolution prioritization**
  - **Validates: Requirements 9.5**

- [ ] 18. Implement error handling and network resilience
  - Create AppError enum with all error categories
  - Implement retry logic with exponential backoff
  - Add user-facing error messages for all error types
  - Build error alert views
  - Implement request cancellation for timeouts
  - _Requirements: 10.1, 10.2, 10.5_

- [ ] 19. Build app navigation and tab structure
  - Create main TabView with Browse, Map, Favorites, Profile tabs
  - Implement NavigationStack for each tab
  - Add deep linking support for property details
  - Create navigation coordinator for complex flows
  - _Requirements: All (UI structure)_

- [ ] 20. Add AI service extensibility layer
  - Create AIServiceProtocol base interface
  - Define RecommendationEngineProtocol
  - Define NaturalLanguageSearchProtocol
  - Define ContentGenerationProtocol
  - Create mock implementations for future integration
  - Add feature flags for AI capabilities
  - _Requirements: Future extensibility_

- [ ] 21. Implement image handling and caching
  - Create ImageCache for memory and disk caching
  - Implement lazy image loading with placeholders
  - Add image compression for uploads
  - Create image upload service with progress tracking
  - Implement image deletion from storage
  - _Requirements: 1.2, 7.4_

- [ ] 22. Polish UI and add loading states
  - Add loading indicators for all async operations
  - Implement skeleton views for content loading
  - Add empty state views for lists
  - Create consistent button and form styles
  - Add animations for transitions
  - _Requirements: All (UI polish)_

- [ ] 23. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.
