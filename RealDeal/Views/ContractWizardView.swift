import SwiftUI

/// Contract/signing wizard (MVP step 5). STATE-driven, not step-driven: the
/// contract's status determines what's shown — a progress indicator, the
/// terms proposal/edit form, an agree step, a documents stub + sign step, a
/// cancel action, and a deadline countdown. Terminal states (executed,
/// cancelled, expired) render a dedicated terminal screen. No push
/// notifications exist yet, so state is fetched on open with pull-to-refresh
/// so a party can see the other side's actions.
@available(iOS 15.0, macOS 12.0, *)
struct ContractWizardView: View {
    @StateObject var viewModel: ContractWizardViewModel
    @State private var showCancelConfirmation = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.contract == nil {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let contract = viewModel.contract {
                if viewModel.isTerminal {
                    terminalView(contract)
                } else {
                    activeWizard(contract)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text(viewModel.errorMessage ?? "Contract not found.")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Contract")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await viewModel.loadContract() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .refreshable {
            await viewModel.loadContract()
        }
        .task {
            if viewModel.contract == nil {
                await viewModel.loadContract()
            }
        }
    }

    // MARK: - Active (non-terminal) wizard

    @ViewBuilder
    private func activeWizard(_ contract: Contract) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                progressIndicator(contract)

                if let deadlineText = deadlineText {
                    Label(deadlineText, systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.orange)
                }

                Divider()

                termsSection(contract)

                Divider()

                agreementSection(contract)

                Divider()

                signingSection(contract)

                if viewModel.canCancel {
                    Divider()
                    cancelSection
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .padding()
        }
        .alert("Cancel Contract", isPresented: $showCancelConfirmation) {
            Button("Keep Contract", role: .cancel) {}
            Button("Cancel Contract", role: .destructive) {
                Task { await viewModel.cancel() }
            }
        } message: {
            Text("Are you sure you want to cancel this contract? This action cannot be undone and the listing will return to search.")
        }
    }

    private var deadlineText: String? {
        guard let seconds = viewModel.timeUntilDeadline, seconds > 0 else { return nil }
        let days = Int(seconds / 86400)
        if days > 0 {
            return "Execution deadline: \(days) day\(days == 1 ? "" : "s") remaining"
        }
        let hours = max(Int(seconds / 3600), 0)
        return "Execution deadline: \(hours) hour\(hours == 1 ? "" : "s") remaining"
    }

    // MARK: - Progress indicator

    @ViewBuilder
    private func progressIndicator(_ contract: Contract) -> some View {
        HStack(spacing: 4) {
            progressStep(label: "Terms", isDone: contract.termsProposedBy != nil)
            progressConnector(isDone: contract.status != .draft || (contract.buyerAgreedAt != nil && contract.sellerAgreedAt != nil))
            progressStep(label: "Agreement", isDone: contract.status == .termsAgreed || contract.status == .buyerSigned || contract.status == .sellerSigned || contract.status == .executed)
            progressConnector(isDone: contract.status == .executed)
            progressStep(label: "Signatures", isDone: contract.status == .executed)
        }
    }

