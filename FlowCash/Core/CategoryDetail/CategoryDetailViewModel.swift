import Foundation
import FactoryKit

struct MonthBar: Identifiable {
    let id = UUID()
    let month: String
    let total: Double
    let isCurrent: Bool
}

@MainActor
@Observable
final class CategoryDetailViewModel: ErrorDisplayable, AlertDisplayable {
    var transactions: [Transaction] = []
    var error: Error?
    var alert: AppAlert?

    let stat: CategoryStat

    @ObservationIgnored
    @Injected(\.dataStore) private var store

    init(stat: CategoryStat) {
        self.stat = stat
    }

    var categoryTransactions: [Transaction] {
        transactions.filter { $0.category?.name == stat.name }
            .sorted { $0.date > $1.date }
    }

    var monthlyBars: [MonthBar] {
        let cal = Calendar.current
        let now = Date()
        let locale = Locale(identifier: "uk_UA")

        return (0..<6).reversed().map { offset in
            guard let month = cal.date(byAdding: .month, value: -offset, to: now) else {
                return MonthBar(month: "", total: 0, isCurrent: false)
            }
            let total = transactions
                .filter { $0.category?.name == stat.name && cal.isDate($0.date, equalTo: month, toGranularity: .month) }
                .reduce(0) { $0 + $1.amount }

            let f = DateFormatter()
            f.locale = locale
            f.dateFormat = "LLL"
            let label = f.string(from: month).capitalized

            return MonthBar(
                month: label,
                total: total,
                isCurrent: offset == 0
            )
        }
    }

    var maxBarTotal: Double { monthlyBars.map(\.total).max() ?? 1 }

    func loadData() {
        Task(handlingError: self) { [weak self] in
            guard let self else { return }
            transactions = try await store.fetchTransactions()
        }
    }
}
