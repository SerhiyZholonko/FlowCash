import Foundation

/// Спільний стан активного рахунку — головний екран, додавання транзакцій
/// і налаштування читають/пишуть один вибір. Зберігається в UserDefaults.
@MainActor
@Observable
final class AccountSelection {
    static let key = "selectedAccountId"

    var selectedId: UUID? {
        didSet { UserDefaults.standard.set(selectedId?.uuidString, forKey: Self.key) }
    }

    init() {
        if let stored = UserDefaults.standard.string(forKey: Self.key) {
            selectedId = UUID(uuidString: stored)
        }
    }

    /// Повертає обраний рахунок зі списку, або перший як запасний варіант.
    func resolve(in accounts: [Account]) -> Account? {
        accounts.first { $0.id == selectedId } ?? accounts.first
    }
}
