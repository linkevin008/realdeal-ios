import Foundation

/// Drives the buyer-facing "Request Viewing" sheet: loads open slots for a
/// listing (filtering out booked and past ones) and submits a request against
/// a chosen slot.
@MainActor
@available(iOS 15.0, macOS 12.0, *)
class RequestViewingViewModel: ObservableObject {
    @Published var slots: [ViewingSlot] = []
    @Published var selectedSlotId: String?
    @Published var message: String = ""
    @Published var isLoading: Bool = false
    @Published var isSubmitting: Bool = false
    @Published var errorMessage: String?
    @Published var submittedRequest: ViewingRequest?

    private let remoteDataSource: RemoteDataSourceProtocol
    /// Injected so tests can pin "now" instead of racing the wall clock.
    private let now: () -> Date

    init(remoteDataSource: RemoteDataSourceProtocol, now: @escaping () -> Date = Date.init) {
        self.remoteDataSource = remoteDataSource
        self.now = now
    }

    /// Open slots: not booked and starting in the future, soonest first.
    var openSlots: [ViewingSlot] {
        let cutoff = now()
        return slots
            .filter { !$0.booked && $0.startTime > cutoff }
            .sorted { $0.startTime < $1.startTime }
    }

    func loadSlots(propertyId: String) async {
        isLoading = true
        errorMessage = nil
        do {
            slots = try await remoteDataSource.fetchViewingSlots(propertyId: propertyId)
        } catch {
            errorMessage = "Failed to load available viewing times."
        }
        isLoading = false
    }

    func submit(propertyId: String) async {
        guard let slotId = selectedSlotId else {
            errorMessage = "Please select a viewing time."
            return
        }

        isSubmitting = true
        errorMessage = nil

        do {
            submittedRequest = try await remoteDataSource.requestViewing(
                propertyId: propertyId,
                slotId: slotId,
                message: message.isEmpty ? nil : message
            )
        } catch {
            errorMessage = "Failed to submit viewing request. Please try again."
        }

        isSubmitting = false
    }
}
