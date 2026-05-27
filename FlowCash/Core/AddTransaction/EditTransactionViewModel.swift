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
    var error: Error?
    var alert: AppAlert?

    private let transaction: Transaction

    @ObservationIgnored
    @Injected(\.dataStore) private var store

    var amountValue: Double { Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0 }
    var isValid: Bool { amountValue > 0 }

    init(transaction: Transaction) {
        self.transaction = transaction
        self.amount = transaction.amount > 0 ? String(format: "%.0f", transaction.amount) : ""
        self.selectedType = transaction.type
        self.note = transaction.note
        self.date = transaction.date
        self.selectedCategory = transaction.category
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

    func save() async throws {
        transaction.amount = amountValue
        transaction.type = selectedType
        transaction.note = note
        transaction.date = date
        transaction.category = selectedCategory
        try await store.update(transaction)
    }
}
