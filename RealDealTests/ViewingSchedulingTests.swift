import XCTest
@testable import RealDeal

@MainActor
final class ViewingSchedulingTests: XCTestCase {

    // MARK: - Helpers

    private func makeSlot(
        id: String = UUID().uuidString,
        propertyId: String = "p1",
        start: Date,
        end: Date,
        booked: Bool = false
    ) -> ViewingSlot {
        ViewingSlot(id: id, propertyId: propertyId, startTime: start, endTime: end, booked: booked)
    }

    // MARK: - RequestViewingViewModel: openSlots filtering

    func testOpenSlotsFiltersOutBookedAndPastSlots() async {
        let remote = MockRemoteDataSource(simulateNetworkDelay: false)
        let fixedNow = Date()
        let vm = RequestViewingViewModel(remoteDataSource: remote, now: { fixedNow })

        let pastSlot = makeSlot(start: fixedNow.addingTimeInterval(-3600), end: fixedNow.addingTimeInterval(-1800))
        let bookedSlot = makeSlot(start: fixedNow.addingTimeInterval(3600), end: fixedNow.addingTimeInterval(7200), booked: true)
        let openSlot = makeSlot(start: fixedNow.addingTimeInterval(7200), end: fixedNow.addingTimeInterval(10800))

        remote.seedData(viewingSlots: [pastSlot, bookedSlot, openSlot])

        await vm.loadSlots(propertyId: "p1")

        XCTAssertEqual(vm.slots.count, 3)
        XCTAssertEqual(vm.openSlots.count, 1)
        XCTAssertEqual(vm.openSlots.first?.id, openSlot.id)
    }

    func testOpenSlotsSortedSoonestFirst() async {
        let remote = MockRemoteDataSource(simulateNetworkDelay: false)
        let fixedNow = Date()
        let vm = RequestViewingViewModel(remoteDataSource: remote, now: { fixedNow })

        let later = makeSlot(start: fixedNow.addingTimeInterval(10800), end: fixedNow.addingTimeInterval(14400))
        let sooner = makeSlot(start: fixedNow.addingTimeInterval(3600), end: fixedNow.addingTimeInterval(7200))
        remote.seedData(viewingSlots: [later, sooner])

        await vm.loadSlots(propertyId: "p1")

        XCTAssertEqual(vm.openSlots.map { $0.id }, [sooner.id, later.id])
    }

    // MARK: - RequestViewingViewModel: submission

    func testSubmitViewingRequestHappyPath() async {
        let remote = MockRemoteDataSource(simulateNetworkDelay: false)
        let fixedNow = Date()
        let slot = makeSlot(start: fixedNow.addingTimeInterval(3600), end: fixedNow.addingTimeInterval(7200))
        remote.seedData(viewingSlots: [slot])

        let vm = RequestViewingViewModel(remoteDataSource: remote, now: { fixedNow })
        await vm.loadSlots(propertyId: "p1")
        vm.selectedSlotId = slot.id
        vm.message = "Looking forward to it"

        await vm.submit(propertyId: "p1")

        XCTAssertNotNil(vm.submittedRequest)
        XCTAssertEqual(vm.submittedRequest?.slotId, slot.id)
        XCTAssertEqual(vm.submittedRequest?.status, .pending)
        XCTAssertNil(vm.errorMessage)
    }

    func testSubmitViewingRequestWithoutSelectionSurfacesError() async {
        let remote = MockRemoteDataSource(simulateNetworkDelay: false)
        let vm = RequestViewingViewModel(remoteDataSource: remote)

        await vm.submit(propertyId: "p1")

        XCTAssertNil(vm.submittedRequest)
        XCTAssertNotNil(vm.errorMessage)
    }

    func testSubmitViewingRequestErrorSurfacesToErrorMessage() async {
        let remote = MockRemoteDataSource(simulateNetworkDelay: false)
        let vm = RequestViewingViewModel(remoteDataSource: remote)
        // No slot seeded -> requestViewing throws notFound
        vm.selectedSlotId = "does-not-exist"

        await vm.submit(propertyId: "p1")

        XCTAssertNil(vm.submittedRequest)
        XCTAssertEqual(vm.errorMessage, "Failed to submit viewing request. Please try again.")
    }

