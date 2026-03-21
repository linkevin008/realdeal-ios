import Foundation

/// Protocol for integrating with the CREA Data Distribution Facility (DDF)
/// Implementations may talk to the DDF directly or via a wrapper such as Repliers.
protocol CREADataSourceProtocol {
    /// Fetch listings from CREA DDF with optional filters
    func fetchListings(filters: PropertyFilters?) async throws -> [Property]
    /// Fetch a single listing by its DDF listing key
    func fetchListing(ddfListingKey: String) async throws -> Property?
    /// Fetch listings updated since a given date (for incremental sync)
    func fetchUpdatedListings(since: Date) async throws -> [Property]
}
