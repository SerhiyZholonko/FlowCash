import Foundation

enum TransactionType: String, Codable, CaseIterable {
    case income
    case expense

    var title: String {
        switch self {
        case .income: L("Дохід")
        case .expense: L("Витрата")
        }
    }
}