    private func progressStep(label: String, isDone: Bool) -> some View {
        VStack(spacing: 4) {
            Circle()
                .fill(isDone ? Color.green : Color.gray.opacity(0.3))
                .frame(width: 24, height: 24)
                .overlay(
                    Group {
                        if isDone {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                )
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private func progressConnector(isDone: Bool) -> some View {
        Rectangle()
            .fill(isDone ? Color.green : Color.gray.opacity(0.3))
            .frame(height: 2)
            .frame(maxWidth: .infinity)
    }

    // MARK: - Terms

    @ViewBuilder
    private func termsSection(_ contract: Contract) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Terms")
                .font(.headline)

            if contract.termsProposedBy == nil {
                Text("No terms proposed yet.")
                    .font(.body)
                    .foregroundColor(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    if let moveIn = contract.moveInDate {
                        labeledRow("Move-in Date", formattedDate(moveIn))
                    }
                    if let transfer = contract.transferDate {
                        labeledRow("Transfer Date", formattedDate(transfer))
                    }
                    if !contract.conditions.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Conditions")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(contract.conditions)
                                .font(.body)
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }

            if viewModel.canProposeTerms {
                DisclosureGroup(contract.termsProposedBy == nil ? "Propose Terms" : "Edit Terms") {
                    termsForm
                }
                .font(.subheadline)
            }
        }
    }

    private var termsForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            if contract?.status != .draft || viewModel.contract?.termsProposedBy != nil {
                Text("Changing terms voids the other party's agreement and any signatures already collected.")
                    .font(.caption)
                    .foregroundColor(.orange)
            }

            DatePicker(
                "Move-in Date",
                selection: Binding(
                    get: { viewModel.moveInDate ?? Date().addingTimeInterval(86400 * 30) },
                    set: { viewModel.moveInDate = $0 }
                ),
                displayedComponents: .date
            )
            Toggle("Set move-in date", isOn: Binding(
                get: { viewModel.moveInDate != nil },
                set: { viewModel.moveInDate = $0 ? (viewModel.moveInDate ?? Date().addingTimeInterval(86400 * 30)) : nil }
            ))

            DatePicker(
                "Transfer Date",
                selection: Binding(
                    get: { viewModel.transferDate ?? Date().addingTimeInterval(86400 * 30) },
                    set: { viewModel.transferDate = $0 }
                ),
                displayedComponents: .date
            )
            Toggle("Set transfer date", isOn: Binding(
                get: { viewModel.transferDate != nil },
                set: { viewModel.transferDate = $0 ? (viewModel.transferDate ?? Date().addingTimeInterval(86400 * 30)) : nil }
            ))

            VStack(alignment: .leading, spacing: 4) {
                Text("Conditions")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("e.g. sale contingent on inspection", text: $viewModel.conditions, axis: .vertical)
                    .lineLimit(3...8)
            }

            Button {
                Task { await viewModel.proposeTerms() }
            } label: {
                if viewModel.isSubmitting {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text(contract?.termsProposedBy == nil ? "Propose Terms" : "Update Terms")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(viewModel.isSubmitting)
        }
        .padding(.top, 8)
    }

    // Helper for the warning inside the disclosure group (avoids referencing
    // `contract` param from an unrelated computed property scope).
    private var contract: Contract? { viewModel.contract }

    // MARK: - Agreement

    @ViewBuilder
    private func agreementSection(_ contract: Contract) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Agreement")
                .font(.headline)

            HStack {
                agreementStatusRow(title: "You", agreedAt: viewModel.myAgreedAt)
                Spacer()
                agreementStatusRow(title: "Other Party", agreedAt: viewModel.otherAgreedAt)
            }

            if viewModel.canAgree {
                Button {
                    Task { await viewModel.agree() }
                } label: {
                    if viewModel.isSubmitting {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Agree to Terms")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(viewModel.isSubmitting)
            } else if contract.termsProposedBy == nil {
                Text("Waiting for terms to be proposed.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func agreementStatusRow(title: String, agreedAt: Date?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            HStack(spacing: 4) {
                Image(systemName: agreedAt != nil ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(agreedAt != nil ? .green : .gray)
                Text(agreedAt != nil ? "Agreed" : "Pending")
                    .font(.subheadline)
            }
        }
    }

    // MARK: - Signing

    @ViewBuilder
    private func signingSection(_ contract: Contract) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Signing")
                .font(.headline)

            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(.secondary)
                Text("Purchase Agreement — preview unavailable (MVP)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)

            HStack {
                agreementStatusRow(title: "You", agreedAt: viewModel.mySignedAt)
                Spacer()
                agreementStatusRow(title: "Other Party", agreedAt: viewModel.otherSignedAt)
            }

            if viewModel.canSign {
                Button {
                    Task { await viewModel.sign() }
                } label: {
                    if viewModel.isSubmitting {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Sign Contract")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(viewModel.isSubmitting)
            } else if !viewModel.isTerminal && viewModel.mySignedAt == nil {
                Text("Both parties must agree to terms before signing.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Cancel

    private var cancelSection: some View {
        Button(role: .destructive) {
            showCancelConfirmation = true
        } label: {
            Text("Cancel Contract")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .foregroundColor(.red)
        .cornerRadius(10)
    }

    // MARK: - Terminal

    @ViewBuilder
    private func terminalView(_ contract: Contract) -> some View {
        VStack(spacing: 16) {
            Image(systemName: terminalIcon(contract.status))
                .font(.system(size: 56))
                .foregroundColor(terminalColor(contract.status))
            Text(terminalTitle(contract.status))
                .font(.title2)
                .fontWeight(.semibold)
            Text(terminalMessage(contract.status))
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private func terminalIcon(_ status: ContractStatus) -> String {
        switch status {
        case .executed: return "checkmark.seal.fill"
        case .cancelled: return "xmark.circle.fill"
        case .expired: return "clock.badge.exclamationmark.fill"
        default: return "questionmark.circle"
        }
    }

    private func terminalColor(_ status: ContractStatus) -> Color {
        switch status {
        case .executed: return .green
        case .cancelled: return .red
        case .expired: return .orange
        default: return .secondary
        }
    }

    private func terminalTitle(_ status: ContractStatus) -> String {
        switch status {
        case .executed: return "Contract Executed"
        case .cancelled: return "Contract Cancelled"
        case .expired: return "Contract Expired"
        default: return "Contract Closed"
        }
    }

    private func terminalMessage(_ status: ContractStatus) -> String {
        switch status {
        case .executed: return "Both parties have signed. The contract is complete."
        case .cancelled: return "This contract was cancelled and is no longer active."
        case .expired: return "This contract expired before both parties finished signing."
        default: return "This contract is no longer active."
        }
    }

    // MARK: - Formatting

    private func labeledRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - My Contracts

/// Simple list of the current user's contracts (buyer or seller side),
/// reachable from the Profile tab. This is the guaranteed entry point for
/// both parties: an accepted property leaves search (status pending), so
/// PropertyDetailView may be unreachable for the buyer once accepted.
@available(iOS 15.0, macOS 12.0, *)
struct MyContractsView: View {
    @StateObject var viewModel: MyContractsViewModel
    let currentUserId: String
    let remoteDataSource: RemoteDataSourceProtocol

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.contracts.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.contracts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No Contracts Yet")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(viewModel.contracts) { contract in
                    NavigationLink {
                        ContractWizardView(
                            viewModel: ContractWizardViewModel(
                                propertyId: contract.propertyId,
                                offerId: contract.offerId,
                                currentUserId: currentUserId,
                                remoteDataSource: remoteDataSource
                            )
                        )
                    } label: {
                        ContractRow(contract: contract)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("My Contracts")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .refreshable {
            await viewModel.loadContracts()
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
            await viewModel.loadContracts()
        }
    }
}

@available(iOS 15.0, macOS 12.0, *)
private struct ContractRow: View {
    let contract: Contract

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(contract.property?.address.street ?? "Property")
                .font(.headline)

            HStack {
                statusBadge
                Spacer()
                if let deadline = deadlineText {
                    Text(deadline)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var statusBadge: some View {
        Text(displayStatus)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(badgeColor)
            .foregroundColor(.white)
            .cornerRadius(4)
    }

    private var displayStatus: String {
        switch contract.status {
        case .draft: return "Draft"
        case .termsAgreed: return "Terms Agreed"
        case .buyerSigned: return "Buyer Signed"
        case .sellerSigned: return "Seller Signed"
        case .executed: return "Executed"
        case .cancelled: return "Cancelled"
        case .expired: return "Expired"
        }
    }

    private var badgeColor: Color {
        switch contract.status {
        case .draft: return .gray
        case .termsAgreed, .buyerSigned, .sellerSigned: return .orange
        case .executed: return .green
        case .cancelled, .expired: return .red
        }
    }

    private var deadlineText: String? {
        switch contract.status {
        case .executed, .cancelled, .expired: return nil
        default:
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return "Due \(formatter.string(from: contract.executionDeadline))"
        }
    }
}
