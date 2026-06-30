import SwiftUI
import SwiftData

@main
struct FlowCashApp: App {
    static let modelContainer: ModelContainer = makeContainer()

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasSeedCompleted") private var hasSeedCompleted = false

    @State private var lock = AppLockManager()
    @State private var accountSelection = AccountSelection()
    @State private var deepLink = DeepLinkRouter()
    @State private var localization = LocalizationManager.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    AppRootView()
                        .task { await bootstrap() }
                } else {
                    OnboardingView()
                }
            }
            .environment(lock)
            .environment(accountSelection)
            .environment(deepLink)
            .environment(localization)
            .onOpenURL { deepLink.handle($0) }
            .overlay {
                if lock.isLocked {
                    LockScreenView(onUnlock: { await lock.unlock() })
                }
            }
            .environment(\.locale, localization.locale)
            .id(localization.language)
        }
        .modelContainer(Self.modelContainer)
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { lock.lockIfNeeded() }
        }
    }

    // MARK: - Container

    private static func makeContainer() -> ModelContainer {
        let schema = Schema([Transaction.self, Category.self, Account.self, Budget.self])

        // Користувацький перемикач синхронізації (Налаштування). За замовчуванням — увімкнено.
        // Контейнер фіксується на старті, тож зміна перемикача діє лише після перезапуску.
        let syncEnabled = UserDefaults.standard.object(forKey: "iCloudSyncEnabled") as? Bool ?? true

        if syncEnabled {
            let cloudConfig = ModelConfiguration(
                schema: schema,
                cloudKitDatabase: .private("iCloud.com.zholonko.www.ToDoList.FlowCash")
            )
            if let container = try? ModelContainer(for: schema, configurations: cloudConfig) {
                return container
            }
            print("⚠️ CloudKit unavailable, falling back to local store")
        }

        return makeLocalContainer(schema: schema)
    }

    /// Локальне сховище без CloudKit — fallback або коли синхронізацію вимкнено користувачем.
    private static func makeLocalContainer(schema: Schema) -> ModelContainer {
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

    // MARK: - Bootstrap

    @MainActor
    private func bootstrap() async {
        await seedIfNeeded()
        Self.deduplicate()
        Self.migrateOrphanTransactions()
        await observeRemoteChanges()
    }

    /// Транзакції, створені до прив'язки до рахунків (account == nil),
    /// прив'язуємо до першого рахунку — інакше вони не показуються в жодному.
    @MainActor
    static func migrateOrphanTransactions() {
        let context = modelContainer.mainContext
        let accountDescriptor = FetchDescriptor<Account>(sortBy: [SortDescriptor(\.order)])
        guard let firstAccount = try? context.fetch(accountDescriptor).first else { return }
        guard let transactions = try? context.fetch(FetchDescriptor<Transaction>()) else { return }

        var changed = false
        for transaction in transactions where transaction.account == nil {
            transaction.account = firstAccount
            changed = true
        }
        if changed { try? context.save() }
    }

    /// CloudKit може доставити дублі вже після старту — переганяємо дедуп
    /// на кожну віддалену зміну сховища. Якщо дублів немає, виклик no-op.
    @MainActor
    private func observeRemoteChanges() async {
        let changes = NotificationCenter.default.notifications(
            named: Notification.Name("NSPersistentStoreRemoteChangeNotification")
        )
        for await _ in changes {
            Self.deduplicate()
        }
    }

    // MARK: - Deduplication

    /// Прибирає дублі категорій/рахунків, що виникають через гонку seed на
    /// кількох пристроях (CloudKit зливає незалежно засіяні набори).
    @MainActor
    static func deduplicate() {
        let context = modelContainer.mainContext
        deduplicateCategories(in: context)
        deduplicateAccounts(in: context)
        if context.hasChanges {
            try? context.save()
        }
    }

    @MainActor
    private static func deduplicateCategories(in context: ModelContext) {
        guard let categories = try? context.fetch(FetchDescriptor<Category>()) else { return }
        // Натуральний ключ: тип + назва. Переможець — найменший id (детерміновано
        // на всіх пристроях), тож усі сходяться до того самого запису.
        let groups = Dictionary(grouping: categories) { "\($0.typeValue)|\($0.name)" }
        for group in groups.values where group.count > 1 {
            let sorted = group.sorted { $0.id.uuidString < $1.id.uuidString }
            guard let keeper = sorted.first else { continue }
            for duplicate in sorted.dropFirst() {
                for transaction in duplicate.transactions ?? [] {
                    transaction.category = keeper
                }
                context.delete(duplicate)
            }
        }
    }

    @MainActor
    private static func deduplicateAccounts(in context: ModelContext) {
        guard let accounts = try? context.fetch(FetchDescriptor<Account>()) else { return }
        let groups = Dictionary(grouping: accounts) { $0.name }
        for group in groups.values where group.count > 1 {
            let sorted = group.sorted { $0.id.uuidString < $1.id.uuidString }
            for duplicate in sorted.dropFirst() {
                context.delete(duplicate)
            }
        }
    }

    // MARK: - Seed

    @MainActor
    private func seedIfNeeded() async {
        guard !hasSeedCompleted else { return }
        let context = Self.modelContainer.mainContext

        let categoriesExist = ((try? context.fetchCount(FetchDescriptor<Category>())) ?? 0) > 0
        let accountsExist = ((try? context.fetchCount(FetchDescriptor<Account>())) ?? 0) > 0

        // Дані вже є (локально чи з CloudKit) — це існуючий користувач.
        // Нічого не сіємо, лише фіксуємо, що seed більше не потрібен. Інакше
        // після видалення всіх рахунків заглушки повертались би на кожен запуск.
        guard !categoriesExist && !accountsExist else {
            hasSeedCompleted = true
            return
        }

        seedDefaultCategories(into: context)
        seedDefaultAccounts(into: context)
        try? context.save()
        hasSeedCompleted = true
    }

    @MainActor
    private func seedDefaultCategories(into context: ModelContext) {
        for category in Category.defaultCategories() {
            context.insert(category)
        }
    }

    @MainActor
    private func seedDefaultAccounts(into context: ModelContext) {
        let accounts: [(String, AccountType, Double, String, String, Int)] = [
            ("Готівка",           .cash,    8240,  "#22c55e", "banknote",   0),
            ("Картка ПриватБанк", .card,    32000, "#3b82f6", "creditcard", 1),
            ("Заощадження",       .savings, 18000, "#818cf8", "lock.shield", 2)
        ]
        // Назви рахунків локалізуються за поточною мовою на момент сіду.
        for (name, type, balance, color, icon, order) in accounts {
            let localizedName = L(name)
            context.insert(Account(name: localizedName, type: type, balance: balance, color: color, icon: icon, order: order))
        }
    }
}


