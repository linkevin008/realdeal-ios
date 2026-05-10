import SwiftUI

@available(iOS 15.0, macOS 12.0, *)
struct SubmitOfferView: View {
    @StateObject var viewModel: OfferViewModel
    let propertyId: String
    let listingPrice: Double
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("Offer Amount") {
                    HStack {
                        Text("$")
                            .foregroundColor(.secondary)
                        TextField("e.g. \(Int(listingPrice))", text: $viewModel.amount)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
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
            .navigationTitle("Submit Offer")
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
                            if viewModel.submittedOffer != nil {
                                dismiss()
                            }
                        }
                    }
                    .disabled(viewModel.amount.isEmpty || viewModel.isSubmitting)
                }
            }
            .overlay {
                if viewModel.isSubmitting {
                    Color.black.opacity(0.2).ignoresSafeArea()
                    ProgressView()
                }
            }
        }
    }
}
