import SwiftUI
import SwiftData

@main
struct FlowCashApp: App {
    static let modelContainer: ModelContainer = makeContainer()

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                AppRootView()
                    .task { await seedCategoriesIfNeeded() }
            } else {
                OnboardingView()
            }
        }
        .modelContainer(Self.modelContainer)
    }

    // MARK: - Container

    private static func makeContainer() -> ModelContainer {
        let schema = Schema([Transaction.self, Category.self, Account.self, Budget.self])

        let cloudConfig = ModelConfiguration(
            schema: schema,
            cloudKitDatabase: .private("iCloud.com.zholonko.www.ToDoList.FlowCash")
        )
        if let container = try? ModelContainer(for: schema, configurations: cloudConfig) {
            return container
        }

        print("⚠️ CloudKit unavailable, falling back to local store")
        let storeURL = URL.applicationSupportDirectory.appending(path: "SpendFlow.store")
        let localConfig = ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .none)
        do {
            return try ModelContainer(for: schema, configurations: localConfig)
        } catch {
            try? FileManager.default.removeItem(at: storeURL)
            let freshConfig = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
            return try! ModelContainer(for: schema, configurations: freshConfig)
        }
    }

    // MARK: - Seed

    @MainActor
    private func seedCategoriesIfNeeded() async {
        let context = Self.modelContainer.mainContext
        let catDescriptor = FetchDescriptor<Category>()
        guard let catCount = try? context.fetchCount(catDescriptor), catCount == 0 else {
            await seedAccountsIfNeeded()
            return
        }

        let expenseCategories: [(String, String, String, Int)] = [
            ("Їжа",       "fork.knife",                        "#f87171", 0),
            ("Кафе",      "cup.and.saucer",                    "#fb923c", 1),
            ("Транспорт", "tram",                              "#fbbf24", 2),
            ("Розваги",   "gamecontroller",                    "#c084fc", 3),
            ("Здоров'я",  "heart",                             "#f472b6", 4),
            ("Дім",       "house",                             "#2dd4bf", 5),
            ("Одяг",      "tshirt",                            "#818cf8", 6),
            ("Освіта",    "graduationcap",                     "#60a5fa", 7),
            ("Подарунки", "gift",                              "#fb7185", 8),
            ("Подорожі",  "airplane",                          "#34d399", 9),
            ("Зв'язок",   "antenna.radiowaves.left.and.right", "#22d3ee", 10),
            ("Краса",     "sparkles",                          "#e879f9", 11),
            ("Спорт",     "figure.run",                        "#a3e635", 12),
            ("Рахунки",   "doc.text",                          "#94a3b8", 13),
            ("Інше",      "ellipsis.circle",                   "#cbd5e1", 14)
        ]
        for (name, icon, color, order) in expenseCategories {
            context.insert(Category(name: name, icon: icon, color: color, type: .expense, order: order))
        }

        let incomeCategories: [(String, String, String, Int)] = [
            ("Зарплата",  "banknote",        "#22c55e", 15),
            ("Фріланс",   "laptopcomputer",  "#3b82f6", 16),
            ("Подарунок", "gift.fill",       "#fb7185", 17),
            ("Оренда",    "house.fill",      "#2dd4bf", 18),
            ("Стипендія", "graduationcap",   "#60a5fa", 19),
            ("Продаж",    "cart",            "#fb923c", 20),
            ("Інше",      "ellipsis.circle", "#cbd5e1", 21)
        ]
        for (name, icon, color, order) in incomeCategories {
            context.insert(Category(name: name, icon: icon, color: color, type: .income, order: order))
        }

        try? context.save()
        await seedAccountsIfNeeded()
    }

    @MainActor
    private func seedAccountsIfNeeded() async {
        let context = Self.modelContainer.mainContext
        let descriptor = FetchDescriptor<Account>()
        guard let count = try? context.fetchCount(descriptor), count == 0 else { return }

        let accounts: [(String, AccountType, Double, String, String, Int)] = [
            ("Готівка",           .cash,    8240,  "#22c55e", "banknote",   0),
            ("Картка ПриватБанк", .card,    32000, "#3b82f6", "creditcard", 1),
            ("Заощадження",       .savings, 18000, "#818cf8", "lock.shield", 2)
        ]
        for (name, type, balance, color, icon, order) in accounts {
            context.insert(Account(name: name, type: type, balance: balance, color: color, icon: icon, order: order))
        }
        try? context.save()
    }
}