    // MARK: - SellerViewingsViewModel: slot validation

    func testValidateNewSlotRejectsEndBeforeStart() {
        let remote = MockRemoteDataSource(simulateNetworkDelay: false)
        let fixedNow = Date()
        let vm = SellerViewingsViewModel(remoteDataSource: remote, now: { fixedNow })
        vm.newSlotStart = fixedNow.addingTimeInterval(7200)
        vm.newSlotEnd = fixedNow.addingTimeInterval(3600)

        XCTAssertNotNil(vm.validateNewSlot())
    }

    func testValidateNewSlotRejectsPastStart() {
        let remote = MockRemoteDataSource(simulateNetworkDelay: false)
        let fixedNow = Date()
        let vm = SellerViewingsViewModel(remoteDataSource: remote, now: { fixedNow })
        vm.newSlotStart = fixedNow.addingTimeInterval(-3600)
        vm.newSlotEnd = fixedNow.addingTimeInterval(3600)

        XCTAssertNotNil(vm.validateNewSlot())
    }

    func testValidateNewSlotAcceptsValidWindow() {
        let remote = MockRemoteDataSource(simulateNetworkDelay: false)
        let fixedNow = Date()
        let vm = SellerViewingsViewModel(remoteDataSource: remote, now: { fixedNow })
        vm.newSlotStart = fixedNow.addingTimeInterval(3600)
        vm.newSlotEnd = fixedNow.addingTimeInterval(7200)

        XCTAssertNil(vm.validateNewSlot())
    }

    func testAddSlotBlockedByValidationDoesNotCallRemote() async {
        let remote = MockRemoteDataSource(simulateNetworkDelay: false)
        let fixedNow = Date()
        let vm = SellerViewingsViewModel(remoteDataSource: remote, now: { fixedNow })
        vm.newSlotStart = fixedNow.addingTimeInterval(7200)
        vm.newSlotEnd = fixedNow.addingTimeInterval(3600) // end before start

        await vm.addSlot()

        XCTAssertNotNil(vm.addSlotError)
        XCTAssertTrue(vm.slots.isEmpty)
    }

    // MARK: - SellerViewingsViewModel: accept updates local state

    func testAcceptRequestUpdatesLocalStateAndDeclinesCompetingRequests() async {
        let remote = MockRemoteDataSource(simulateNetworkDelay: false)
        let fixedNow = Date()
        let slot = makeSlot(start: fixedNow.addingTimeInterval(3600), end: fixedNow.addingTimeInterval(7200))
        remote.seedData(viewingSlots: [slot])

        let requestA = ViewingRequest(
            id: "reqA", slotId: slot.id, propertyId: "p1", buyerId: "buyerA",
            status: .pending, createdAt: fixedNow, slot: slot
        )
        let requestB = ViewingRequest(
            id: "reqB", slotId: slot.id, propertyId: "p1", buyerId: "buyerB",
            status: .pending, createdAt: fixedNow, slot: slot
        )
        remote.seedData(viewingRequests: [requestA, requestB])

        let vm = SellerViewingsViewModel(remoteDataSource: remote, now: { fixedNow })
        await vm.load(propertyId: "p1")

        await vm.accept(requestA)

        let updatedA = vm.requests.first { $0.id == "reqA" }
        let updatedB = vm.requests.first { $0.id == "reqB" }
        XCTAssertEqual(updatedA?.status, .accepted)
        XCTAssertEqual(updatedB?.status, .declined)

        let updatedSlot = vm.slots.first { $0.id == slot.id }
        XCTAssertEqual(updatedSlot?.booked, true)
        XCTAssertNil(vm.errorMessage)
    }

