import Foundation

// ВАЖЛИВО: цей файл має ідентичну копію у віджеті (FlowCashWidget/WidgetShared.swift).
// Тримайте обидві версії синхронними — застосунок пише знімок, віджет читає.

enum WidgetShared {
    /// App Group, спільний для застосунку та віджета. Має збігатися з тим,
    /// що увімкнено в capability обох таргетів.
    static let appGroup = "group.com.zholonko.www.ToDoList.FlowCash"
    static let snapshotKey = "financeSnapshot"
    /// Код обраної в застосунку мови ("uk"/"en") — щоб віджет рендерився тією ж мовою.
    static let languageCodeKey = "widgetLanguageCode"

    static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroup)
    }
}

/// Зведення за місяць для активного рахунку — готові до показу рядки.
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
