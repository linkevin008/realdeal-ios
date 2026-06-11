import Foundation

protocol PropertyRepositoryProtocol {
    func fetchProperties(filters: PropertyFilters?) async throws -> [Property]
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
}
