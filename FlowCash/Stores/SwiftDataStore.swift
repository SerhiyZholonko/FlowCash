import SwiftData
import Foundation

@MainActor
final class SwiftDataStore: DataStoreProtocol {
    private let context: ModelContext

    init(container: ModelContainer) {
        self.context = container.mainContext
    }

    // MARK: - Transactions

    func fetchTransactions() async throws -> [Transaction] {
        let descriptor = FetchDescriptor<Transaction>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func add(_ transaction: Transaction) async throws {
        context.insert(transaction)
        try context.save()
    }

    func update(_ transaction: Transaction) async throws {
        try context.save()
    }

    func delete(_ transaction: Transaction) async throws {
        context.delete(transaction)
        try context.save()
    }

    // MARK: - Categories

    func fetchCategories() async throws -> [Category] {
        let descriptor = FetchDescriptor<Category>(
            sortBy: [SortDescriptor(\.order), SortDescriptor(\.name)]
        )
        return try context.fetch(descriptor)
    }

    func add(_ category: Category) async throws {
        context.insert(category)
        try context.save()
    }

    func update(_ category: Category) async throws {
        try context.save()
    }

    func delete(_ category: Category) async throws {
        context.delete(category)
        try context.save()
    }

    // MARK: - Accounts

    func fetchAccounts() async throws -> [Account] {
        let descriptor = FetchDescriptor<Account>(
            sortBy: [SortDescriptor(\.order)]
        )
        return try context.fetch(descriptor)
    }

    func add(_ account: Account) async throws {
        context.insert(account)
        try context.save()
    }

    func update(_ account: Account) async throws {
        try context.save()
    }

    func delete(_ account: Account) async throws {
        context.delete(account)
        try context.save()
    }

    // MARK: - Budgets

    func fetchBudgets() async throws -> [Budget] {
        let descriptor = FetchDescriptor<Budget>()
        return try context.fetch(descriptor)
    }

    func add(_ budget: Budget) async throws {
        context.insert(budget)
        try context.save()
    }

    func update(_ budget: Budget) async throws {
        try context.save()
    }

    func delete(_ budget: Budget) async throws {
        context.delete(budget)
        try context.save()
    }
}
