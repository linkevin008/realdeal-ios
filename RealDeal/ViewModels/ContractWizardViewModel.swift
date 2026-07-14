import Foundation

/// Drives the contract wizard (MVP step 5, post-acceptance signing). Unlike a
/// step-driven wizard, this view model is STATE-driven: the contract's status
/// (draft -> terms_agreed -> buyer_signed/seller_signed -> executed, or
/// cancelled/expired) determines what the view shows and which action is
/// available. Client-side validation mirrors the server (ContractHandler.
/// ProposeTerms in realdeal-api) so users get instant feedback, but the
/// server remains the source of truth.
@MainActor
@available(iOS 15.0, macOS 12.0, *)
class ContractWizardViewModel: ObservableObject {
    @Published var contract: Contract?
    @Published var isLoading: Bool = false
    @Published var isSubmitting: Bool = false
    @Published var errorMessage: String?

    // Terms proposal form fields
    @Published var moveInDate: Date?
    @Published var transferDate: Date?
    @Published var conditions: String = ""

    let propertyId: String
    let offerId: String
    let currentUserId: String

    private let remoteDataSource: RemoteDataSourceProtocol
    private let now: () -> Date

    init(
        propertyId: String,
        offerId: String,
        currentUserId: String,
        remoteDataSource: RemoteDataSourceProtocol,
        now: @escaping () -> Date = Date.init
    ) {
        self.propertyId = propertyId
        self.offerId = offerId
        self.currentUserId = currentUserId
        self.remoteDataSource = remoteDataSource
        self.now = now
    }

    // MARK: - Role

    var isBuyer: Bool {
        guard let contract else { return false }
        return contract.buyerId == currentUserId
    }

    var isSeller: Bool {
        guard let contract else { return false }
        return contract.sellerId == currentUserId
    }

    // MARK: - Agreement / signature state

    var myAgreedAt: Date? {
        guard let contract else { return nil }
        return isBuyer ? contract.buyerAgreedAt : contract.sellerAgreedAt
    }

    var otherAgreedAt: Date? {
        guard let contract else { return nil }
        return isBuyer ? contract.sellerAgreedAt : contract.buyerAgreedAt
    }

    var mySignedAt: Date? {
        guard let contract else { return nil }
        return isBuyer ? contract.buyerSignedAt : contract.sellerSignedAt
    }

    var otherSignedAt: Date? {
        guard let contract else { return nil }
        return isBuyer ? contract.sellerSignedAt : contract.buyerSignedAt
    }

    // MARK: - Computed flags

    var isTerminal: Bool {
        guard let contract else { return false }
        switch contract.status {
        case .executed, .cancelled, .expired: return true
        default: return false
        }
    }

    /// Either party may propose/replace terms any time before a terminal
    /// state — even after one or both signatures, since a re-proposal voids
    /// them (mirrors ContractHandler.ProposeTerms, which only gates on
    /// isContractTerminal).
    var canProposeTerms: Bool {
        guard contract != nil else { return false }
        return !isTerminal && (isBuyer || isSeller)
    }

    /// Whether the current party still needs to agree to the current terms:
    /// terms have been proposed, my agreement is nil, and we're not terminal.
    var canAgree: Bool {
        guard let contract else { return false }
        guard !isTerminal else { return false }
        guard contract.termsProposedBy != nil else { return false }
        return myAgreedAt == nil
    }

    /// Signing unlocks once both parties have agreed (terms_agreed, or one
    /// side has already signed) and my signature is still nil.
    var canSign: Bool {
        guard let contract else { return false }
        switch contract.status {
        case .termsAgreed, .buyerSigned, .sellerSigned:
            return mySignedAt == nil
        default:
            return false
        }
    }

    var canCancel: Bool {
        !isTerminal && contract != nil
    }

    var timeUntilDeadline: TimeInterval? {
        guard let contract, !isTerminal else { return nil }
        return contract.executionDeadline.timeIntervalSince(now())
    }

    var isPastDeadline: Bool {
        guard let seconds = timeUntilDeadline else { return false }
        return seconds <= 0
    }

    // MARK: - Actions

    func loadContract() async {
        isLoading = true
        errorMessage = nil
        do {
            let loaded = try await remoteDataSource.getContract(propertyId: propertyId, offerId: offerId)
            contract = loaded
            moveInDate = loaded.moveInDate
            transferDate = loaded.transferDate
            conditions = loaded.conditions
        } catch {
            errorMessage = "Failed to load contract."
        }
        isLoading = false
    }

    /// Mirrors ContractHandler.ProposeTerms's validation: conditions
    /// non-empty and <= 5000 chars, dates in the future, transfer >= move-in.
    func validateTerms() -> String? {
        if conditions.isEmpty {
            return "Conditions are required."
        }
        if conditions.count > 5000 {
            return "Conditions must be at most 5000 characters."
        }
        let reference = now()
        if let moveInDate, moveInDate <= reference {
            return "Move-in date must be in the future."
        }
        if let transferDate, transferDate <= reference {
            return "Transfer date must be in the future."
        }
        if let moveInDate, let transferDate, transferDate < moveInDate {
            return "Transfer date must not be before move-in date."
        }
        return nil
    }

    func proposeTerms() async {
        if let validationError = validateTerms() {
            errorMessage = validationError
            return
        }
        isSubmitting = true
        errorMessage = nil
        do {
            contract = try await remoteDataSource.proposeTerms(
                propertyId: propertyId,
                offerId: offerId,
                moveInDate: moveInDate,
                transferDate: transferDate,
                conditions: conditions
            )
        } catch {
            errorMessage = "Failed to propose terms."
        }
        isSubmitting = false
    }

    func agree() async {
        isSubmitting = true
        errorMessage = nil
        do {
            contract = try await remoteDataSource.agreeTerms(propertyId: propertyId, offerId: offerId)
        } catch {
            errorMessage = "Failed to agree to terms."
        }
        isSubmitting = false
    }

    func sign() async {
        isSubmitting = true
        errorMessage = nil
        do {
            contract = try await remoteDataSource.signContract(propertyId: propertyId, offerId: offerId)
        } catch {
            errorMessage = "Failed to sign contract."
        }
        isSubmitting = false
    }

    func cancel() async {
        isSubmitting = true
        errorMessage = nil
        do {
            contract = try await remoteDataSource.cancelContract(propertyId: propertyId, offerId: offerId)
        } catch {
            errorMessage = "Failed to cancel contract."
        }
        isSubmitting = false
    }
}
