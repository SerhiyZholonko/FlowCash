import Foundation

/// Маршрутизація deep links з віджета: відкриває екран додавання транзакції.
@MainActor
@Observable
final class DeepLinkRouter {
    var pendingAdd: TransactionType?

    /// Розбирає URL виду flowcash://add/income або flowcash://add/expense.
    func handle(_ url: URL) {
        guard url.scheme == "flowcash", url.host == "add" else { return }
        switch url.lastPathComponent {
        case "income":  pendingAdd = .income
        case "expense": pendingAdd = .expense
        default:        break
        }
    }
}
