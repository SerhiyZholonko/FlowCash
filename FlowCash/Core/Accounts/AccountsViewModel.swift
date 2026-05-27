import Foundation
import FactoryKit

@MainActor
@Observable
final class AccountsViewModel: ErrorDisplayable, AlertDisplayable {
    var accounts: [Account] = []
    var error: Error?
    var alert: AppAlert?

    @ObservationIgnored
    @Injected(\.dataStore) private var store

    var totalBalance: Double {
        accounts.reduce(0) { $0 + $1.balance }
    }

    func loadData() {
        Task(handlingError: self) { [weak self] in
            guard let self else { return }
            accounts = try await store.fetchAccounts()
        }
    }
}
