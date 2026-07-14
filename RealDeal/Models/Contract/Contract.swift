import Foundation

/// Mirrors realdeal-api's ContractStatus (internal/models/contract.go). Terminal
/// states are executed/cancelled/expired — no further mutation is possible.
enum ContractStatus: String, Codable {
    case draft
    case termsAgreed = "terms_agreed"
    case buyerSigned = "buyer_signed"
    case sellerSigned = "seller_signed"
    case executed
    case cancelled
    case expired
}

/// The post-acceptance signing flow for an accepted offer (MVP step 5). Created
/// automatically by the backend when an offer is accepted — there is no create
/// endpoint on the client. The documents themselves are stubbed for the MVP;
/// only the state machine (terms -> agreement -> both signatures -> executed)
/// is real. NO CodingKeys here — APIClient.decoder uses .convertFromSnakeCase,
/// so explicit snake_case CodingKeys would conflict and break real decoding
/// (see the 06-07-2026 APIOffer wire-decode bug/fix in CONTEXT.md).
struct Contract: Codable, Identifiable, Equatable {
    let id: String
    let offerId: String
    let propertyId: String
    let sellerId: String
    let buyerId: String
    let status: ContractStatus

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

    let property: Property?

    init(
        id: String,
        offerId: String,
        propertyId: String,
        sellerId: String,
        buyerId: String,
        status: ContractStatus,
        moveInDate: Date? = nil,
        transferDate: Date? = nil,
        conditions: String = "",
        termsProposedBy: String? = nil,
        buyerAgreedAt: Date? = nil,
        sellerAgreedAt: Date? = nil,
        buyerSignedAt: Date? = nil,
        sellerSignedAt: Date? = nil,
        executionDeadline: Date,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        property: Property? = nil
    ) {
        self.id = id
        self.offerId = offerId
        self.propertyId = propertyId
        self.sellerId = sellerId
        self.buyerId = buyerId
        self.status = status
        self.moveInDate = moveInDate
        self.transferDate = transferDate
        self.conditions = conditions
        self.termsProposedBy = termsProposedBy
        self.buyerAgreedAt = buyerAgreedAt
        self.sellerAgreedAt = sellerAgreedAt
        self.buyerSignedAt = buyerSignedAt
        self.sellerSignedAt = sellerSignedAt
        self.executionDeadline = executionDeadline
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.property = property
    }
}
