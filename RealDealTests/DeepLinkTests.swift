import XCTest
@testable import RealDeal

@available(iOS 15.0, macOS 12.0, *)
final class DeepLinkTests: XCTestCase {

    // MARK: - URL Generation

    func testPropertyDetailURLHasRealDealScheme() {
        // Given: a property id
        let propertyId = "abc123"

        // When: generating a property detail URL
        let url = DeepLinkHelper.propertyDetailURL(propertyId: propertyId)

        // Then: URL uses the realdeal scheme
        XCTAssertNotNil(url, "propertyDetailURL should not return nil for a valid id")
        XCTAssertEqual(url?.scheme, "realdeal")
    }

    func testPropertyDetailURLContainsPropertyId() {
        // Given/When
        let url = DeepLinkHelper.propertyDetailURL(propertyId: "abc123")

        // Then: the property id appears in the URL path
        XCTAssertNotNil(url)
        XCTAssertTrue(url!.absoluteString.contains("abc123"), "URL should embed the property id")
    }

    func testProfileURLHasRealDealScheme() {
        // Given: a user id
        let userId = "user456"

        // When: generating a profile URL
        let url = DeepLinkHelper.profileURL(userId: userId)

        // Then: URL uses the realdeal scheme
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.scheme, "realdeal")
    }

    func testProfileURLContainsUserId() {
        // Given/When
        let url = DeepLinkHelper.profileURL(userId: "user456")

        // Then
        XCTAssertNotNil(url)
        XCTAssertTrue(url!.absoluteString.contains("user456"))
    }

    func testPropertyCreationURLHasRealDealScheme() {
        // Given/When: generating a property creation URL
        let url = DeepLinkHelper.propertyCreationURL()

        // Then
        XCTAssertNotNil(url, "propertyCreationURL should not return nil")
        XCTAssertEqual(url?.scheme, "realdeal")
    }

    // MARK: - URL Parsing

    func testParsePropertyDeepLink() {
        // Given: use the single-slash form that DeepLinkHelper.propertyDetailURL generates
        let url = URL(string: "realdeal:/property/abc123")!

        // When
        let result = DeepLinkHelper.parseDeepLink(url)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, "property")
        XCTAssertEqual(result?.id, "abc123")
    }

    func testParseProfileDeepLink() {
        // Given: single-slash form matching DeepLinkHelper.profileURL output
        let url = URL(string: "realdeal:/profile/user456")!

        // When
        let result = DeepLinkHelper.parseDeepLink(url)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, "profile")
        XCTAssertEqual(result?.id, "user456")
    }

    func testParseProfileDeepLinkWithOwnParameter() {
        // Given: single-slash form with a query parameter
        let url = URL(string: "realdeal:/profile/user456?own=true")!

        // When
        let result = DeepLinkHelper.parseDeepLink(url)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, "profile")
        XCTAssertEqual(result?.id, "user456")
        XCTAssertEqual(result?.parameters["own"], "true", "The 'own' query parameter should be preserved")
    }

    func testParseDeepLinkWithWrongSchemeReturnsNil() {
        // Given: a URL with an https scheme (not realdeal:)
        let url = URL(string: "https://example.com/property/abc123")!

        // When
        let result = DeepLinkHelper.parseDeepLink(url)

        // Then
        XCTAssertNil(result, "Links with a non-realdeal scheme should return nil")
    }

    func testParseSearchDeepLink() {
        // Given: a search deep link that has no id segment.
        // DeepLinkHelper generates single-slash URLs (realdeal:/path), so we use that form.
        let url = URL(string: "realdeal:/search")!

        // When
        let result = DeepLinkHelper.parseDeepLink(url)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, "search")
        XCTAssertNil(result?.id, "Search deep links have no associated id")
    }

    func testParseCreatePropertyDeepLink() {
        // Given: the URL matches what propertyCreationURL() generates (single-slash form)
        let url = URL(string: "realdeal:/create-property")!

        // When
        let result = DeepLinkHelper.parseDeepLink(url)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, "create-property")
        XCTAssertNil(result?.id, "create-property deep links have no associated id")
    }

    // MARK: - Round-trip

    func testPropertyDetailURLRoundTrip() {
        // Given
        let propertyId = "round-trip-42"

        // When: generate then parse
        guard let url = DeepLinkHelper.propertyDetailURL(propertyId: propertyId) else {
            XCTFail("propertyDetailURL returned nil"); return
        }
        let result = DeepLinkHelper.parseDeepLink(url)

        // Then: parsed values match what we put in
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, "property")
        XCTAssertEqual(result?.id, propertyId)
    }

    func testProfileURLRoundTrip() {
        // Given
        let userId = "profile-round-trip-99"

        // When: generate then parse
        guard let url = DeepLinkHelper.profileURL(userId: userId) else {
            XCTFail("profileURL returned nil"); return
        }
        let result = DeepLinkHelper.parseDeepLink(url)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, "profile")
        XCTAssertEqual(result?.id, userId)
    }

    // MARK: - shareableText

    func testShareableTextContainsAddress() {
        // Given: a sample property
        let property = Property(
            id: "share-test-1",
            address: Address(
                street: "88 Scott Street",
                city: "Toronto",
                province: "ON",
                postalCode: "M5E 0A9",
                country: "Canada"
            ),
            price: 899_000,
            propertyType: .condo,
            description: "Test property",
            location: Coordinate(latitude: 43.6479, longitude: -79.3733)
        )

        // When
        let text = DeepLinkHelper.shareableText(for: property)

        // Then: address components appear in the shareable text
        XCTAssertTrue(text.contains("88 Scott Street"), "shareableText should include the street address")
        XCTAssertTrue(text.contains("Toronto"), "shareableText should include the city")
    }

    func testShareableTextContainsFormattedPrice() {
        // Given: a property with a known price
        let property = Property(
            id: "share-test-2",
            address: Address(
                street: "47 Oriole Road",
                city: "Toronto",
                province: "ON",
                postalCode: "M4V 1S3",
                country: "Canada"
            ),
            price: 2_595_000,
            propertyType: .house,
            description: "Test property",
            location: Coordinate(latitude: 43.6888, longitude: -79.4031)
        )

        // When
        let text = DeepLinkHelper.shareableText(for: property)

        // Then: the price (in some currency format) appears in the output
        XCTAssertTrue(
            text.contains("2,595,000") || text.contains("2595000"),
            "shareableText should include the property price"
        )
    }

    func testShareableTextIncludesDeepLinkURL() {
        // Given
        let property = Property(
            id: "link-prop-7",
            address: Address(
                street: "1480 Howe Street",
                city: "Vancouver",
                province: "BC",
                postalCode: "V6Z 1R8",
                country: "Canada"
            ),
            price: 1_098_000,
            propertyType: .condo,
            description: "Test property",
            location: Coordinate(latitude: 49.2731, longitude: -123.1269)
        )

        // When: shareableText is generated with includeURL defaulting to true
        let text = DeepLinkHelper.shareableText(for: property)

        // Then: the realdeal deep link URL appears in the text
        XCTAssertTrue(
            text.contains("realdeal://"),
            "shareableText should embed the deep link URL when includeURL is true"
        )
        XCTAssertTrue(
            text.contains("link-prop-7"),
            "shareableText deep link URL should contain the property id"
        )
    }
}
