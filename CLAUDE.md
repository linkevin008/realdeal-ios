# Responsibilities
- This repo is for the app's iOS logic, app code
- The app's code should be low latency

# Commands
- Unit tests: `make test` (xcodebuild test, simulator: iPhone 17 Pro)
- Build only: `make build` (or `xcodebuild -project RealDeal.xcodeproj -scheme RealDeal -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`)
- Run in simulator: `make run` (boot + install + launch)
- Coverage: `make coverage`
- The app talks to the local gateway stack — start it with `make up` in realdeal-api when testing live flows

# Backlog
Priority: P0 = important/must have, P1 = need to have but not crucial, P2 = nice to have

- [x][P0] Implement photo upload functionality
- [x][P0] Symlink the upper CLAUDE.md file to all other repos
- [x][P0] Implement buying functionality — offer submission and seller offer management
- [x][P1] After sign-up, route new users to a "Complete Your Profile" onboarding flow instead of showing the "Profile Not Found" empty state — ProfileViewModel fetches from the repo independently of auth, so a brand new user lands on an empty state that looks like an error
- [x][P1] Adopt the lookup service's /api/v1/search/properties endpoint for property browsing
- [x][P1] Add sign-out UI — the app previously had no way to sign out anywhere
- [x][P0] Remove the agent role from the app — drop the .agent registration option, license-number field/validation, and agent-specific tests (2-user model: buyers + sellers; coordinate with realdeal-api)
- [x][P0] Viewing requests UI: sellers set availability windows on a listing; buyers request a viewing against those windows
- [x][P0] Contract/signing wizard UI: after a bid is accepted, guide both parties through signing the required documents (documents stubbed for MVP; wire the real signing state machine) → state-driven wizard + My Contracts entry point; live-verified two-party flow through executed
- [x][P1] My Listings should include the seller's own non-active listings (pending/sold) — found in live contract walkthrough: an accepted listing goes pending, drops out of the active-only search feed, and vanishes from My Listings, breaking the seller's offers-row path to the contract (My Contracts on Profile is the workaround)
- [ ][P2] Contract wizard polish: My Contracts rows show generic "Property" instead of the street (enrich from property), and the Signing section labels a signature "Agreed" where "Signed" would be clearer
- [ ][P0] Escrow/payment UI: collect the buyer's payment details to fund escrow after both parties sign; reflect the sold state once the transaction completes
- [ ][P2] Decide on color scheme and theme
- [x][P0] Fix APIOffer wire-decode bug: explicit snake_case CodingKeys conflict with APIClient's .convertFromSnakeCase — offer flow (submit/list/accept) fails to decode real API responses at runtime; remove the CodingKeys and add a wire-decode test (same fix as the viewing DTOs, see 06-07-2026 context entry)
- [ ][P1] Implement legal consent form
- [ ][P2] Do we want to implement a chat feature?
- [ ][P1] Create informational walk through and explanation bubbles
