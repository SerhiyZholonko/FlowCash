import Foundation
import FactoryKit

struct ExportFile: Identifiable {
    let id = UUID()
    let url: URL
}

@MainActor
@Observable
final class SettingsViewModel: ErrorDisplayable {
    var error: Error?
    var exportFile: ExportFile?
    var hasData = false
    var accounts: [Account] = []

    /// Прапор успішного Debug-видалення — тригерить alert «перезапустіть застосунок».
    var didDeleteAllData = false

    @ObservationIgnored
    @Injected(\.dataStore) private var store

    /// Підвантажує наявність транзакцій — кнопка експорту активна лише якщо є що експортувати.
    func load() {
        Task(handlingError: self) { [weak self] in
            guard let self else { return }
            hasData = try await !store.fetchTransactions().isEmpty
            accounts = try await store.fetchAccounts()
        }
    }

    /// Debug-скидання: видаляє всі дані (синхронізується в iCloud). Прапор seed
    /// лишається встановленим, тож дефолтні категорії/рахунки НЕ відновлюються —
    /// застосунок лишається порожнім.
    func deleteAllICloudData() {
        Task(handlingError: self) { [weak self] in
            guard let self else { return }
            try await store.deleteAllData()
            hasData = false
            accounts = []
            didDeleteAllData = true
        }
    }

    func exportCSV() {
        Task(handlingError: self) { [weak self] in
            guard let self else { return }
            let transactions = try await store.fetchTransactions()
            let url = try Self.writeCSV(transactions)
            exportFile = ExportFile(url: url)
        }
    }

    // MARK: - CSV

    private static func writeCSV(_ transactions: [Transaction]) throws -> URL {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "uk_UA")
        formatter.dateFormat = "yyyy-MM-dd"

        var rows = [L("Дата,Тип,Категорія,Сума,Нотатка")]
        for transaction in transactions {
            let fields = [
                formatter.string(from: transaction.date),
                transaction.type.title,
                transaction.category?.name ?? "",
                String(format: "%.2f", transaction.amount),
                transaction.note
            ]
            rows.append(fields.map(escape).joined(separator: ","))
        }

        // BOM, щоб Excel коректно показував кирилицю.
        let csv = "\u{FEFF}" + rows.joined(separator: "\n")
        let url = FileManager.default.temporaryDirectory.appending(path: "FlowCash.csv")
        try csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private static func escape(_ field: String) -> String {
        guard field.contains(",") || field.contains("\"") || field.contains("\n") else {
            return field
        }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
