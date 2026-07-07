# Context

## Fix APIOffer wire-decode bug + decode preloaded associations 06-07-2026
- Removed the explicit snake_case `CodingKeys` from `APIOffer` (APIRemoteDataSource.swift) and the public `Offer` model — they conflicted with `APIClient.decoder`'s `.convertFromSnakeCase` (keys rewritten to camelCase before CodingKey matching → guaranteed `keyNotFound` on every real offer response). Same bug class as the viewing DTOs fixed in 9ba2384; offer tests never caught it because they're all mock-routed
- Public `Offer` CodingKeys removal verified safe: no `decode(Offer.self)`/encode call sites, no Core Data OfferEntity — all constructions memberwise
- Bonus fix: `APIOffer.asOffer()` had hardcoded `property: nil, buyer: nil`, discarding associations the Go handlers preload (Buyer on submit/accept/reject/list, Property+Images on ListMyOffers). Added `property: APIProperty?`/`buyer: APIUser?` and wired them through — verified `APIUser` matches the non-hidden Go User json tags exactly (sensitive fields are `json:"-"`)
- Post-fix sweep: zero explicit CodingKeys remain in APIRemoteDataSource.swift — this bug class is extinct in the DTO layer
- New `OfferWireDecodingTests.swift`: 2 regression tests decoding realistic Go-shaped envelope JSON (nested buyer, mixed fractional/plain RFC3339 timestamps) through the real `APIClient.decoder`
- Suite: 271 tests, 0 failures; evaluator-verified (APPROVE)

