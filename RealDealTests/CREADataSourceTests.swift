import XCTest
@testable import RealDeal

@available(iOS 15.0, macOS 12.0, *)
final class CREADataSourceTests: XCTestCase {

    var dataSource: MockCREADataSource!

    override func setUp() async throws {
        try await super.setUp()
        dataSource = MockCREADataSource(simulateNetworkDelay: false)
    }

    override func tearDown() async throws {
        dataSource = nil
        try await super.tearDown()
    }

    // MARK: - fetchListings (no filters)

    func testFetchListingsWithNoFilterReturnsAllSampleListings() async throws {
        // Given: the mock data source with no active-status overrides

        // When: fetching without filters
        let listings = try await dataSource.fetchListings(filters: nil)

        // Then: all 11 sample listings are returned (all are .active)
        XCTAssertEqual(listings.count, 11, "MockCREADataSource should return all 11 sample listings when no filter is applied")
    }

    func testFetchListingsAllHaveCREASource() async throws {
        // Given/When
        let listings = try await dataSource.fetchListings(filters: nil)

        // Then: every listing must carry the .crea source tag
        let nonCREA = listings.filter { $0.source != .crea }
        XCTAssertTrue(nonCREA.isEmpty, "All CREA listings must have source == .crea; found: \(nonCREA.map(\.id))")
    }

    func testFetchListingsAllHaveNonEmptyIDs() async throws {
        // Given/When
        let listings = try await dataSource.fetchListings(filters: nil)

        // Then: every listing has a non-empty id (valid DDF listing key)
        for listing in listings {
            XCTAssertFalse(listing.id.isEmpty, "Listing at address '\(listing.address.street)' must have a non-empty DDF listing key")
        }
    }

    // MARK: - fetchListings (price filter)

    func testPriceFilterMaxExcludesPropertiesAboveThreshold() async throws {
        // Given: a max price of $600,000 CAD
        let filters = PropertyFilters(priceMax: 600_000)

        // When
        let listings = try await dataSource.fetchListings(filters: filters)

        // Then: all returned properties are priced at or below $600,000
        for listing in listings {
            XCTAssertLessThanOrEqual(
                listing.price,
                600_000,
                "Listing \(listing.id) priced at \(listing.price) exceeds the $600,000 max filter"
            )
        }
        // Sanity check: the filter should actually exclude something
        XCTAssertFalse(listings.isEmpty, "There should be at least one listing under $600,000")
    }

    func testPriceFilterExcludesAllOverMaxPrice() async throws {
        // Given: a very high max price that lets everything through
        let filters = PropertyFilters(priceMax: 10_000_000)
        let allListings = try await dataSource.fetchListings(filters: nil)
        let filteredListings = try await dataSource.fetchListings(filters: filters)

        // Then: a high ceiling returns the same count as no filter
        XCTAssertEqual(filteredListings.count, allListings.count, "A ceiling higher than all prices should return all listings")
    }

    func testPriceFilterMinExcludesPropertiesBelowThreshold() async throws {
        // Given: a min price of $1,000,000
        let filters = PropertyFilters(priceMin: 1_000_000)

        // When
        let listings = try await dataSource.fetchListings(filters: filters)

        // Then: no listing is priced below $1,000,000
        for listing in listings {
            XCTAssertGreaterThanOrEqual(
                listing.price,
                1_000_000,
                "Listing \(listing.id) priced at \(listing.price) is below the $1,000,000 min filter"
            )
        }
    }

    // MARK: - fetchListing(ddfListingKey:)

    func testFetchListingByKnownKeyReturnsCorrectProperty() async throws {
        // Given: a known DDF listing key from the sample data
        let knownKey = "DDF_100000001"

        // When
        let property = try await dataSource.fetchListing(ddfListingKey: knownKey)

        // Then: the correct property is returned
        XCTAssertNotNil(property, "Should return a property for a known DDF key")
        XCTAssertEqual(property?.id, knownKey)
    }

    func testFetchListingByUnknownKeyReturnsNil() async throws {
        // Given: a DDF key that does not exist in the sample data
        let unknownKey = "DDF_NONEXISTENT"

        // When
        let property = try await dataSource.fetchListing(ddfListingKey: unknownKey)

        // Then: nil is returned
        XCTAssertNil(property, "Should return nil for an unknown DDF listing key")
    }

    func testFetchListingReturnsPropertyMatchingTheKey() async throws {
        // Given: pick the last sample listing
        let knownKey = "DDF_100000011"

        // When
        let property = try await dataSource.fetchListing(ddfListingKey: knownKey)

        // Then: the returned property has .crea source and a matching id
        XCTAssertEqual(property?.source, .crea)
        XCTAssertEqual(property?.id, knownKey)
    }

    // MARK: - fetchUpdatedListings(since:)

    func testFetchUpdatedListingsSinceDistantPastReturnsAllActiveListings() async throws {
        // Given: a date far enough in the past that all listings are "newer"
        let distantPast = Date(timeIntervalSince1970: 0) // Jan 1, 1970

        // When
        let updated = try await dataSource.fetchUpdatedListings(since: distantPast)

        // Then: all active sample listings are returned (they were all created recently)
        let allActive = try await dataSource.fetchListings(filters: nil)
        XCTAssertEqual(updated.count, allActive.count,
            "Fetching updates since the distant past should return all active listings")
    }

    func testFetchUpdatedListingsSinceFutureReturnsEmpty() async throws {
        // Given: a date far in the future
        let futureDate = Date(timeIntervalSinceNow: 60 * 60 * 24 * 365 * 10) // 10 years from now

        // When
        let updated = try await dataSource.fetchUpdatedListings(since: futureDate)

        // Then: no listings qualify as "updated after" a future date
        XCTAssertTrue(updated.isEmpty, "No listings should be newer than a date 10 years in the future")
    }

    // MARK: - CREAConfiguration

    func testCREAConfigurationBaseURLIsNonEmpty() {
        // Given/When
        let baseURL = CREAConfiguration.baseURL

        // Then
        XCTAssertFalse(baseURL.isEmpty, "CREAConfiguration.baseURL must not be empty")
    }

    func testCREAConfigurationIsNotConfiguredInTestEnvironment() {
        // Given: in the test environment the REPLIERS_API_KEY env var is not set
        // When
        let configured = CREAConfiguration.isConfigured

        // Then: isConfigured should reflect the absence of the key
        // (If a developer has REPLIERS_API_KEY set locally this test would pass either way,
        //  but in CI the env var should not be present.)
        if ProcessInfo.processInfo.environment["REPLIERS_API_KEY"] != nil {
            XCTAssertTrue(configured, "isConfigured should be true when REPLIERS_API_KEY is set")
        } else {
            XCTAssertFalse(configured, "isConfigured should be false when REPLIERS_API_KEY is absent")
        }
    }
}
