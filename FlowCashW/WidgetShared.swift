import Foundation

// ВАЖЛИВО: ідентична копія у застосунку (FlowCash/Shared/WidgetShared.swift).
// Тримайте обидві версії синхронними.

enum WidgetShared {
    /// App Group, спільний для застосунку та віджета.
    static let appGroup = "group.com.zholonko.www.ToDoList.FlowCash"
    static let snapshotKey = "financeSnapshot"
    /// Код обраної в застосунку мови ("uk"/"en") — щоб віджет рендерився тією ж мовою.
    static let languageCodeKey = "widgetLanguageCode"

    static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroup)
    }
}

struct FinanceSnapshot: Codable {
    var accountName: String
    var monthTitle: String
    var incomeText: String
    var expenseText: String
    var balanceText: String

    static let placeholder = FinanceSnapshot(
        accountName: "Рахунок",
        monthTitle: "Цей місяць",
        incomeText: "0 ₴",
        expenseText: "0 ₴",
        balanceText: "0 ₴"
    )
}
