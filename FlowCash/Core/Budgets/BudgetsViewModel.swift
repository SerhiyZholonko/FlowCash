import Foundation
import FactoryKit

struct BudgetItem: Identifiable {
    let id: UUID
    let categoryName: String
    let categoryColor: String
    let categoryIcon: String
    let spent: Double
    let limit: Double

    var percentage: Double { limit > 0 ? min(spent / limit, 1.5) : 0 }
    var percentageInt: Int { Int(percentage * 100) }

    var status: BudgetStatus {
        let pct = limit > 0 ? spent / limit : 0
        if pct >= 1.0 { return .exceeded }
        if pct >= 0.6 { return .nearLimit }
        return .ok
    }
}

enum BudgetStatus {
    case ok, nearLimit, exceeded

    var label: String {
        switch self {
        case .ok: return ""
        case .nearLimit: return L("Близько до ліміту")
        case .exceeded: return L("Перевищено")
        }
    }

    var color: Color {
        switch self {
        case .ok: return .incomeGreen
        case .nearLimit: return Color(hex: "#fbbf24")
        case .exceeded: return .expenseRed
        }
    }
}

import SwiftUI

@MainActor
@Observable
final class BudgetsViewModel: ErrorDisplayable, AlertDisplayable {
    var transactions: [Transaction] = []
    var categories: [Category] = []
    var budgets: [Budget] = []
    var error: Error?
    var alert: AppAlert?

    @ObservationIgnored
    @Injected(\.dataStore) private var store

    var budgetItems: [BudgetItem] {
        budgets.compactMap { budget in
            guard let category = categories.first(where: { $0.id == budget.categoryID }) else { return nil }
            let cal = Calendar.current
            let spent = transactions
                .filter { $0.type == .expense && $0.category?.id == budget.categoryID
                    && cal.isDate($0.date, equalTo: Date(), toGranularity: .month) }
                .reduce(0) { $0 + $1.amount }
            return BudgetItem(
                id: budget.id,
                categoryName: category.name,
                categoryColor: category.color,
                categoryIcon: category.icon,
                spent: spent,
                limit: budget.monthlyLimit
            )
        }
        .sorted { $0.percentage > $1.percentage }
    }

    var totalSpent: Double { budgetItems.reduce(0) { $0 + $1.spent } }
    var totalLimit: Double { budgetItems.reduce(0) { $0 + $1.limit } }
    var totalPercentage: Double { totalLimit > 0 ? min(totalSpent / totalLimit, 1) : 0 }

    var daysLeft: Int {
        let cal = Calendar.current
        let now = Date()
        let range = cal.range(of: .day, in: .month, for: now) ?? 1..<31
        let day = cal.component(.day, from: now)
        return range.count - day
    }

    func loadData() {
        Task(handlingError: self) { [weak self] in
            guard let self else { return }
            async let t = store.fetchTransactions()
            async let c = store.fetchCategories()
            async let b = store.fetchBudgets()
            transactions = try await t
            categories = try await c
            budgets = try await b
        }
    }
}
