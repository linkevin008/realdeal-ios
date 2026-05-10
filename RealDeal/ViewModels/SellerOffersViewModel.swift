import Foundation

@MainActor
@available(iOS 15.0, macOS 12.0, *)
class SellerOffersViewModel: ObservableObject {
    @Published var offers: [Offer] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let remoteDataSource: RemoteDataSourceProtocol
    private var propertyId: String = ""

    init(remoteDataSource: RemoteDataSourceProtocol) {
        self.remoteDataSource = remoteDataSource
    }

    func loadOffers(propertyId: String) async {
        self.propertyId = propertyId
        isLoading = true
        errorMessage = nil

        do {
            offers = try await remoteDataSource.fetchOffersForProperty(propertyId: propertyId)
        } catch {
            errorMessage = "Failed to load offers."
        }

        isLoading = false
    }

    func accept(offer: Offer) async {
        do {
            let updated = try await remoteDataSource.acceptOffer(propertyId: propertyId, offerId: offer.id)
            replace(updated)
            // Reject other pending offers locally
            offers = offers.map { o in
                guard o.id != updated.id, o.status == .pending else { return o }
                return Offer(id: o.id, propertyId: o.propertyId, buyerId: o.buyerId,
                             amount: o.amount, message: o.message, status: .rejected,
                             createdAt: o.createdAt, updatedAt: Date(), property: o.property, buyer: o.buyer)
            }
        } catch {
            errorMessage = "Failed to accept offer."
        }
    }

    func reject(offer: Offer) async {
        do {
            replace(try await remoteDataSource.rejectOffer(propertyId: propertyId, offerId: offer.id))
        } catch {
            errorMessage = "Failed to reject offer."
        }
    }

    private func replace(_ offer: Offer) {
        if let idx = offers.firstIndex(where: { $0.id == offer.id }) {
            offers[idx] = offer
        }
    }
}
