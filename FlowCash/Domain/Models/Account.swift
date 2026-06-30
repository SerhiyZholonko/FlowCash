import SwiftData
import Foundation

@Model
final class Account {
    var id: UUID = UUID()
    var name: String = ""
    var typeValue: String = "cash"
    var balance: Double = 0
    var color: String = ""
    var icon: String = ""
    var order: Int = 0
    @Relationship(deleteRule: .cascade)
    var transactions: [Transaction]?

    var type: AccountType {
        get { AccountType(rawValue: typeValue) ?? .cash }
        set { typeValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String,
        type: AccountType,
        balance: Double = 0,
        color: String,
        icon: String,
        order: Int = 0
    ) {
        self.id = id
        self.name = name
        self.typeValue = type.rawValue
        self.balance = balance
        self.color = color
        self.icon = icon
        self.order = order
    }
}