## Viewing scheduling UI: seller slots, buyer requests 06-07-2026
- Backend counterpart: realdeal-api ab6323b (one-off slots, seller-approved requests, one buyer per slot, public slot list with computed `booked` flag)
- New `Models/Viewing/` (`ViewingSlot`, `ViewingRequest` + status enum), 9 operations added to `RemoteDataSourceProtocol`/`APIRemoteDataSource`/`MockRemoteDataSource`
- Buyer: PropertyDetailView action bar gains Request Viewing beside Make Offer — sheet lists open (non-booked, future) slots, optional message; live request shows as "Viewing Requested"/"Viewing Confirmed" with Cancel (pending or accepted)
- Seller: MyListingsView "Viewings" swipe action (mirrors "Offers") → SellerViewingsView: slot add (date pickers, client validation mirroring server rules)/delete with confirmation, requests grouped by slot with Accept/Decline; local state optimistically mirrors server transaction side effects (same convention as SellerOffersViewModel)
- **Evaluator REJECT round caught a real runtime bug**: the wire DTOs declared explicit snake_case `CodingKeys` while `APIClient.decoder` uses `.convertFromSnakeCase` — mutually exclusive, every real API response would throw `keyNotFound`. Undetected by 268 green tests because nothing decoded real JSON (all mock-routed). Fixed by dropping the CodingKeys (APIProperty's convention) and adding two wire-decode tests that pipe realistic Go-shaped envelope JSON through the real `APIClient.decoder`
- **Known pre-existing bug found in the process**: `APIOffer` (APIRemoteDataSource.swift ~385) has the identical CodingKeys+convertFromSnakeCase conflict — the offer flow (submit/list/accept) will fail to decode real API responses at runtime; never surfaced because offer tests are mock-only and the flow hasn't been live-tested from the app. Fix pending backlog decision
- Suite: 270 tests, 0 failures (16 ViewingSchedulingTests incl. the 2 wire-decode guards)

## Remove the agent user role — 2-user model (buyers + sellers) 05-07-2026
- Product decision: RealDeal is direct buyer↔seller ("Uber for private real estate sellers"); the realtor/agent concept is removed entirely. Backend (realdeal-api) needed zero changes — its UserRole was already buyer/seller only; this was an iOS-only removal
- `UserRole.swift`: removed `.agent` case and the `requiresLicenseNumber` property; enum is now `.buyer`/`.homeowner` (homeowner still maps to API "seller")
- Removed `licenseNumber` end-to-end: `UserProfile`, `AuthViewModel` (registration state, validation block, form reset), `LocalDataSource` mappings, and all three Core Data layers — the `.xcdatamodeld` contents (missed by the initial code map — the compiled model is the primary one; the programmatic model in `PersistenceController` is only a fallback), `UserProfileEntity+CoreDataProperties`, and the programmatic attribute
- Core Data migration: lightweight migration already enabled (`shouldMigrateStoreAutomatically`/`shouldInferMappingModelAutomatically`); attribute removal migrates cleanly, with an existing delete-and-retry fallback for incompatible stores (dev-only data)
- Role→API mapping simplified in `APIAuthenticationService` and `APIRemoteDataSource` (`.homeowner` → "seller"); role pickers iterate `UserRole.allCases` so the UI adapted automatically; agent mentions scrubbed from `MainTabView` copy and View previews
- KEPT `ListingSource.realtor` + AggregationService priorities — listing data source, not a user role
- Tests: deleted 7 agent/license tests (including two now-vacuous licence-number checks), renamed the case-count test to assert 2 roles, simplified homeowner registration test, updated LocalDataSource fixture — suite green (253 passed, 0 failed), verified independently by reviewer
- First task run through the orchestrator pipeline: researcher (code map) → executor (implementation) → evaluator (independent review + test run, APPROVE) → committer

## Text search on the Search (formerly Browse) tab 03-07-2026
- Tab renamed Browse → Search (magnifyingglass icon); heading "Browse Properties" → "Search Properties"
- Toolbar gains a "Search" button right of "Filters" (flow may change later): opens a sheet with a single text field; Search applies, Clear Search (shown only when active) resets; blue dot on the button while a search is active (same convention as Filters)
- `PropertyFilters.searchText` → sent as `q` to the lookup service (`APIRemoteDataSource`); `PropertyListViewModel.loadProperties`/`loadMoreProperties` now pass the filters object to the repository so search + filters are **server-side** (was `filters: nil` + client-only filtering); `FilterService.applySearchTextFilter` mirrors the q matching (street/city/description, case-insensitive) for cache/mock paths
- `applySearch`/`clearSearch`/`hasActiveSearch` on PropertyListViewModel; verified live: `GET /api/v1/search/properties?q=Oak` from the app in the gateway log, result list narrowed, clear restored
- New `testApplySearchTextFilter` in FilterServiceTests
- Note: LocalStack has no persistent volume — uploaded images vanish when the Docker daemon restarts (broken-image icon on old listings); dev-only behavior

## Listing form: state/province dropdown per country 11-06-2026
- State/Province is a Picker fed by the backend: `config/countries` now returns each supported country with its subdivisions (`SupportedCountry`/`CountrySubdivision` types on `RemoteDataSourceProtocol`); picker shows names, stores codes; countries without a list fall back to free text
- Switching country clears a province that isn't valid for the new country (Combine sink on `$country`); `loadSupportedCountries` reconciles both country and province
- Label still adapts (State for US, Province otherwise); server validates state codes against the same list (realdeal-api d7ffd9b)
- 2 new tests (subdivisions follow selected country; switching clears foreign province) — 261 green

## Listing form: Year Built picker 10-06-2026
- Year Built is a Picker (matching bedrooms/bathrooms): newest-first from next year (new construction) back to 1800, "Select" empty state; `PropertyCreationViewModel.selectableYears` matches the server's validation range

## Listing form: validation-guided navigation 10-06-2026
- Create/Update button is always tappable (disabled only mid-save) — no more greyed-out text with no explanation
- Tapping with missing fields scrolls (ScrollViewReader + section `.id`s) to the first incomplete section in form order; each missing field shows its red "… is required" error beneath the input (the red "— must have a value" header suffix was tried and removed per feedback — per-field errors only)
- `PropertyCreationViewModel`: `FormSection` enum (address/basicInfo/specifications), `incompleteSections` set + `firstInvalidSection` computed in `validateForm()`, cleared when the form is valid
- 3 new tests: empty form flags all sections and targets address, ordering follows the form (price-only gap targets basicInfo), valid form clears flags — 259 tests green

## Listing form follow-ups: year built required, lot size removed, toolbar fix 10-06-2026
- Year Built is required (number pad, validated 1800..next year, mirrors server); Lot Size removed from the form and viewmodel (model keeps `lotSize` for MLS-imported display — 40 references across mocks/validators untouched)
- Create/Update toolbar button: removed `.primaryButtonStyle` (drew a gray pill that looked like a stray square in the navigation bar); plain toolbar button with `.disabled(!canSave || isLoading)`
- New test: implausible year built blocks save — 256 tests green

## Listing form: country dropdown, geocoding, required specs 10-06-2026
- Country is a Picker fed by `GET /api/v1/config/countries` (backend = single source of truth; `fetchSupportedCountries` on RemoteDataSource/PropertyRepository protocols with US/CA defaults so mocks and offline keep working); stores ISO alpha-2 codes, displays `Locale.localizedString(forRegionCode:)` names; selection reconciles if the backend drops a country
- Postal field adapts to country: "ZIP Code" + number-ish keyboard for US, "Postal Code" otherwise; validation mirrors the server (US/CA regexes in `PropertyCreationViewModel.postalCodeError`); State/Province label adapts too
- **Coordinates are geocoded from the address** (CLGeocoder via injectable `geocode` closure) on create/update — the Location Coordinates section is gone; geocode failure blocks save with a user-facing error
- Specifications are required: bedrooms (0–10) and bathrooms (0–6 in halves) are Pickers, square feet a required numeric field; lot size/year built explicitly marked optional
- DTOs renamed `zipCode` → `postalCode` (snake-case strategy makes the wire field `postal_code`, matching the API rename)
- 5 new tests in `PropertyCreationFormTests` (stubbed geocoder): geocode success populates coords, failure blocks save, missing specs block save, per-country postal rules, supported-countries load + selection reconcile — 255 tests green

## Remove broken RealDealUITests target 10-06-2026
- Root cause of "Failed to load the test bundle. The bundle's executable couldn't be located": the `RealDealUITests` native target had an empty `fileSystemSynchronizedGroups = ()` and no `RealDealUITests/` source folder exists on disk, so the target compiled zero sources and produced an `.xctest` bundle with no executable
- Deleted the dead target from `RealDeal.xcodeproj/project.pbxproj` (file reference, Products entry, native target, 3 empty build phases, target dependency + container proxy, TargetAttributes entry, Debug/Release build configs, and config list) — the project has no shared scheme, so Xcode's autogenerated scheme was pulling the broken target into every test run
- Full `xcodebuild test` (and `make test`) now passes without `-only-testing:RealDealTests`; re-add UI tests later via Xcode's UI Testing Bundle template if wanted

## Add sign-out UI 10-06-2026
- `ProfileView`: "Sign Out" button on own profile (above Delete Profile), driven by an optional `onSignOut` closure; neutral styling vs. the destructive delete
- `MainTabView`/`ProfileTab`: wires `onSignOut` to `authViewModel.signOut()`; after sign-out the Profile tab flips to `LoginView` via the existing `isAuthenticated` switch
- `AuthViewModel.signOut()` now also clears `needsProfileSetup` so signing out mid-wizard dismisses it
- Added `testSignOutClearsProfileSetupFlag` to ProfileSetupFlowTests

## Profile setup wizard after sign-up 10-06-2026
- Created `RealDeal/Views/ProfileSetupView.swift`: 3-step onboarding wizard (About You → Your Role → Privacy) presented full-screen after account creation; Skip always available since the account already exists server-side; Finish PUTs via `ProfileViewModel.updateProfile()` and only dismisses on success
- `AuthViewModel`: added `@Published needsProfileSetup` (set on successful `signUp()`, not on sign-in) and `completeProfileSetup(updatedProfile:)` which also syncs `currentUser`
- `MainTabView`: presents the wizard via `fullScreenCover` bound to `needsProfileSetup`; extracted private `ProfileTab` wrapper owning `ProfileViewModel` as `@StateObject` — fixes the root "Profile Not Found" bug where the view model was created inline in `body` and replaced (unloaded) on every re-render
- `ProfileTab` reload is keyed on `"\(userId)-\(setupWizardActive)"`: the tab loads while the wizard covers it, so it must reload on wizard dismissal or it shows the pre-wizard profile (found via live simulator verification — role displayed stale "Buyer" while the backend already had "seller")
- Verified end-to-end in the simulator against the local gateway stack: signup → wizard (name prefilled) → Owner role selected → Finish → profile screen immediately shows Homeowner; backend `users.role` = seller; iOS "homeowner" ↔ API "seller"
- Noted: the app has no sign-out UI anywhere (worked around in testing via `xcrun simctl keychain reset`)
- `ProfileView`: empty state now passes `onSetupProfile` to `EmptyStateView.profileNotFound(onCreate:)` so a profile-less user can open the wizard instead of hitting a dead end (own profile only)
- Added `RealDealTests/ProfileSetupFlowTests.swift`: 5 tests — signup triggers wizard, failed signup doesn't, finish clears flag + syncs user, skip leaves user untouched, sign-in never triggers wizard
- All 248 unit tests pass. Note: `RealDealUITests` bundle fails to load on this machine ("executable couldn't be located") — pre-existing target/DerivedData issue, unrelated; use `-only-testing:RealDealTests`

## Adopt lookup search endpoint for browsing 10-06-2026
- `APIRemoteDataSource.fetchProperties` now calls `GET /api/v1/search/properties` (lookup service through the gateway) with the search API's param names: min_price, max_price, beds, baths, property_type (comma-joined), source (comma-joined), seller_id, lat/lon/radius_miles
- `ContentView`: `creaDataSource` set to nil — browse now shows real backend listings instead of the mock MLS feed (PropertyRepository previously short-circuited through MockCREADataSource before ever reaching the real API)
- Entity CRUD (`GET/POST/PUT/DELETE /api/v1/properties...`) stays on core; only browse/search reads moved
- Backend counterpart: lookup search gained seller_id, source, and geo-radius filters (realdeal-api commit 00b8fdb) so no client capability was lost

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

