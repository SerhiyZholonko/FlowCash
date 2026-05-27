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

    @ObservationIgnored
    @Injected(\.dataStore) private var store

    var filtered: [Transaction] {
        guard !searchText.isEmpty else { return allTransactions }
        let q = searchText.lowercased()
        return allTransactions.filter { t in
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
            try await store.delete(transaction)
            allTransactions.removeAll { $0.id == transaction.id }
        }
    }

    private func dayTitle(for date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Сьогодні" }
        if cal.isDateInYesterday(date) { return "Вчора" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "uk_UA")
        f.dateFormat = "d MMMM"
        return f.string(from: date)
    }
}
