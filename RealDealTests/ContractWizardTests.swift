import XCTest
@testable import RealDeal

@MainActor
final class ContractWizardTests: XCTestCase {

    // MARK: - Helpers

    private func makeContract(
        id: String = "contract-1",
        offerId: String = "offer-1",
        propertyId: String = "prop-1",
        sellerId: String = "seller-1",
        buyerId: String = "buyer-1",
        status: ContractStatus = .draft,
        moveInDate: Date? = nil,
        transferDate: Date? = nil,
        conditions: String = "",
        termsProposedBy: String? = nil,
        buyerAgreedAt: Date? = nil,
        sellerAgreedAt: Date? = nil,
        buyerSignedAt: Date? = nil,
        sellerSignedAt: Date? = nil,
        executionDeadline: Date = Date().addingTimeInterval(86400 * 30)
    ) -> Contract {
        Contract(
            id: id,
            offerId: offerId,
            propertyId: propertyId,
            sellerId: sellerId,
            buyerId: buyerId,
            status: status,
            moveInDate: moveInDate,
            transferDate: transferDate,
            conditions: conditions,
            termsProposedBy: termsProposedBy,
            buyerAgreedAt: buyerAgreedAt,
            sellerAgreedAt: sellerAgreedAt,
            buyerSignedAt: buyerSignedAt,
            sellerSignedAt: sellerSignedAt,
            executionDeadline: executionDeadline
        )
    }

    private func makeViewModel(
        remote: MockRemoteDataSource,
        currentUserId: String,
        propertyId: String = "prop-1",
        offerId: String = "offer-1",
        now: @escaping () -> Date = Date.init
    ) -> ContractWizardViewModel {
        ContractWizardViewModel(
            propertyId: propertyId,
            offerId: offerId,
            currentUserId: currentUserId,
            remoteDataSource: remote,
            now: now
        )
    }

    // MARK: - Load

    func testLoadContractHappyPath() async {
        let remote = MockRemoteDataSource(simulateNetworkDelay: false)
        let contract = makeContract(conditions: "Sale as-is")
        remote.seedData(contracts: [contract])

        let vm = makeViewModel(remote: remote, currentUserId: "buyer-1")
        await vm.loadContract()

        XCTAssertEqual(vm.contract?.id, "contract-1")
        XCTAssertEqual(vm.conditions, "Sale as-is")
        XCTAssertNil(vm.errorMessage)
    }

    func testLoadContractNotFoundSurfacesError() async {
        let remote = MockRemoteDataSource(simulateNetworkDelay: false)
        let vm = makeViewModel(remote: remote, currentUserId: "buyer-1")

        await vm.loadContract()

        XCTAssertNil(vm.contract)
        XCTAssertEqual(vm.errorMessage, "Failed to load contract.")
    }

    // MARK: - Role

    func testIsBuyerAndIsSellerReflectCurrentUserId() async {
        let remote = MockRemoteDataSource(simulateNetworkDelay: false)
        remote.seedData(contracts: [makeContract(sellerId: "seller-1", buyerId: "buyer-1")])

        let buyerVM = makeViewModel(remote: remote, currentUserId: "buyer-1")
        await buyerVM.loadContract()
        XCTAssertTrue(buyerVM.isBuyer)
        XCTAssertFalse(buyerVM.isSeller)

        let sellerVM = makeViewModel(remote: remote, currentUserId: "seller-1")
        await sellerVM.loadContract()
        XCTAssertTrue(sellerVM.isSeller)
        XCTAssertFalse(sellerVM.isBuyer)
    }

    // MARK: - Terms validation (mirrors ContractHandler.ProposeTerms)

    func testValidateTermsRejectsEmptyConditions() {
        let remote = MockRemoteDataSource(simulateNetworkDelay: false)
        let vm = makeViewModel(remote: remote, currentUserId: "buyer-1")
        vm.conditions = ""

        XCTAssertNotNil(vm.validateTerms())
    }

    func testValidateTermsRejectsConditionsOverMaxLength() {
        let remote = MockRemoteDataSource(simulateNetworkDelay: false)
        let vm = makeViewModel(remote: remote, currentUserId: "buyer-1")
        vm.conditions = String(repeating: "a", count: 5001)

        XCTAssertNotNil(vm.validateTerms())
    }

    func testValidateTermsRejectsPastMoveInDate() {
        let remote = MockRemoteDataSource(simulateNetworkDelay: false)
        let fixedNow = Date()
        let vm = makeViewModel(remote: remote, currentUserId: "buyer-1", now: { fixedNow })
        vm.conditions = "Standard terms"
        vm.moveInDate = fixedNow.addingTimeInterval(-3600)

        XCTAssertNotNil(vm.validateTerms())
    }

