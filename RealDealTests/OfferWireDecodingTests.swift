import XCTest
@testable import RealDeal

// APIRemoteDataSource's APIOffer DTO is `private` to that file, so we can't
// reference it by name here. Instead we mirror its shape with local structs
// and decode through the *actual* `APIClient.decoder` (same static instance
// production code uses: .convertFromSnakeCase key strategy + custom
// fractional-seconds RFC3339 date strategy). This is the same guard added for
// APIViewingSlot/APIViewingRequest (see ViewingSchedulingTests.swift): APIOffer
// previously declared explicit snake_case CodingKeys, which conflicts with
// .convertFromSnakeCase — the decoder rewrites "property_id" to "propertyId"
// before CodingKey matching, so a literal `"property_id"` key no longer
// matches anything and every real API response threw keyNotFound.
final class OfferWireDecodingTests: XCTestCase {

    private struct WireEnvelope<T: Decodable>: Decodable { let data: T }

    private struct WireUser: Decodable {
        let id: String
        let name: String
        let email: String
        let phoneNumber: String?
        let profilePhotoUrl: String?
        let role: String
        let showEmail: Bool
        let showPhone: Bool
        let showListings: Bool
        let createdAt: Date
    }

    private struct WireOffer: Decodable {
        let id: String
        let propertyId: String
        let buyerId: String
        let amount: Double
        let message: String?
        let status: String
        let createdAt: Date
        let updatedAt: Date
        let buyer: WireUser?
    }

    func testDecodesOfferEnvelopeFromRealGoResponseShape() throws {
        // Mirrors OfferHandler.SubmitOffer/AcceptOffer/RejectOffer:
        // {"data": models.Offer, "message": "..."} with a preloaded Buyer
        // association (snake_case json tags throughout).
        let json = """
        {
          "data": {
            "id": "offer-1",
            "property_id": "prop-1",
            "buyer_id": "buyer-1",
            "amount": 850000.0,
            "message": "Willing to close quickly",
            "status": "pending",
            "created_at": "2026-07-01T12:30:00.987654321Z",
            "updated_at": "2026-07-01T12:30:00Z",
            "buyer": {
              "id": "buyer-1",
              "name": "Jamie Buyer",
              "email": "jamie@example.com",
              "phone_number": "555-0100",
              "profile_photo_url": null,
              "role": "buyer",
              "show_email": true,
              "show_phone": true,
              "show_listings": true,
              "created_at": "2026-01-01T00:00:00Z"
            }
          },
          "message": "offer submitted successfully"
        }
        """.data(using: .utf8)!

        let envelope = try APIClient.decoder.decode(WireEnvelope<WireOffer>.self, from: json)

        XCTAssertEqual(envelope.data.id, "offer-1")
        XCTAssertEqual(envelope.data.propertyId, "prop-1")
        XCTAssertEqual(envelope.data.buyerId, "buyer-1")
        XCTAssertEqual(envelope.data.amount, 850000.0)
        XCTAssertEqual(envelope.data.status, "pending")
        XCTAssertEqual(envelope.data.buyer?.id, "buyer-1")
        XCTAssertEqual(envelope.data.buyer?.showListings, true)
    }

    func testDecodesOfferListEnvelopeFromRealGoResponseShape() throws {
        // Mirrors OfferHandler.ListOffers: {"data": [models.Offer, ...]}
        // (seller-side list, each preloaded with Buyer).
        let json = """
        {
          "data": [
            {
              "id": "offer-1",
              "property_id": "prop-1",
              "buyer_id": "buyer-1",
              "amount": 850000.0,
              "message": null,
              "status": "pending",
              "created_at": "2026-07-01T12:30:00Z",
              "updated_at": "2026-07-01T12:30:00Z",
              "buyer": {
                "id": "buyer-1",
                "name": "Jamie Buyer",
                "email": "jamie@example.com",
                "phone_number": null,
                "profile_photo_url": null,
                "role": "buyer",
                "show_email": true,
                "show_phone": false,
                "show_listings": true,
                "created_at": "2026-01-01T00:00:00Z"
              }
            },
            {
              "id": "offer-2",
              "property_id": "prop-1",
              "buyer_id": "buyer-2",
              "amount": 900000.0,
              "message": "Second offer",
              "status": "rejected",
              "created_at": "2026-07-02T09:00:00.5Z",
              "updated_at": "2026-07-02T10:00:00Z",
              "buyer": null
            }
          ]
        }
        """.data(using: .utf8)!

        let envelope = try APIClient.decoder.decode(WireEnvelope<[WireOffer]>.self, from: json)

        XCTAssertEqual(envelope.data.count, 2)
        XCTAssertEqual(envelope.data.first?.id, "offer-1")
        XCTAssertEqual(envelope.data.first?.propertyId, "prop-1")
        XCTAssertEqual(envelope.data.first?.buyer?.name, "Jamie Buyer")
        XCTAssertEqual(envelope.data.last?.id, "offer-2")
        XCTAssertEqual(envelope.data.last?.status, "rejected")
        XCTAssertNil(envelope.data.last?.buyer)
    }
}
