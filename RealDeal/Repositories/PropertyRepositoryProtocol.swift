import Foundation

protocol PropertyRepositoryProtocol {
    func fetchProperties(filters: PropertyFilters?) async throws -> [Property]
    func createProperty(_ property: Property) async throws -> Property
    func updateProperty(_ property: Property) async throws
    func deleteProperty(id: String) async throws
    func getProperty(id: String) async throws -> Property?
}