    func testValidateTermsRejectsTransferBeforeMoveIn() {
        let remote = MockRemoteDataSource(simulateNetworkDelay: false)
        let fixedNow = Date()
        let vm = makeViewModel(remote: remote, currentUserId: "buyer-1", now: { fixedNow })
        vm.conditions = "Standard terms"
        vm.moveInDate = fixedNow.addingTimeInterval(86400 * 10)
        vm.transferDate = fixedNow.addingTimeInterval(86400 * 5)

        XCTAssertNotNil(vm.validateTerms())
    }

    func testValidateTermsAcceptsValidForm() {
        let remote = MockRemoteDataSource(simulateNetworkDelay: false)
        let fixedNow = Date()
        let vm = makeViewModel(remote: remote, currentUserId: "buyer-1", now: { fixedNow })
        vm.conditions = "Standard terms"
        vm.moveInDate = fixedNow.addingTimeInterval(86400 * 5)
        vm.transferDate = fixedNow.addingTimeInterval(86400 * 10)

        XCTAssertNil(vm.validateTerms())
    }

    // MARK: - Propose terms (auto-agree + reset-other-party semantics)

    func testProposeTermsAutoAgreesProposerOnly() async {
        let remote = MockRemoteDataSource(simulateNetworkDelay: false)
        remote.seedData(contracts: [makeContract()])
        remote.mockCurrentUserId = "seller-1"

        let vm = makeViewModel(remote: remote, currentUserId: "seller-1")
        await vm.loadContract()
        vm.conditions = "Sale contingent on inspection"
        vm.moveInDate = Date().addingTimeInterval(86400 * 20)
        vm.transferDate = Date().addingTimeInterval(86400 * 25)

        await vm.proposeTerms()

        XCTAssertEqual(vm.contract?.termsProposedBy, "seller-1")
        XCTAssertNotNil(vm.contract?.sellerAgreedAt)
        XCTAssertNil(vm.contract?.buyerAgreedAt)
        XCTAssertEqual(vm.contract?.status, .draft)
        XCTAssertNil(vm.errorMessage)
    }

    func testReProposeTermsResetsOtherPartyAgreementAndBothSignatures() async {
        let remote = MockRemoteDataSource(simulateNetworkDelay: false)
        // Both parties previously agreed and buyer already signed.
        remote.seedData(contracts: [makeContract(
            status: .buyerSigned,
            conditions: "Original terms",
            termsProposedBy: "buyer-1",
            buyerAgreedAt: Date(),
            sellerAgreedAt: Date(),
            buyerSignedAt: Date()
        )])
        remote.mockCurrentUserId = "seller-1"

        let vm = makeViewModel(remote: remote, currentUserId: "seller-1")
        await vm.loadContract()
        vm.conditions = "Revised terms"

        await vm.proposeTerms()

        XCTAssertEqual(vm.contract?.status, .draft)
        XCTAssertEqual(vm.contract?.termsProposedBy, "seller-1")
        XCTAssertNotNil(vm.contract?.sellerAgreedAt)
        XCTAssertNil(vm.contract?.buyerAgreedAt, "re-proposal must void the other party's prior agreement")
        XCTAssertNil(vm.contract?.buyerSignedAt, "re-proposal must void prior signatures")
        XCTAssertNil(vm.contract?.sellerSignedAt)
    }

    // MARK: - Agree

    func testAgreeAdvancesToTermsAgreedWhenBothHaveAgreed() async {
        let remote = MockRemoteDataSource(simulateNetworkDelay: false)
        remote.seedData(contracts: [makeContract(
            termsProposedBy: "buyer-1",
            buyerAgreedAt: Date()
        )])
        remote.mockCurrentUserId = "seller-1"

        let vm = makeViewModel(remote: remote, currentUserId: "seller-1")
        await vm.loadContract()
        XCTAssertTrue(vm.canAgree)

        await vm.agree()

        XCTAssertEqual(vm.contract?.status, .termsAgreed)
        XCTAssertNotNil(vm.contract?.sellerAgreedAt)
        XCTAssertNil(vm.errorMessage)
    }

    func testCanAgreeFalseWhenAlreadyAgreed() async {
        let remote = MockRemoteDataSource(simulateNetworkDelay: false)
        remote.seedData(contracts: [makeContract(
            termsProposedBy: "buyer-1",
            buyerAgreedAt: Date()
        )])
        let vm = makeViewModel(remote: remote, currentUserId: "buyer-1")
        await vm.loadContract()

        XCTAssertFalse(vm.canAgree)
    }

    func testCanAgreeFalseWhenNoTermsProposedYet() async {
        let remote = MockRemoteDataSource(simulateNetworkDelay: false)
        remote.seedData(contracts: [makeContract()])
        let vm = makeViewModel(remote: remote, currentUserId: "buyer-1")
        await vm.loadContract()

        XCTAssertFalse(vm.canAgree)
    }

