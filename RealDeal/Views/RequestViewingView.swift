import SwiftUI

@available(iOS 15.0, macOS 12.0, *)
struct RequestViewingView: View {
    @StateObject var viewModel: RequestViewingViewModel
    let propertyId: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("Available Times") {
                    if viewModel.isLoading && viewModel.slots.isEmpty {
                        ProgressView()
                    } else if viewModel.openSlots.isEmpty {
                        Text("No open viewing times right now.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(viewModel.openSlots) { slot in
                            slotRow(slot)
                        }
                    }
                }

                Section("Message (Optional)") {
                    TextField("Add a note to the seller...", text: $viewModel.message, axis: .vertical)
                        .lineLimit(3...6)
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Request Viewing")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        Task {
                            await viewModel.submit(propertyId: propertyId)
                            if viewModel.submittedRequest != nil {
                                dismiss()
                            }
                        }
                    }
                    .disabled(viewModel.selectedSlotId == nil || viewModel.isSubmitting)
                }
            }
            .overlay {
                if viewModel.isSubmitting {
                    Color.black.opacity(0.2).ignoresSafeArea()
                    ProgressView()
                }
            }
            .task {
                await viewModel.loadSlots(propertyId: propertyId)
            }
        }
    }

    private func slotRow(_ slot: ViewingSlot) -> some View {
        Button {
            viewModel.selectedSlotId = slot.id
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(Self.dateFormatter.string(from: slot.startTime))
                        .font(.body)
                        .foregroundColor(.primary)
                    Text("\(Self.timeFormatter.string(from: slot.startTime)) – \(Self.timeFormatter.string(from: slot.endTime))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if viewModel.selectedSlotId == slot.id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
        }
        .buttonStyle(.plain)
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
