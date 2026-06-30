import SwiftData
import Foundation

@Model
final class Transaction {
    var id: UUID = UUID()
    var amount: Double = 0
    var typeValue: String = "expense"
    @Relationship(deleteRule: .nullify, inverse: \Category.transactions)
    var category: Category?
    @Relationship(deleteRule: .nullify, inverse: \Account.transactions)
    var account: Account?
    var date: Date = Date()
    var note: String = ""

    var type: TransactionType {
        get { TransactionType(rawValue: typeValue) ?? .expense }
        set { typeValue = newValue.rawValue }
    }

    /// Вплив транзакції на баланс рахунку: дохід додає, витрата віднімає.
    var signedAmount: Double {
        type == .income ? amount : -amount
    }

    init(
        id: UUID = UUID(),
        amount: Double,
        type: TransactionType,
        category: Category? = nil,
        date: Date = .now,
        note: String = ""
    ) {
        self.id = id
        self.amount = amount
        self.typeValue = type.rawValue
        self.category = category
        self.date = date
        self.note = note
    }
}