    // MARK: - Sign

    func testSignAdvancesToBuyerSignedWhenSellerHasNotSignedYet() async {
        let remote = MockRemoteDataSource(simulateNetworkDelay: false)
        remote.seedData(contracts: [makeContract(status: .termsAgreed, termsProposedBy: "buyer-1", buyerAgreedAt: Date(), sellerAgreedAt: Date())])
        remote.mockCurrentUserId = "buyer-1"

        let vm = makeViewModel(remote: remote, currentUserId: "buyer-1")
        await vm.loadContract()
        XCTAssertTrue(vm.canSign)

        await vm.sign()

        XCTAssertEqual(vm.contract?.status, .buyerSigned)
        XCTAssertNotNil(vm.contract?.buyerSignedAt)
        XCTAssertNil(vm.contract?.sellerSignedAt)
    }

    func testSignExecutesWhenBothPartiesHaveSigned() async {
        let remote = MockRemoteDataSource(simulateNetworkDelay: false)
        remote.seedData(contracts: [makeContract(
            status: .sellerSigned,
            termsProposedBy: "buyer-1",
            buyerAgreedAt: Date(),
            sellerAgreedAt: Date(),
            sellerSignedAt: Date()
        )])
        remote.mockCurrentUserId = "buyer-1"

        let vm = makeViewModel(remote: remote, currentUserId: "buyer-1")
        await vm.loadContract()

        await vm.sign()

        XCTAssertEqual(vm.contract?.status, .executed)
        XCTAssertNotNil(vm.contract?.buyerSignedAt)
        XCTAssertNotNil(vm.contract?.sellerSignedAt)
        XCTAssertTrue(vm.isTerminal)
    }

    func testCanSignFalseWhenTermsNotYetAgreed() async {
        let remote = MockRemoteDataSource(simulateNetworkDelay: false)
        remote.seedData(contracts: [makeContract(status: .draft)])
        let vm = makeViewModel(remote: remote, currentUserId: "buyer-1")
        await vm.loadContract()

        XCTAssertFalse(vm.canSign)
    }

    // MARK: - Cancel

    func testCancelSetsCancelledStatusAndBlocksFurtherMutation() async {
        let remote = MockRemoteDataSource(simulateNetworkDelay: false)
        remote.seedData(contracts: [makeContract(status: .termsAgreed, termsProposedBy: "buyer-1", buyerAgreedAt: Date(), sellerAgreedAt: Date())])
        remote.mockCurrentUserId = "buyer-1"

        let vm = makeViewModel(remote: remote, currentUserId: "buyer-1")
        await vm.loadContract()
        XCTAssertTrue(vm.canCancel)

        await vm.cancel()

        XCTAssertEqual(vm.contract?.status, .cancelled)
        XCTAssertTrue(vm.isTerminal)
        XCTAssertFalse(vm.canCancel)
    }

    // MARK: - Terminal / expired states block mutation

    func testExpiredContractBlocksProposeTerms() async {
        let remote = MockRemoteDataSource(simulateNetworkDelay: false)
        remote.seedData(contracts: [makeContract(status: .expired)])
        remote.mockCurrentUserId = "buyer-1"

        let vm = makeViewModel(remote: remote, currentUserId: "buyer-1")
        await vm.loadContract()
        XCTAssertTrue(vm.isTerminal)
        XCTAssertFalse(vm.canProposeTerms)

        vm.conditions = "New terms"
        await vm.proposeTerms()

        XCTAssertEqual(vm.errorMessage, "Failed to propose terms.")
        XCTAssertEqual(vm.contract?.status, .expired, "a rejected mutation must not silently change contract state")
    }

    func testIsTerminalTrueForAllThreeTerminalStatuses() {
        let remote = MockRemoteDataSource(simulateNetworkDelay: false)
        let vm = makeViewModel(remote: remote, currentUserId: "buyer-1")

        for status: ContractStatus in [.executed, .cancelled, .expired] {
            vm.contract = makeContract(status: status)
            XCTAssertTrue(vm.isTerminal, "\(status) should be terminal")
        }
        for status: ContractStatus in [.draft, .termsAgreed, .buyerSigned, .sellerSigned] {
            vm.contract = makeContract(status: status)
            XCTAssertFalse(vm.isTerminal, "\(status) should not be terminal")
        }
    }

    // MARK: - Deadline

    func testTimeUntilDeadlineReflectsRemainingTime() {
        let remote = MockRemoteDataSource(simulateNetworkDelay: false)
        let fixedNow = Date()
        let vm = makeViewModel(remote: remote, currentUserId: "buyer-1", now: { fixedNow })
        vm.contract = makeContract(executionDeadline: fixedNow.addingTimeInterval(86400 * 3))

        XCTAssertEqual(vm.timeUntilDeadline ?? 0, 86400 * 3, accuracy: 1.0)
        XCTAssertFalse(vm.isPastDeadline)
    }

