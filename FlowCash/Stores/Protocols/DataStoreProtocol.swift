import Foundation

@MainActor
protocol DataStoreProtocol: AnyObject {
    func fetchTransactions() async throws -> [Transaction]
    func add(_ transaction: Transaction) async throws
    func update(_ transaction: Transaction) async throws
    func delete(_ transaction: Transaction) async throws

    func fetchCategories() async throws -> [Category]
    func add(_ category: Category) async throws
    func update(_ category: Category) async throws
    func delete(_ category: Category) async throws

    func fetchAccounts() async throws -> [Account]
    func add(_ account: Account) async throws
    func update(_ account: Account) async throws
    func delete(_ account: Account) async throws

    func fetchBudgets() async throws -> [Budget]
    func add(_ budget: Budget) async throws
    func update(_ budget: Budget) async throws
    func delete(_ budget: Budget) async throws

    /// Повне видалення всіх даних (для Debug-скидання). Видалення синхронізується в iCloud.
    func deleteAllData() async throws
}
