import Foundation
import FactoryKit

enum StatsPeriod: String, CaseIterable {
    case week  = "Тиждень"
    case month = "Місяць"
    case year  = "Рік"
    case all   = "Все"
}

@MainActor
@Observable
final class StatsViewModel: ErrorDisplayable, AlertDisplayable {
    var allTransactions: [Transaction] = []
    var selectedPeriod: StatsPeriod = .month
    var error: Error?
    var alert: AppAlert?

    @ObservationIgnored
    @Injected(\.dataStore) private var store

    var transactions: [Transaction] {
        let cal = Calendar.current
        let now = Date()
        switch selectedPeriod {
        case .week:
            let start = cal.date(byAdding: .day, value: -7, to: now) ?? now
            return allTransactions.filter { $0.date >= start }
        case .month:
            return allTransactions.filter {
                cal.isDate($0.date, equalTo: now, toGranularity: .month)
            }
        case .year:
            return allTransactions.filter {
                cal.isDate($0.date, equalTo: now, toGranularity: .year)
            }
        case .all:
            return allTransactions
        }
    }

    var expensesByCategory: [CategoryStat] {
        Dictionary(
            grouping: transactions.filter { $0.type == .expense },
            by: { $0.category?.id ?? UUID() }
        )
        .compactMap { _, group -> CategoryStat? in
            guard let first = group.first else { return nil }
            let total = group.reduce(0) { $0 + $1.amount }
            return CategoryStat(
                name: first.category?.name ?? "Інше",
                color: first.category?.color ?? "#cbd5e1",
                icon: first.category?.icon ?? "ellipsis.circle",
                total: total
            )
        }
        .sorted { $0.total > $1.total }
    }

    var totalExpense: Double {
        transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    var totalExpenseForPercent: Double { totalExpense > 0 ? totalExpense : 1 }

    func loadData() {
        Task(handlingError: self) { [weak self] in
            guard let self else { return }
            allTransactions = try await store.fetchTransactions()
        }
    }
}
