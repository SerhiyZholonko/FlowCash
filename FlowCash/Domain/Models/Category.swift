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
}
