import Foundation

@MainActor
final class MockDataStore: DataStoreProtocol {

    // MARK: - Seed categories

    private let catFood        = Category(name: "Їжа",       icon: "fork.knife",       color: "#f87171", type: .expense, order: 0)
    private let catCafe        = Category(name: "Кафе",      icon: "cup.and.saucer",   color: "#fb923c", type: .expense, order: 1)
    private let catTransport   = Category(name: "Транспорт", icon: "tram",             color: "#fbbf24", type: .expense, order: 2)
    private let catEntertain   = Category(name: "Розваги",   icon: "gamecontroller",   color: "#c084fc", type: .expense, order: 3)
    private let catHealth      = Category(name: "Здоров'я",  icon: "heart",            color: "#f472b6", type: .expense, order: 4)
    private let catHome        = Category(name: "Дім",       icon: "house",            color: "#2dd4bf", type: .expense, order: 5)
    private let catClothes     = Category(name: "Одяг",      icon: "tshirt",           color: "#818cf8", type: .expense, order: 6)
    private let catEducation   = Category(name: "Освіта",    icon: "graduationcap",    color: "#60a5fa", type: .expense, order: 7)
    private let catGifts       = Category(name: "Подарунки", icon: "gift",             color: "#fb7185", type: .expense, order: 8)
    private let catTravel      = Category(name: "Подорожі",  icon: "airplane",         color: "#34d399", type: .expense, order: 9)
    private let catComms       = Category(name: "Зв'язок",   icon: "antenna.radiowaves.left.and.right", color: "#22d3ee", type: .expense, order: 10)
    private let catBeauty      = Category(name: "Краса",     icon: "sparkles",         color: "#e879f9", type: .expense, order: 11)
    private let catSport       = Category(name: "Спорт",     icon: "figure.run",       color: "#a3e635", type: .expense, order: 12)
    private let catBills       = Category(name: "Рахунки",   icon: "doc.text",         color: "#94a3b8", type: .expense, order: 13)
    private let catOther       = Category(name: "Інше",      icon: "ellipsis.circle",  color: "#cbd5e1", type: .expense, order: 14)
    private let catSalary      = Category(name: "Зарплата",  icon: "banknote",         color: "#22c55e", type: .income,  order: 15)
    private let catFreelance   = Category(name: "Фріланс",   icon: "laptopcomputer",   color: "#3b82f6", type: .income,  order: 16)

    private lazy var categories: [Category] = [
        catFood, catCafe, catTransport, catEntertain, catHealth,
        catHome, catClothes, catEducation, catGifts, catTravel,
        catComms, catBeauty, catSport, catBills, catOther,
        catSalary, catFreelance
    ]

    private lazy var transactions: [Transaction] = {
        let now = Date()
        let cal = Calendar.current
        func daysAgo(_ n: Int) -> Date { cal.date(byAdding: .day, value: -n, to: now) ?? now }
        return [
            Transaction(amount: 50000, type: .income,  category: catSalary,    date: daysAgo(0),  note: "Квітнева зарплата"),
            Transaction(amount: 1240,  type: .expense, category: catFood,       date: daysAgo(0),  note: "Сільпо, продукти на тиждень"),
            Transaction(amount: 85,    type: .expense, category: catCafe,       date: daysAgo(0),  note: "Капучіно"),
            Transaction(amount: 140,   type: .expense, category: catTransport,  date: daysAgo(0),  note: "Поїздка додому"),
            Transaction(amount: 8000,  type: .income,  category: catFreelance,  date: daysAgo(1),  note: "Аванс"),
            Transaction(amount: 499,   type: .expense, category: catEntertain,  date: daysAgo(1),  note: "Steam, гра"),
            Transaction(amount: 411,   type: .expense, category: catHealth,     date: daysAgo(1),  note: "Аптека, вітаміни"),
            Transaction(amount: 380,   type: .expense, category: catFood,       date: daysAgo(2),  note: "АТБ, вечеря"),
            Transaction(amount: 560,   type: .expense, category: catFood,       date: daysAgo(3),  note: "Varus, овочі та фрукти"),
            Transaction(amount: 2400,  type: .expense, category: catHome,       date: daysAgo(7),  note: "Комуналка")
        ]
    }()

    // MARK: - Seed accounts

    private lazy var accounts: [Account] = [
        Account(name: "Готівка",          type: .cash,    balance: 8240,  color: "#22c55e", icon: "banknote",  order: 0),
        Account(name: "Картка ПриватБанк", type: .card,   balance: 32000, color: "#3b82f6", icon: "creditcard", order: 1),
        Account(name: "Заощадження",      type: .savings, balance: 18000, color: "#818cf8", icon: "lock.shield", order: 2)
    ]

    // MARK: - Seed budgets (filled after categories are set up)

    private lazy var budgets: [Budget] = [
        Budget(categoryID: catFood.id,      monthlyLimit: 5000),
        Budget(categoryID: catTransport.id, monthlyLimit: 1500),
        Budget(categoryID: catCafe.id,      monthlyLimit: 3000),
        Budget(categoryID: catEntertain.id, monthlyLimit: 2000),
        Budget(categoryID: catHome.id,      monthlyLimit: 4000)
    ]

    // MARK: - Transactions

    func fetchTransactions() async throws -> [Transaction] {
        transactions.sorted { $0.date > $1.date }
    }

    func add(_ transaction: Transaction) async throws {
        transactions.insert(transaction, at: 0)
    }

    func update(_ transaction: Transaction) async throws {
        if let idx = transactions.firstIndex(where: { $0.id == transaction.id }) {
            transactions[idx] = transaction
        }
    }

    func delete(_ transaction: Transaction) async throws {
        transactions.removeAll { $0.id == transaction.id }
    }

    // MARK: - Categories

    func fetchCategories() async throws -> [Category] {
        categories.sorted { $0.order < $1.order }
    }

    func add(_ category: Category) async throws {
        category.order = categories.count
        categories.append(category)
    }

    func update(_ category: Category) async throws {
        if let idx = categories.firstIndex(where: { $0.id == category.id }) {
            categories[idx] = category
        }
    }

    func delete(_ category: Category) async throws {
        categories.removeAll { $0.id == category.id }
    }

    // MARK: - Accounts

    func fetchAccounts() async throws -> [Account] {
        accounts.sorted { $0.order < $1.order }
    }

    func add(_ account: Account) async throws {
        account.order = accounts.count
        accounts.append(account)
    }

    func update(_ account: Account) async throws {
        if let idx = accounts.firstIndex(where: { $0.id == account.id }) {
            accounts[idx] = account
        }
    }

    func delete(_ account: Account) async throws {
        accounts.removeAll { $0.id == account.id }
    }

    // MARK: - Budgets

    func fetchBudgets() async throws -> [Budget] { budgets }

    func add(_ budget: Budget) async throws {
        budgets.append(budget)
    }

    func update(_ budget: Budget) async throws {
        if let idx = budgets.firstIndex(where: { $0.id == budget.id }) {
            budgets[idx] = budget
        }
    }

    func delete(_ budget: Budget) async throws {
        budgets.removeAll { $0.id == budget.id }
    }
}
