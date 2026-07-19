import Foundation

protocol PropertyRepositoryProtocol {
    func fetchProperties(filters: PropertyFilters?) async throws -> [Property]
    /// The given seller's own listings across active/pending/sold (deleted
    /// excluded) — used by My Listings so a seller's listing stays visible
    /// once an offer is accepted (pending) or the sale completes (sold).
    func fetchMyListings(sellerId: String) async throws -> [Property]
    func createProperty(_ property: Property) async throws -> Property
    func updateProperty(_ property: Property) async throws
    func deleteProperty(id: String) async throws
    func getProperty(id: String) async throws -> Property?
    /// Countries listings can be created in, with their state/province codes
    /// (backend-owned list).
    func fetchSupportedCountries() async throws -> [SupportedCountry]
}

extension PropertyRepositoryProtocol {
    /// Default mirrors the backend's launch countries so mocks keep working
    /// (empty subdivisions — the form falls back to free text).
    func fetchSupportedCountries() async throws -> [SupportedCountry] {
        [SupportedCountry(code: "US", subdivisions: []),
         SupportedCountry(code: "CA", subdivisions: [])]
    }

    /// Degraded default: fetch everything the repository knows about and
    /// filter client-side by seller. Fine for mocks/tests and any future
    /// conformer that has no dedicated "my listings" endpoint; `PropertyRepository`
    /// overrides this with a call to the real `/users/me/listings` endpoint so
    /// pending/sold listings aren't lost behind the active-only search filter.
    func fetchMyListings(sellerId: String) async throws -> [Property] {
        let allProperties = try await fetchProperties(filters: nil)
        return allProperties.filter { $0.sellerId == sellerId && $0.status != .deleted }
    }
}
