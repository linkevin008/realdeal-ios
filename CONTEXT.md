# Responsibilities
- This repo is for the app's iOS logic, app code
- The app's code should be low latency

# Backlog
- [x][P0] Implement photo upload functionality
- [x][P0] Symlink the upper CLAUDE.md file to all other repos
- [ ][P1] After sign-up, route new users to a "Complete Your Profile" onboarding flow instead of showing the "Profile Not Found" empty state — ProfileViewModel fetches from the repo independently of auth, so a brand new user lands on an empty state that looks like an error
- [ ][P2] Decide on color scheme and theme
- [ ][P1] Implement legal consent form
- [ ][P2] Do we want to implement a chat feature?
- [ ][P1] Create informational walk through and explanation bubbles   

# Context

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

