import Foundation

/// Drives the seller's viewing-management screen: the listing's slots (add /
/// delete) and incoming requests (accept / decline), grouped by slot.
@MainActor
@available(iOS 15.0, macOS 12.0, *)
class SellerViewingsViewModel: ObservableObject {
    @Published var slots: [ViewingSlot] = []
    @Published var requests: [ViewingRequest] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // Add-slot form state
    @Published var newSlotStart: Date = Date().addingTimeInterval(3600)
    @Published var newSlotEnd: Date = Date().addingTimeInterval(3600 * 2)
    @Published var isAddingSlot: Bool = false
    @Published var addSlotError: String?

    private let remoteDataSource: RemoteDataSourceProtocol
    private var propertyId: String = ""
    private let now: () -> Date

    init(remoteDataSource: RemoteDataSourceProtocol, now: @escaping () -> Date = Date.init) {
        self.remoteDataSource = remoteDataSource
        self.now = now
    }

    func load(propertyId: String) async {
        self.propertyId = propertyId
        isLoading = true
        errorMessage = nil

        do {
            async let slotsResult = remoteDataSource.fetchViewingSlots(propertyId: propertyId)
            async let requestsResult = remoteDataSource.fetchViewingRequests(propertyId: propertyId)
            slots = try await slotsResult
            requests = try await requestsResult
        } catch {
            errorMessage = "Failed to load viewings."
        }

        isLoading = false
    }

    /// Mirrors the server's rules (end after start, start in the future) so
    /// the form surfaces inline errors instead of a 4xx round trip.
    func validateNewSlot() -> String? {
        if !newSlotEnd.timeIntervalSince(newSlotStart).isFinite || newSlotEnd <= newSlotStart {
            return "End time must be after start time."
        }
        if newSlotStart <= now() {
            return "Start time must be in the future."
        }
        return nil
    }

    func addSlot() async {
        if let error = validateNewSlot() {
            addSlotError = error
            return
        }

        isAddingSlot = true
        addSlotError = nil

        do {
            let slot = try await remoteDataSource.createViewingSlot(
                propertyId: propertyId,
                startTime: newSlotStart,
                endTime: newSlotEnd
            )
            slots.append(slot)
            slots.sort { $0.startTime < $1.startTime }
        } catch {
            addSlotError = "Failed to create viewing slot. Please try again."
        }

        isAddingSlot = false
    }

    func deleteSlot(_ slot: ViewingSlot) async {
        do {
            try await remoteDataSource.deleteViewingSlot(propertyId: propertyId, slotId: slot.id)
            slots.removeAll { $0.id == slot.id }
            // Deleting a slot server-side declines its pending requests.
            requests = requests.map { req in
                guard req.slotId == slot.id, req.status == .pending else { return req }
                return ViewingRequest(
                    id: req.id, slotId: req.slotId, propertyId: req.propertyId, buyerId: req.buyerId,
                    message: req.message, status: .declined, createdAt: req.createdAt,
                    slot: req.slot, buyer: req.buyer, property: req.property
                )
            }
        } catch {
            errorMessage = "Failed to delete viewing slot."
        }
    }

    func accept(_ request: ViewingRequest) async {
        do {
            let updated = try await remoteDataSource.acceptViewingRequest(propertyId: propertyId, requestId: request.id)
            replace(updated)
            // Reflect the server's side effect: other pending requests for the
            // same slot are declined, and the slot becomes booked.
            requests = requests.map { req in
                guard req.id != updated.id, req.slotId == updated.slotId, req.status == .pending else { return req }
                return ViewingRequest(
                    id: req.id, slotId: req.slotId, propertyId: req.propertyId, buyerId: req.buyerId,
                    message: req.message, status: .declined, createdAt: req.createdAt,
                    slot: req.slot, buyer: req.buyer, property: req.property
                )
            }
            if let idx = slots.firstIndex(where: { $0.id == updated.slotId }) {
                let slot = slots[idx]
                slots[idx] = ViewingSlot(id: slot.id, propertyId: slot.propertyId, startTime: slot.startTime, endTime: slot.endTime, booked: true)
            }
        } catch {
            errorMessage = "Failed to accept viewing request."
        }
    }

    func decline(_ request: ViewingRequest) async {
        do {
            replace(try await remoteDataSource.declineViewingRequest(propertyId: propertyId, requestId: request.id))
        } catch {
            errorMessage = "Failed to decline viewing request."
        }
    }

    /// Requests for a given slot, most recent first.
    func requests(for slot: ViewingSlot) -> [ViewingRequest] {
        requests.filter { $0.slotId == slot.id }.sorted { $0.createdAt > $1.createdAt }
    }

    private func replace(_ request: ViewingRequest) {
        if let idx = requests.firstIndex(where: { $0.id == request.id }) {
            requests[idx] = request
        }
    }
}
