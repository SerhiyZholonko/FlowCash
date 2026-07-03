import Foundation
import FactoryKit

@MainActor
@Observable
final class EditTransactionViewModel: ErrorDisplayable, AlertDisplayable {
    var amount: String
    var selectedType: TransactionType
    var note: String
    var date: Date
    var categories: [Category] = []
    var selectedCategory: Category?
    var accounts: [Account] = []
    var selectedAccount: Account?
    var isShowingAccountPicker = false
    var error: Error?
    var alert: AppAlert?

    private let transaction: Transaction

    @ObservationIgnored
    @Injected(\.dataStore) private var store

    var amountValue: Double { Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0 }
    var isValid: Bool { amountValue > 0 && selectedAccount != nil }

    /// Категорії лише обраного типу — дохід і витрати мають окремі набори.
    var filteredCategories: [Category] {
        categories.filter { $0.type == selectedType }
    }

    /// Викликати при зміні типу: знімаємо вибір категорії, якщо вона іншого типу,
    /// інакше можна зберегти, напр., дохід із категорією витрат.
    func typeChanged() {
        if let category = selectedCategory, category.type != selectedType {
            selectedCategory = nil
        }
    }

    init(transaction: Transaction) {
        self.transaction = transaction
        self.amount = transaction.amount > 0 ? String(format: "%.0f", transaction.amount) : ""
        self.selectedType = transaction.type
        self.note = transaction.note
        self.date = transaction.date
        self.selectedCategory = transaction.category
        self.selectedAccount = transaction.account
    }

    func loadCategories() {
        Task(handlingError: self) { [weak self] in
            guard let self else { return }
            categories = try await store.fetchCategories().filter { !$0.isHidden }
            // Reselect the matching category from the loaded list
            if let existing = selectedCategory {
                selectedCategory = categories.first { $0.id == existing.id } ?? selectedCategory
            }
        }
    }

    func loadAccounts() {
        Task(handlingError: self) { [weak self] in
            guard let self else { return }
            accounts = try await store.fetchAccounts()
            // Reselect the matching account from the loaded list
            if let existing = selectedAccount {
                selectedAccount = accounts.first { $0.id == existing.id } ?? selectedAccount
            }
        }
    }

    func delete() async throws {
        // Відкочуємо вплив транзакції на баланс рахунку перед видаленням.
        if let account = transaction.account {
            account.balance -= transaction.signedAmount
        }
        try await store.delete(transaction)
    }

    func save() async throws {
        let previousSigned = transaction.signedAmount
        let previousAccount = transaction.account
        let accountChanged = previousAccount?.id != selectedAccount?.id

        transaction.amount = amountValue
        transaction.type = selectedType
        transaction.note = note
        transaction.date = date

        // Переприсвоюємо зв'язки лише при реальній зміні: переприсвоєння to-one
        // relationship із інверсним to-many призводить до «stale» зв'язків у контексті
        // після save (транзакція тимчасово зникає зі списку категорії/рахунку).
        if transaction.category?.id != selectedCategory?.id {
            transaction.category = selectedCategory
        }

        if accountChanged {
            transaction.account = selectedAccount
            // Рахунок змінено — знімаємо старий вплив і додаємо новий.
            previousAccount?.balance -= previousSigned
            selectedAccount?.balance += transaction.signedAmount
        } else {
            // Той самий рахунок — коригуємо на різницю старого й нового впливу.
            selectedAccount?.balance += transaction.signedAmount - previousSigned
        }
        try await store.update(transaction)
    }
}