    func testTimeUntilDeadlineNilForTerminalContract() {
        let remote = MockRemoteDataSource(simulateNetworkDelay: false)
        let vm = makeViewModel(remote: remote, currentUserId: "buyer-1")
        vm.contract = makeContract(status: .executed, executionDeadline: Date().addingTimeInterval(86400))

        XCTAssertNil(vm.timeUntilDeadline)
    }

    // MARK: - fetchMyContracts (MyContractsViewModel)

    func testMyContractsViewModelLoadsContractsForCurrentUser() async {
        let remote = MockRemoteDataSource(simulateNetworkDelay: false)
        remote.mockCurrentUserId = "buyer-1"
        remote.seedData(contracts: [
            makeContract(id: "c1", buyerId: "buyer-1"),
            makeContract(id: "c2", sellerId: "someone-else-2", buyerId: "someone-else")
        ])

        let vm = MyContractsViewModel(remoteDataSource: remote)
        await vm.loadContracts()

        XCTAssertEqual(vm.contracts.map { $0.id }, ["c1"])
        XCTAssertNil(vm.errorMessage)
    }

    // MARK: - Wire decoding: real APIClient.decoder against the Go handler response shape

    // APIRemoteDataSource's APIContract DTO is `private` to that file, so we
    // mirror its shape here and decode through the *actual* `APIClient.decoder`
    // (same static instance production code uses). This is the same guard
    // added for APIOffer/APIViewingSlot/APIViewingRequest after the 06-07-2026
    // wire-decode bug: explicit snake_case CodingKeys conflict with
    // .convertFromSnakeCase, which has already rewritten "property_id" to
    // "propertyId" before CodingKey matching. Contract.swift declares NO
    // CodingKeys, so this guards against that regression.
    private struct WireEnvelope<T: Decodable>: Decodable { let data: T }

    private struct WireContract: Decodable {
        let id: String
        let offerId: String
        let propertyId: String
        let sellerId: String
        let buyerId: String
        let status: String
        let moveInDate: Date?
        let transferDate: Date?
        let conditions: String
        let termsProposedBy: String?
        let buyerAgreedAt: Date?
        let sellerAgreedAt: Date?
        let buyerSignedAt: Date?
        let sellerSignedAt: Date?
        let executionDeadline: Date
        let createdAt: Date
        let updatedAt: Date
    }

    func testDecodesContractEnvelopeFromRealGoResponseShape() throws {
        // Mirrors ContractHandler.GetContract/ProposeTerms/AgreeTerms/Sign/Cancel:
        // {"data": models.Contract, "message": "..."} (snake_case json tags,
        // nullable pointer fields for terms/agreement/signature timestamps).
        let json = """
        {
          "data": {
            "id": "contract-1",
            "offer_id": "offer-1",
            "property_id": "prop-1",
            "seller_id": "seller-1",
            "buyer_id": "buyer-1",
            "status": "terms_agreed",
            "move_in_date": "2026-09-01T00:00:00Z",
            "transfer_date": "2026-09-15T00:00:00Z",
            "conditions": "Sale contingent on inspection",
            "terms_proposed_by": "buyer-1",
            "buyer_agreed_at": "2026-07-01T12:30:00.123456789Z",
            "seller_agreed_at": "2026-07-02T09:00:00Z",
            "buyer_signed_at": null,
            "seller_signed_at": null,
            "execution_deadline": "2026-08-01T00:00:00Z",
            "created_at": "2026-06-30T00:00:00Z",
            "updated_at": "2026-07-02T09:00:00Z"
          },
          "message": "terms agreed"
        }
        """.data(using: .utf8)!

        let envelope = try APIClient.decoder.decode(WireEnvelope<WireContract>.self, from: json)

        XCTAssertEqual(envelope.data.id, "contract-1")
        XCTAssertEqual(envelope.data.offerId, "offer-1")
        XCTAssertEqual(envelope.data.propertyId, "prop-1")
        XCTAssertEqual(envelope.data.sellerId, "seller-1")
        XCTAssertEqual(envelope.data.buyerId, "buyer-1")
        XCTAssertEqual(envelope.data.status, "terms_agreed")
        XCTAssertEqual(envelope.data.termsProposedBy, "buyer-1")
        XCTAssertNotNil(envelope.data.buyerAgreedAt)
        XCTAssertNotNil(envelope.data.sellerAgreedAt)
        XCTAssertNil(envelope.data.buyerSignedAt)
        XCTAssertNil(envelope.data.sellerSignedAt)
    }
}
