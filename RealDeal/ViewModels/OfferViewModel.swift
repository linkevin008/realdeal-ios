import Foundation

@MainActor
@available(iOS 15.0, macOS 12.0, *)
class OfferViewModel: ObservableObject {
    @Published var amount: String = ""
    @Published var message: String = ""
    @Published var isSubmitting: Bool = false
    @Published var errorMessage: String?
    @Published var submittedOffer: Offer?

    private let remoteDataSource: RemoteDataSourceProtocol

    init(remoteDataSource: RemoteDataSourceProtocol) {
        self.remoteDataSource = remoteDataSource
    }

    func submit(propertyId: String) async {
        guard let amountValue = Double(amount), amountValue > 0 else {
            errorMessage = "Please enter a valid offer amount."
            return
        }

        isSubmitting = true
        errorMessage = nil

        do {
            submittedOffer = try await remoteDataSource.submitOffer(
                propertyId: propertyId,
                amount: amountValue,
                message: message.isEmpty ? nil : message
            )
        } catch {
            errorMessage = "Failed to submit offer. Please try again."
        }

        isSubmitting = false
    }
}
