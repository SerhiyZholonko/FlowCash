import Foundation
import FactoryKit

struct TransactionGroup: Identifiable {
    let id: String
    let title: String
    let transactions: [Transaction]

    var total: Double {
        transactions.reduce(0) { acc, t in
            acc + (t.type == .expense ? -t.amount : t.amount)
        }
    }
}

@MainActor
@Observable
final class TransactionsViewModel: ErrorDisplayable, AlertDisplayable {
    var allTransactions: [Transaction] = []
    var searchText: String = ""
    var isAddingTransaction = false
    var editingTransaction: Transaction?
    var error: Error?
    var alert: AppAlert?

    /// Якщо задано — показуємо лише транзакції цього типу (напр. лише доходи).
    let typeFilter: TransactionType?

    @ObservationIgnored
    @Injected(\.dataStore) private var store

    init(typeFilter: TransactionType? = nil) {
        self.typeFilter = typeFilter
    }

    var navigationTitle: String {
        switch typeFilter {
        case .income:  L("Доходи")
        case .expense: L("Витрати")
        case nil:      L("Транзакції")
        }
    }

    var filtered: [Transaction] {
        var result = allTransactions
        if let typeFilter {
            result = result.filter { $0.type == typeFilter }
        }
        guard !searchText.isEmpty else { return result }
        let q = searchText.lowercased()
        return result.filter { t in
            t.note.lowercased().contains(q) ||
            (t.category?.name.lowercased().contains(q) ?? false)
        }
    }

    var grouped: [TransactionGroup] {
        let cal = Calendar.current
        let byDay = Dictionary(grouping: filtered) { t in
            cal.startOfDay(for: t.date)
        }
        return byDay.keys
            .sorted(by: >)
            .map { day in
                let txns = byDay[day]!.sorted { $0.date > $1.date }
                return TransactionGroup(
                    id: day.formatted(),
                    title: dayTitle(for: day),
                    transactions: txns
                )
            }
    }

    func loadData() {
        Task(handlingError: self) { [weak self] in
            guard let self else { return }
            allTransactions = try await store.fetchTransactions()
        }
    }

    func delete(_ transaction: Transaction) {
        Task(handlingError: self) { [weak self] in
            guard let self else { return }
            // Відкочуємо вплив транзакції на баланс рахунку перед видаленням.
            if let account = transaction.account {
                account.balance -= transaction.signedAmount
            }
            try await store.delete(transaction)
            allTransactions.removeAll { $0.id == transaction.id }
        }
    }

    private func dayTitle(for date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return L("Сьогодні") }
        if cal.isDateInYesterday(date) { return L("Вчора") }
        let f = DateFormatter()
        f.locale = LocalizationManager.shared.locale
        f.dateFormat = "d MMMM"
        return f.string(from: date)
    }
}
