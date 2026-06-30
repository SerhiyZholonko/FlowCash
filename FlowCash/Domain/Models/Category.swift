import SwiftData
import Foundation

@Model
final class Category {
    var id: UUID = UUID()
    var name: String = ""
    var icon: String = ""
    var color: String = ""
    var typeValue: String = "expense"
    var order: Int = 0
    var isHidden: Bool = false
    @Relationship(deleteRule: .nullify)
    var transactions: [Transaction]?

    var type: TransactionType {
        get { TransactionType(rawValue: typeValue) ?? .expense }
        set { typeValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "",
        color: String,
        type: TransactionType = .expense,
        order: Int = 0,
        isHidden: Bool = false
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.typeValue = type.rawValue
        self.order = order
        self.isHidden = isHidden
    }

    /// Дефолтний набір категорій — єдине джерело для seed при першому запуску
    /// та для відновлення після Debug-очищення даних.
    static func defaultCategories() -> [Category] {
        let expense: [(String, String, String, Int)] = [
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
        let income: [(String, String, String, Int)] = [
            ("Зарплата",  "banknote",        "#22c55e", 15),
            ("Фріланс",   "laptopcomputer",  "#3b82f6", 16),
            ("Подарунок", "gift.fill",       "#fb7185", 17),
            ("Оренда",    "house.fill",      "#2dd4bf", 18),
            ("Стипендія", "graduationcap",   "#60a5fa", 19),
            ("Продаж",    "cart",            "#fb923c", 20),
            ("Інше",      "ellipsis.circle", "#cbd5e1", 21)
        ]
        // Назви локалізуються за поточною мовою на момент сіду (перший запуск).
        func localized(_ key: String) -> String { L(key) }
        return expense.map { Category(name: localized($0.0), icon: $0.1, color: $0.2, type: .expense, order: $0.3) }
             + income.map  { Category(name: localized($0.0), icon: $0.1, color: $0.2, type: .income,  order: $0.3) }
    }
}
