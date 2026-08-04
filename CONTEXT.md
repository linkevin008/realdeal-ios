# Current State

*Rewrite this section after each task — it is the first thing a new session reads.*

**App**: SwiftUI, 5 tabs — Search (browse + text search + filters), Map, Favorites, My Listings (sellers), Profile. Points at `http://localhost:8080` (the gateway) in dev; the same base URL will point at the ALB once deployed.

**Built and live-verified**: auth + post-signup profile wizard + sign-out · listing creation (country/state dropdowns from the backend, geocoded coordinates, required specs, photo upload via presign) · search with server-side filters · offers (submit, seller accept/reject) · viewings (seller slots, buyer requests) · **contract signing wizard** (terms → agree → sign → executed, three entry points incl. My Contracts on Profile) · My Listings across active/pending/sold.

**Not built**: escrow/payment UI (next major slice, waits on the Stripe backend) · legal consent form · walkthrough/explainer bubbles · theming.

**Known gaps**: no automated integration/UI coverage — every integration bug we've shipped was caught by hand-driving the simulator (P1 in the backlog, and the highest-value unfinished work). Contract-row polish (street names, "Signed" vs "Agreed" label) is P2.

# Conventions

*Hard-won rules. Each one here cost us a shipped bug.*

- **NEVER declare explicit `CodingKeys` on wire DTOs or models.** `APIClient.decoder` uses `.convertFromSnakeCase`, which rewrites keys before CodingKey matching — declaring them guarantees `keyNotFound` on every real response. This shipped twice (viewing DTOs, then `APIOffer`) and mock-routed tests cannot catch it.
- **`APIClient.encoder` uses `.iso8601`** so `Date` fields serialize as RFC3339 strings; Go's `time.Time` binding rejects the raw numbers that `.deferredToDate` produces. Any new Date-carrying request body inherits this automatically.
- **Wire-decode tests must pipe realistic Go-shaped JSON through the REAL `APIClient.decoder`** (see `OfferWireDecodingTests`). Mock-routed tests never cross the wire boundary and prove nothing about decoding.
- **List rows: every action button needs `.buttonStyle(.borderless)`** — default-styled Buttons in a List row all fire on a single tap (tapping Reject once accepted the offer first).
- **Wrap a card in `Button` only when it actually has an action** (`onTap != nil`). An unconditional Button wrapper swallows taps when the card is embedded in a `NavigationLink` — this silently broke every listing tap in browse and favorites.
- **View models belong in a `@StateObject` on a small wrapper view**, never constructed inline in a parent's `body` — inline construction replaces (and un-loads) them on every re-render. That was the root cause of the phantom "Profile Not Found".
- **Live verification is required for UI/wiring changes.** The unit suite is structurally blind to integration bugs: 4 shipped bugs found in one smoke session (07-07), plus the My Listings gap (14-07). Green tests are necessary, not sufficient.
- **Simulator driving**: pass the device UDID to `xcrun simctl pbcopy` when more than one simulator is booted (`booted` is ambiguous), and paste text with `cmd+v` rather than synthetic typing (which triggers the accent picker and garbles input).

# Context

*Newest first. Older entries live in `CONTEXT-ARCHIVE.md`.*

