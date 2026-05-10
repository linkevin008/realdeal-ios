# Responsibilities
- This repo is for the app's iOS logic, app code
- The app's code should be low latency

# Backlog
- [x][P0] Implement photo upload functionality
- [x][P0] Symlink the upper CLAUDE.md file to all other repos
- [x][P0] Implement buying functionality — offer submission and seller offer management
- [ ][P1] After sign-up, route new users to a "Complete Your Profile" onboarding flow instead of showing the "Profile Not Found" empty state — ProfileViewModel fetches from the repo independently of auth, so a brand new user lands on an empty state that looks like an error
- [ ][P2] Decide on color scheme and theme
- [ ][P1] Implement legal consent form
- [ ][P2] Do we want to implement a chat feature?
- [ ][P1] Create informational walk through and explanation bubbles   

# Context

## Implement offer flow iOS 10-05-2026
- Created `RealDeal/Models/Offer/Offer.swift`: `Offer` struct (Codable, Identifiable) with `OfferStatus` enum (pending/accepted/rejected/withdrawn); snake_case CodingKeys mapping
- Added 6 offer methods to `RemoteDataSourceProtocol`: submitOffer, fetchOffersForProperty, acceptOffer, rejectOffer, withdrawOffer, fetchMyOffers
- Updated `APIRemoteDataSource`: implemented all 6 methods using existing `APIClient` patterns; added private `APIOffer` DTO and `EmptyBody` for PUT calls with no body
- Updated `MockRemoteDataSource`: added in-memory `offers` store; stub implementations for all 6 methods; `submitOffer` returns a real mock offer for UI testing
- Created `RealDeal/ViewModels/OfferViewModel.swift`: `@Published` amount, message, isSubmitting, errorMessage, submittedOffer; validates amount > 0 before submitting
- Created `RealDeal/Views/SubmitOfferView.swift`: Form sheet with $ amount field (decimal keyboard), optional message, Submit/Cancel toolbar buttons, loading overlay
- Updated `PropertyDetailViewModel`: added `isShowingOfferSheet`, `myPendingOffer`, `remoteDataSource` dependency, `isSeller` computed var, `checkMyPendingOffer()` async method
- Updated `PropertyDetailView`: added `safeAreaInset` bottom bar — "Make Offer" button for buyers on active listings, "Offer Pending" badge if buyer already has a pending offer; presents `SubmitOfferView` as sheet
- Created `RealDeal/ViewModels/SellerOffersViewModel.swift`: loadOffers, accept (transaction: updates accepted + rejects others locally), reject; all via `RemoteDataSourceProtocol`
- Created `RealDeal/Views/SellerOffersView.swift`: list of offers with buyer name, amount, status badge; Accept/Reject buttons for pending offers; pull to refresh
- Updated `MyListingsViewModel`: added `remoteDataSource: RemoteDataSourceProtocol` parameter (defaults to `MockRemoteDataSource` for backwards compat)
- Updated `MyListingsView`: added leading swipe action "Offers" on each listing; tapping presents `SellerOffersView` in a sheet; added `offersProperty` state
- Updated `MainTabView`: added `remoteDataSource` parameter (defaulted); passes through to `MyListingsViewModel`
- Updated `ContentView`: passes `remoteDataSource` to `MainTabView`

## Fix SwiftCheck dependency and simulator name 28-04-2026
- Added SwiftCheck (`0.12.0`) to `RealDeal.xcodeproj/project.pbxproj`: remote package reference, product dependency, and wired to `RealDealTests` target
- Fixed simulator name in `Makefile` from `iPhone 16 Pro` (no longer exists) to `iPhone 17 Pro`
- Updated `SIM_ID` in `realdeal-api/Makefile` to match `iPhone 17 Pro` UUID
- Tests now build and run; 2 test logic failures remain: `BackendIntegrationTests.testAggregationServiceCustomPrioritization`, `UserRoleTests.testAgentWithEmptyLicenseNumberFailsFormValidation`

## Implement APIImageStorage presign upload 03-05-2026
- Created `RealDeal/Services/APIImageStorage.swift`: `APIImageStorage` implementing `ImageStorageProtocol` using the presign flow — calls `POST /api/v1/upload/presign`, then PUTs image bytes directly to S3 (no Authorization header on the S3 PUT); returns CloudFront `public_url`
- Path-to-upload_type mapping: `properties/` → `property`, `profiles/` → `profile`, `id_verification/` → `id_verification`, default → `property`
- `deleteImage` and `deleteImages` throw `APIError.notSupported` (not yet implemented)
- `uploadImages` batches sequential `uploadImage` calls
- Updated `APIClient.swift`: added a second initializer `init(baseURL:keychainManager:session:)` for session injection in unit tests
- Updated `APIRemoteDataSource.swift`: added `private let imageStorage: APIImageStorage`; `uploadImage` and `deleteImage` delegate to `imageStorage` instead of throwing `notSupported`
- Created `RealDealTests/APIImageStorageTests.swift`: tests for each path-to-upload_type prefix, two-step call sequence (presign POST + S3 PUT), no Authorization header on S3 PUT, correct public URL returned, and notSupported errors for delete operations; uses `SpyURLSession` (URLSession subclass) with pre-configured responses

## Fix two failing iOS tests 03-05-2026
- Added agent license number validation to `validateRegistrationForm()` in `AuthViewModel.swift`: blocks sign-up and sets `licenseNumberValidationError` when `registerRole == .agent` and `registerLicenseNumber` is empty
- Added MLS-006 listing ("123 Oak Street, Toronto, ON") to `MockMLSAPIClient.createSampleListings()` so `testAggregationServiceCustomPrioritization` has a conflicting MLS property to resolve against the user-generated one; MLS now wins with the custom priority config (MLS: 100 vs userGenerated: 50)
- All tests pass

