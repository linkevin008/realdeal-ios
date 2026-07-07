import SwiftUI

@available(iOS 15.0, macOS 12.0, *)
struct SellerViewingsView: View {
    @StateObject var viewModel: SellerViewingsViewModel
    let property: Property

    @State private var showAddSlotSheet = false
    @State private var slotToDelete: ViewingSlot?
    @State private var showDeleteAlert = false

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.slots.isEmpty && viewModel.requests.isEmpty {
                ProgressView()
            } else {
                List {
                    Section {
                        if viewModel.slots.isEmpty {
                            Text("No viewing slots yet.")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(viewModel.slots) { slot in
                                slotSection(for: slot)
                            }
                        }
                    } header: {
                        HStack {
                            Text("Viewing Slots")
                            Spacer()
                            Button {
                                showAddSlotSheet = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Viewings")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    showAddSlotSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSlotSheet) {
            AddSlotSheet(viewModel: viewModel, isPresented: $showAddSlotSheet)
        }
        .alert("Delete Viewing Slot", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { slotToDelete = nil }
            Button("Delete", role: .destructive) {
                if let slot = slotToDelete {
                    Task { await viewModel.deleteSlot(slot) }
                }
                slotToDelete = nil
            }
        } message: {
            Text("Delete this viewing slot? Any pending requests for it will be declined.")
        }
        .refreshable {
            await viewModel.load(propertyId: property.id)
        }
        .overlay(alignment: .bottom) {
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.red.opacity(0.85))
                    .cornerRadius(8)
                    .padding(.bottom, 16)
            }
        }
        .task {
            await viewModel.load(propertyId: property.id)
        }
    }

    @ViewBuilder
    private func slotSection(for slot: ViewingSlot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(Self.dateFormatter.string(from: slot.startTime))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("\(Self.timeFormatter.string(from: slot.startTime)) – \(Self.timeFormatter.string(from: slot.endTime))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if slot.booked {
                    Text("Booked")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
            }

            let slotRequests = viewModel.requests(for: slot)
            if !slotRequests.isEmpty {
                ForEach(slotRequests) { request in
                    RequestRow(request: request) {
                        Task { await viewModel.accept(request) }
                    } onDecline: {
                        Task { await viewModel.decline(request) }
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                slotToDelete = slot
                showDeleteAlert = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .full
        f.timeStyle = .none
        return f
    }()

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()
}

@available(iOS 15.0, macOS 12.0, *)
private struct RequestRow: View {
    let request: ViewingRequest
    let onAccept: () -> Void
    let onDecline: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(request.buyer?.name ?? "Buyer")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                statusBadge
            }

            if let msg = request.message, !msg.isEmpty {
                Text(msg)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }

            if request.status == .pending {
                HStack(spacing: 12) {
                    Button(action: onAccept) {
                        Text("Accept")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                    Button(action: onDecline) {
                        Text("Decline")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(Color.red.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                }
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.08))
        .cornerRadius(8)
    }

    private var statusBadge: some View {
        Text(request.status.rawValue.capitalized)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(badgeColor)
            .foregroundColor(.white)
            .cornerRadius(4)
    }

    private var badgeColor: Color {
        switch request.status {
        case .pending:   return .orange
        case .accepted:  return .green
        case .declined:  return .gray
        case .cancelled: return .red
        }
    }
}

@available(iOS 15.0, macOS 12.0, *)
private struct AddSlotSheet: View {
    @ObservedObject var viewModel: SellerViewingsViewModel
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            Form {
                Section("Start") {
                    DatePicker("Start Time", selection: $viewModel.newSlotStart)
                }
                Section("End") {
                    DatePicker("End Time", selection: $viewModel.newSlotEnd)
                }
                if let error = viewModel.addSlotError {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Add Viewing Slot")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            await viewModel.addSlot()
                            if viewModel.addSlotError == nil {
                                isPresented = false
                            }
                        }
                    }
                    .disabled(viewModel.isAddingSlot)
                }
            }
            .overlay {
                if viewModel.isAddingSlot {
                    Color.black.opacity(0.2).ignoresSafeArea()
                    ProgressView()
                }
            }
        }
    }
}
