import Foundation
import FactoryKit

@MainActor
@Observable
final class AccountsViewModel: ErrorDisplayable, AlertDisplayable {
    var accounts: [Account] = []
    var error: Error?
    var alert: AppAlert?

    // MARK: - Editor (add / edit)
    var isShowingEditor = false
    var editingAccount: Account?
    var draftName = ""
    var draftType: AccountType = .cash
    var draftBalance = "0"
    var draftColor = "#22c55e"

    // MARK: - Transfer
    var isShowingTransfer = false
    var transferFromId: UUID?
    var transferToId: UUID?
    var transferAmount = "0"

    let colorSwatches: [String] = [
        "#22c55e", "#3b82f6", "#818cf8", "#f59e0b",
        "#ef4444", "#14b8a6", "#a855f7", "#ec4899"
    ]

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

    // MARK: - Editor

    var isEditorValid: Bool {
        !draftName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func presentNewAccount() {
        editingAccount = nil
        draftName = ""
        draftType = .cash
        draftBalance = "0"
        draftColor = colorSwatches.first ?? "#22c55e"
        isShowingEditor = true
    }

    func presentEdit(_ account: Account) {
        editingAccount = account
        draftName = account.name
        draftType = account.type
        draftBalance = String(format: "%g", account.balance)
        draftColor = account.color
        isShowingEditor = true
    }

    func saveAccount() {
        let name = draftName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let balance = Double(draftBalance.replacingOccurrences(of: ",", with: ".")) ?? 0
        let type = draftType
        let color = draftColor

        Task(handlingError: self) { [weak self] in
            guard let self else { return }
            if let account = editingAccount {
                account.name = name
                account.type = type
                account.icon = type.icon
                account.balance = balance
                account.color = color
                try await store.update(account)
            } else {
                let account = Account(
                    name: name,
                    type: type,
                    balance: balance,
                    color: color,
                    icon: type.icon,
                    order: accounts.count
                )
                try await store.add(account)
            }
            accounts = try await store.fetchAccounts()
            isShowingEditor = false
        }
    }

    func deleteAccount(_ account: Account) {
        Task(handlingError: self) { [weak self] in
            guard let self else { return }
            try await store.delete(account)
            accounts.removeAll { $0.id == account.id }
        }
    }

    // MARK: - Transfer

    var transferFrom: Account? { accounts.first { $0.id == transferFromId } }
    var transferTo: Account? { accounts.first { $0.id == transferToId } }

    var transferAmountValue: Double {
        Double(transferAmount.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    var isTransferValid: Bool {
        guard let from = transferFrom, let to = transferTo, from.id != to.id else { return false }
        return transferAmountValue > 0 && transferAmountValue <= from.balance
    }

    func presentTransfer() {
        transferFromId = accounts.first?.id
        transferToId = accounts.first(where: { $0.id != transferFromId })?.id
        transferAmount = "0"
        isShowingTransfer = true
    }

    func transfer() {
        guard let from = transferFrom, let to = transferTo, isTransferValid else { return }
        let amount = transferAmountValue
        Task(handlingError: self) { [weak self] in
            guard let self else { return }
            from.balance -= amount
            to.balance += amount
            try await store.update(from)
            try await store.update(to)
            accounts = try await store.fetchAccounts()
            isShowingTransfer = false
        }
    }
}
