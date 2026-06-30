import Foundation

enum AccountType: String, Codable, CaseIterable {
    case cash
    case card
    case savings

    var title: String {
        switch self {
        case .cash: L("Готівка")
        case .card: L("Картка")
        case .savings: L("Заощадження")
        }
    }

    var icon: String {
        switch self {
        case .cash: "banknote"
        case .card: "creditcard"
        case .savings: "lock.shield"
        }
    }
}