## My Listings shows pending/sold listings 19-07-2026
- `fetchMyListings()` added to RemoteDataSourceProtocol (API impl hits the authed `GET /api/v1/users/me/listings`, realdeal-api bb6adad; mock returns the current user's non-deleted listings newest-first)
- `PropertyRepositoryProtocol.fetchMyListings(sellerId:)` with a default extension (fetch-all + filter by seller, excluding deleted) so other conformers keep compiling; `PropertyRepository` overrides remote-first with NO CREA involvement (account data, not listing search) and falls back to the seller-filtered local cache offline
- `PropertyListingService.fetchSellerProperties` now delegates to the repository method — the old fetch-everything-from-active-only-search-then-filter approach is gone (that was the bug: an accepted listing goes pending, leaves the search feed, and disappeared from My Listings along with its Offers path)
- No UI work needed: `MyListingsView` already renders StatusBadge + per-status filter chips
- 2 new tests assert exact id-set membership (deleted and other-seller listings excluded); 301 green; evaluator APPROVE
- Verified live: seller's My Listings shows "789 Pine Street" with a Pending badge and working Offers swipe action

## Contract/signing wizard + RFC3339 date encoding 14-07-2026
- `ContractWizardView`: state-driven (not step-driven) wizard against the contract API — progress dots (Terms/Agreement/Signatures), deadline countdown, terms display with propose/edit form (re-proposal warning: voids other party's agreement + signatures), role-relative Agreement/Signing sections, documents stub row, cancel with confirmation, terminal screens; pull-to-refresh + toolbar refresh
- Entry points: buyer's PropertyDetailView (accepted offer keeps the action bar alive after the listing leaves search), seller's accepted offer rows in SellerOffersView, and **My Contracts** on the own-profile screen (`GET /users/me/contracts`) — the guaranteed path for both parties
- Data layer: `Contract`/`ContractStatus` models + 6 protocol methods; `APIContract` DTO with NO CodingKeys; MockRemoteDataSource simulates the full state machine; 23 tests incl. wire-decode through the real decoder (commit c715c8f)
- **Encoder fix** (commit 89d0c90): `APIClient.encoder` had no dateEncodingStrategy → Dates went out as raw numbers that Go's time.Time binding rejects; found by the evaluator during wizard review. One shared `.iso8601` strategy fixed contract terms AND the already-shipped viewing-slot creation bug; 4 encode-side tests pin the format
- **Live two-party walkthrough verified end-to-end** (real stack, two accounts): seller proposes dated terms (PUT /contract/terms → 200 — the request class that 400'd pre-fix), buyer agrees + signs via My Contracts, seller counter-signs → "Contract Executed"; DB: status executed, both signatures, property stays pending for escrow
- Found live and backlogged: My Listings omitted the seller's own pending/sold listings (fixed 19-07); polish items as P2

## Live smoke test of offer + viewing flows; 4 integration bugs fixed 07-07-2026
- First live run of the full buyer↔seller funnel in the simulator against the real local stack; all four bugs were invisible to the 272-test unit suite because they live at integration boundaries (wire shapes, gesture composition, view nesting, dependency injection) that mock-routed tests never cross
- **Bug 1 — nested-slot decode**: `APIViewingSlot.booked` was non-optional but `booked` only exists on the slot-LIST endpoint's computed response → seller's Viewings screen failed to load. Fixed: `Bool?` + `?? false`; fixtures must mirror the real payload per endpoint
- **Bug 2 — List-row double-action**: default-styled Buttons in List rows fire ALL row actions on one tap (tapping Reject would ACCEPT the offer first). Fixed with `.buttonStyle(.borderless)` on all 4 action buttons
- **Bug 3 — dead property cards (P0)**: `PropertyCardView` unconditionally wrapped content in a `Button`; browse + favorites embed it in `NavigationLink`, so the no-op Button swallowed every tap — buyers could not open ANY listing. Fixed: Button wrapper conditional on `onTap != nil`
- **Bug 4 — nil remote in detail**: `MainTabView.destinationView` built `PropertyDetailViewModel` without `remoteDataSource` → no state badges, empty Make Offer sheet; failed silently because state checks swallow errors
- Takeaway: this bug class needs automated integration coverage (XCUITest happy path against `make up`) — backlogged P1

## Fix APIOffer wire-decode bug + decode preloaded associations 06-07-2026
- Removed the explicit snake_case `CodingKeys` from `APIOffer` and the public `Offer` model — they conflicted with `.convertFromSnakeCase` (guaranteed `keyNotFound` on every real offer response). Same bug class as the viewing DTOs; offer tests never caught it because they're all mock-routed
- Bonus fix: `APIOffer.asOffer()` had hardcoded `property: nil, buyer: nil`, discarding associations the Go handlers preload. Added and wired them through
- Post-fix sweep: zero explicit CodingKeys remain in APIRemoteDataSource.swift — this bug class is extinct in the DTO layer
- New `OfferWireDecodingTests.swift`: 2 regression tests decoding realistic Go-shaped envelope JSON through the real decoder

## Viewing scheduling UI: seller slots, buyer requests 06-07-2026
- Backend counterpart: realdeal-api ab6323b (one-off slots, seller-approved requests, one buyer per slot)
- New `Models/Viewing/`, 9 operations added across the data-source protocols
- Buyer: PropertyDetailView action bar gains Request Viewing beside Make Offer — sheet lists open future slots; live request shows as "Viewing Requested"/"Viewing Confirmed" with Cancel
- Seller: MyListingsView "Viewings" swipe action → SellerViewingsView: slot add/delete, requests grouped by slot with Accept/Decline; local state optimistically mirrors server transaction side effects
- **Evaluator REJECT round caught a real runtime bug**: the CodingKeys/convertFromSnakeCase conflict, undetected by 268 green tests because nothing decoded real JSON

## Remove the agent user role — 2-user model (buyers + sellers) 05-07-2026
- Product decision: RealDeal is direct buyer↔seller; the realtor/agent concept is removed entirely. Backend needed zero changes — its UserRole was already buyer/seller only
- `UserRole` is now `.buyer`/`.homeowner` (homeowner maps to API "seller"); `licenseNumber` removed end-to-end including all three Core Data layers (the `.xcdatamodeld` contents are the primary compiled model — the programmatic one in `PersistenceController` is only a fallback)
- Lightweight Core Data migration handles the attribute removal; KEPT `ListingSource.realtor` (listing data source, not a user role)
- First task run through the full orchestrator pipeline: researcher → executor → evaluator (APPROVE) → committer

## Text search on the Search (formerly Browse) tab 03-07-2026
- Tab renamed Browse → Search (magnifyingglass icon); heading "Search Properties"
- Toolbar "Search" button beside "Filters" opens a sheet with a single text field; blue dot while active; Clear Search resets
- `PropertyFilters.searchText` → sent as `q` to the lookup service; `PropertyListViewModel` now passes the filters object to the repository so search + filters are **server-side** (was `filters: nil` + client-only filtering); `FilterService.applySearchTextFilter` mirrors q matching for cache/mock paths
- Verified live: `GET /api/v1/search/properties?q=Oak` in the gateway log, list narrowed, clear restored
