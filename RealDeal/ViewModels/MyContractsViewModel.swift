import Foundation

/// Backs MyContractsView: the guaranteed entry point to a contract for both
/// parties (an accepted property leaves search — status pending — so
/// PropertyDetailView may be unreachable for the buyer once an offer is
/// accepted). Loads all contracts (buyer or seller side) for the current user.
@MainActor
@available(iOS 15.0, macOS 12.0, *)
class MyContractsViewModel: ObservableObject {
    @Published var contracts: [Contract] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let remoteDataSource: RemoteDataSourceProtocol

    init(remoteDataSource: RemoteDataSourceProtocol) {
        self.remoteDataSource = remoteDataSource
    }

    func loadContracts() async {
        isLoading = true
        errorMessage = nil
        do {
            contracts = try await remoteDataSource.fetchMyContracts()
        } catch {
            errorMessage = "Failed to load contracts."
        }
        isLoading = false
    }
}
