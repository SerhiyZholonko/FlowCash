import Foundation
import FactoryKit

@MainActor
@Observable
final class HomeViewModel: ErrorDisplayable, AlertDisplayable {
    var allTransactions: [Transaction] = []
    var selectedMonth: Date = Date()
    var isAddingExpense = false
    var isAddingIncome = false
    var error: Error?
    var alert: AppAlert?

    @ObservationIgnored
    @Injected(\.dataStore) private var store

    // MARK: - Filtered transactions

    var transactions: [Transaction] {
        allTransactions.filter {
            Calendar.current.isDate($0.date, equalTo: selectedMonth, toGranularity: .month)
        }
    }

    // MARK: - Totals

    var totalIncome: Double {
        transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    var totalExpense: Double {
        transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    var totalBalance: Double { totalIncome - totalExpense }

    // MARK: - Category breakdown (for donut + top list)

    var expensesByCategory: [CategoryStat] {
        Dictionary(
            grouping: transactions.filter { $0.type == .expense },
            by: { $0.category?.id ?? UUID() }
        )
        .compactMap { _, group -> CategoryStat? in
            guard let first = group.first else { return nil }
            return CategoryStat(
                name: first.category?.name ?? "Інше",
                color: first.category?.color ?? "#cbd5e1",
                icon: first.category?.icon ?? "ellipsis.circle",
                total: group.reduce(0) { $0 + $1.amount }
            )
        }
        .sorted { $0.total > $1.total }
    }

    var topExpenses: [CategoryStat] { Array(expensesByCategory.prefix(3)) }

    var totalExpenseForPercent: Double { totalExpense > 0 ? totalExpense : 1 }

    // MARK: - Actions

    func loadData() {
        Task(handlingError: self) { [weak self] in
            guard let self else { return }
            allTransactions = try await store.fetchTransactions()
        }
    }
}
