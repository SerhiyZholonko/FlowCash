import Foundation
import FactoryKit
import WidgetKit

@MainActor
@Observable
final class HomeViewModel: ErrorDisplayable, AlertDisplayable {
    var allTransactions: [Transaction] = []
    var accounts: [Account] = []
    var selectedMonth: Date = Date()
    var preferredAccountId: UUID?
    var isAddingExpense = false
    var isAddingIncome = false
    /// true до завершення першого завантаження даних — керує показом заставки.
    var isLoading = true
    var error: Error?
    var alert: AppAlert?

    @ObservationIgnored
    @Injected(\.dataStore) private var store

    // MARK: - Selected account

    /// Активний рахунок: бажаний вибір або перший як запасний варіант.
    var effectiveAccountId: UUID? {
        accounts.first { $0.id == preferredAccountId }?.id ?? accounts.first?.id
    }

    // MARK: - Filtered transactions

    /// Транзакції активного рахунку за обраний місяць.
    var transactions: [Transaction] {
        allTransactions.filter {
            $0.account?.id == effectiveAccountId
            && Calendar.current.isDate($0.date, equalTo: selectedMonth, toGranularity: .month)
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
                name: first.category?.name ?? L("Інше"),
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

    /// Мінімальний час показу заставки, щоб анімація встигла відпрацювати навіть при швидкому завантаженні.
    private let splashMinimumDuration: TimeInterval = 2.0

    func loadData() {
        let showsSplash = isLoading
        let startedAt = Date()
        Task(handlingError: self) { [weak self] in
            guard let self else { return }
            do {
                allTransactions = try await store.fetchTransactions()
                accounts = try await store.fetchAccounts()
                writeWidgetSnapshot()
            } catch {
                self.error = error
            }
            // Заставку показуємо щонайменше splashMinimumDuration і ховаємо навіть при помилці.
            guard showsSplash else { return }
            let remaining = splashMinimumDuration - Date().timeIntervalSince(startedAt)
            if remaining > 0 {
                try? await Task.sleep(for: .seconds(remaining))
            }
            isLoading = false
        }
    }

    /// Записує зведення активного рахунку в App Group для віджета.
    func writeWidgetSnapshot() {
        let account = accounts.first { $0.id == effectiveAccountId }
        let formatter = DateFormatter()
        formatter.locale = LocalizationManager.shared.locale
        formatter.dateFormat = "LLLL yyyy"

        let snapshot = FinanceSnapshot(
            accountName: account?.name ?? L("Усі рахунки"),
            monthTitle: formatter.string(from: selectedMonth).capitalized,
            incomeText: totalIncome.formattedCurrency,
            expenseText: totalExpense.formattedCurrency,
            balanceText: totalBalance.formattedCurrency
        )

        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        WidgetShared.defaults?.set(data, forKey: WidgetShared.snapshotKey)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
