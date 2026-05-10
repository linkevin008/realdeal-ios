import SwiftUI

@available(iOS 15.0, macOS 12.0, *)
struct SellerOffersView: View {
    @StateObject var viewModel: SellerOffersViewModel
    let property: Property

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.offers.isEmpty {
                ProgressView()
            } else if viewModel.offers.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No offers yet")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(viewModel.offers) { offer in
                    OfferRow(offer: offer) {
                        Task { await viewModel.accept(offer: offer) }
                    } onReject: {
                        Task { await viewModel.reject(offer: offer) }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Offers")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .refreshable {
            await viewModel.loadOffers(propertyId: property.id)
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
            await viewModel.loadOffers(propertyId: property.id)
        }
    }
}

@available(iOS 15.0, macOS 12.0, *)
private struct OfferRow: View {
    let offer: Offer
    let onAccept: () -> Void
    let onReject: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(formattedAmount)
                        .font(.headline)
                    Text(offer.buyer?.name ?? "Buyer")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                offerStatusBadge
            }

            if let msg = offer.message, !msg.isEmpty {
                Text(msg)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }

            if offer.status == .pending {
                HStack(spacing: 12) {
                    Button(action: onAccept) {
                        Text("Accept")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    Button(action: onReject) {
                        Text("Reject")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.red.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }

    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: offer.amount)) ?? "$\(offer.amount)"
    }

    private var offerStatusBadge: some View {
        Text(offer.status.rawValue.capitalized)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(badgeColor)
            .foregroundColor(.white)
            .cornerRadius(4)
    }

    private var badgeColor: Color {
        switch offer.status {
        case .pending:  return .orange
        case .accepted: return .green
        case .rejected: return .gray
        case .withdrawn: return .red
        }
    }
}
