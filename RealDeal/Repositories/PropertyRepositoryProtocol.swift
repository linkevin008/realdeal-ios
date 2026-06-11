import Foundation

protocol PropertyRepositoryProtocol {
    func fetchProperties(filters: PropertyFilters?) async throws -> [Property]
    func createProperty(_ property: Property) async throws -> Property
    func updateProperty(_ property: Property) async throws
    func deleteProperty(id: String) async throws
    func getProperty(id: String) async throws -> Property?
    /// ISO codes of countries listings can be created in (backend-owned list).
    func fetchSupportedCountries() async throws -> [String]
}

extension PropertyRepositoryProtocol {
    /// Default mirrors the backend's launch list so mocks keep working.
    func fetchSupportedCountries() async throws -> [String] {
        ["US", "CA"]
    }
}