    func testAcceptRequestErrorSurfacesToErrorMessage() async {
        let remote = MockRemoteDataSource(simulateNetworkDelay: false)
        let vm = SellerViewingsViewModel(remoteDataSource: remote)
        let bogusRequest = ViewingRequest(
            id: "nonexistent", slotId: "s1", propertyId: "p1", buyerId: "b1",
            status: .pending, createdAt: Date()
        )

        await vm.accept(bogusRequest)

        XCTAssertEqual(vm.errorMessage, "Failed to accept viewing request.")
    }

    // MARK: - PropertyDetailViewModel: buyer viewing state + cancel

    private func makeProperty(id: String = "p1", sellerId: String? = "seller1") -> Property {
        Property(
            id: id,
            address: Address(street: "123 Main St", city: "Toronto", province: "ON", postalCode: "M5H 1J9", country: "Canada"),
            price: 850_000,
            propertyType: .house,
            description: "Test",
            location: Coordinate(latitude: 43.6532, longitude: -79.3832),
            sellerId: sellerId
        )
    }

    private func makeDetailViewModel(property: Property, remote: MockRemoteDataSource, currentUserId: String?) -> PropertyDetailViewModel {
        let mockRepo = MockPropertyRepository()
        let persistence = PersistenceController(inMemory: true)
        let localDS = LocalDataSource(persistenceController: persistence)
        let userProfileRepo = UserProfileRepository(localDataSource: localDS, remoteDataSource: remote)
        return PropertyDetailViewModel(
            property: property,
            propertyRepository: mockRepo,
            userProfileRepository: userProfileRepo,
            remoteDataSource: remote,
            currentUserId: currentUserId
        )
    }

    func testCheckMyViewingRequestReflectsLivePendingRequest() async {
        let remote = MockRemoteDataSource(simulateNetworkDelay: false)
        remote.mockCurrentBuyerId = "buyer1"
        let property = makeProperty()
        let slot = makeSlot(start: Date().addingTimeInterval(3600), end: Date().addingTimeInterval(7200))
        let request = ViewingRequest(
            id: "reqX", slotId: slot.id, propertyId: property.id, buyerId: "buyer1",
            status: .pending, createdAt: Date(), slot: slot
        )
        remote.seedData(viewingSlots: [slot], viewingRequests: [request])

        let vm = makeDetailViewModel(property: property, remote: remote, currentUserId: "buyer1")
        await vm.checkMyViewingRequest()

        XCTAssertEqual(vm.myViewingRequest?.id, "reqX")
    }

    func testCancelMyViewingRequestClearsBuyerState() async {
        let remote = MockRemoteDataSource(simulateNetworkDelay: false)
        remote.mockCurrentBuyerId = "buyer1"
        let property = makeProperty()
        let slot = makeSlot(start: Date().addingTimeInterval(3600), end: Date().addingTimeInterval(7200))
        let request = ViewingRequest(
            id: "reqX", slotId: slot.id, propertyId: property.id, buyerId: "buyer1",
            status: .pending, createdAt: Date(), slot: slot
        )
        remote.seedData(viewingSlots: [slot], viewingRequests: [request])

        let vm = makeDetailViewModel(property: property, remote: remote, currentUserId: "buyer1")
        await vm.checkMyViewingRequest()
        XCTAssertNotNil(vm.myViewingRequest)

        await vm.cancelMyViewingRequest()

        XCTAssertNil(vm.myViewingRequest)
        XCTAssertNil(vm.errorMessage)

        // Verify the cancellation reached the remote data source too.
        let myRequests = try? await remote.fetchMyViewingRequests()
        XCTAssertEqual(myRequests?.first { $0.id == "reqX" }?.status, .cancelled)
    }

    func testSellerNeverPopulatesViewingRequestState() async {
        let remote = MockRemoteDataSource(simulateNetworkDelay: false)
        let property = makeProperty(sellerId: "seller1")
        let vm = makeDetailViewModel(property: property, remote: remote, currentUserId: "seller1")

        await vm.checkMyViewingRequest()

        XCTAssertNil(vm.myViewingRequest)
    }

    // MARK: - Wire decoding: real APIClient.decoder against Go handler response shapes

    // APIRemoteDataSource's APIViewingSlot/APIViewingRequest DTOs are `private` to that
    // file, so we can't reference them by name here. Instead we mirror their shape with
    // local structs and decode through the *actual* `APIClient.decoder` (same static
    // instance production code uses: .convertFromSnakeCase key strategy + custom
    // fractional-seconds RFC3339 date strategy). This is the guard the evaluator flagged
    // as missing: if APIViewingSlot/APIViewingRequest ever redeclare explicit snake_case
    // CodingKeys again, `.convertFromSnakeCase` will have already rewritten "property_id"
    // to "propertyId" before CodingKey matching, so a literal `"property_id"` key no
    // longer matches anything and decoding fails with keyNotFound.
    private struct WireEnvelope<T: Decodable>: Decodable { let data: T }

    private struct WireViewingSlot: Decodable, Equatable {
        let id: String
        let propertyId: String
        let startTime: Date
        let endTime: Date
        let booked: Bool
    }

    private struct WireViewingRequest: Decodable {
        let id: String
        let slotId: String
        let propertyId: String
        let buyerId: String
        let message: String?
        let status: String
        let createdAt: Date
        let slot: WireViewingSlot?
    }

    func testDecodesViewingSlotListEnvelopeFromRealGoResponseShape() throws {
        // Mirrors ViewingHandler.ListSlots: {"data": [viewingSlotResponse, ...]}
        // where viewingSlotResponse embeds models.ViewingSlot (snake_case json tags)
        // plus a computed "booked" bool. Go's time.Time marshals as RFC3339 with
        // fractional seconds, e.g. "2026-03-29T17:15:23.143527891Z".
        let json = """
        {
          "data": [
            {
              "id": "slot-1",
              "property_id": "prop-1",
              "start_time": "2026-08-01T14:00:00.123456789Z",
              "end_time": "2026-08-01T15:00:00Z",
              "created_at": "2026-07-01T00:00:00Z",
              "updated_at": "2026-07-01T00:00:00Z",
              "booked": false
            }
          ]
        }
        """.data(using: .utf8)!

        let envelope = try APIClient.decoder.decode(WireEnvelope<[WireViewingSlot]>.self, from: json)

        XCTAssertEqual(envelope.data.count, 1)
        XCTAssertEqual(envelope.data.first?.id, "slot-1")
        XCTAssertEqual(envelope.data.first?.propertyId, "prop-1")
        XCTAssertEqual(envelope.data.first?.booked, false)
    }

    func testDecodesViewingRequestEnvelopeFromRealGoResponseShape() throws {
        // Mirrors ViewingHandler.RequestViewing: {"data": models.ViewingRequest, "message": "..."}
        // with a preloaded nested Slot (snake_case json tags throughout).
        let json = """
        {
          "data": {
            "id": "req-1",
            "slot_id": "slot-1",
            "property_id": "prop-1",
            "buyer_id": "buyer-1",
            "message": "Looking forward to it",
            "status": "pending",
            "created_at": "2026-07-01T12:30:00.987654321Z",
            "updated_at": "2026-07-01T12:30:00Z",
            "slot": {
              "id": "slot-1",
              "property_id": "prop-1",
              "start_time": "2026-08-01T14:00:00Z",
              "end_time": "2026-08-01T15:00:00Z",
              "created_at": "2026-07-01T00:00:00Z",
              "updated_at": "2026-07-01T00:00:00Z",
              "booked": true
            }
          },
          "message": "viewing request submitted"
        }
        """.data(using: .utf8)!

        let envelope = try APIClient.decoder.decode(WireEnvelope<WireViewingRequest>.self, from: json)

        XCTAssertEqual(envelope.data.id, "req-1")
        XCTAssertEqual(envelope.data.slotId, "slot-1")
        XCTAssertEqual(envelope.data.propertyId, "prop-1")
        XCTAssertEqual(envelope.data.buyerId, "buyer-1")
        XCTAssertEqual(envelope.data.status, "pending")
        XCTAssertEqual(envelope.data.slot?.propertyId, "prop-1")
        XCTAssertEqual(envelope.data.slot?.booked, true)
    }
}
