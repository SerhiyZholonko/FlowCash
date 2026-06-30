import Foundation

enum Currency: String, CaseIterable, Identifiable {
    case uah = "UAH"
    case usd = "USD"
    case eur = "EUR"
    case pln = "PLN"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .uah: "₴"
        case .usd: "$"
        case .eur: "€"
        case .pln: "zł"
        }
    }

    var displayName: String {
        switch self {
        case .uah: L("Українська гривня")
        case .usd: L("Долар США")
        case .eur: L("Євро")
        case .pln: L("Польський злотий")
        }
    }

    /// Поточна обрана валюта (ключ "currency" у UserDefaults / @AppStorage).
    static var selected: Currency {
        Currency(rawValue: UserDefaults.standard.string(forKey: "currency") ?? "") ?? .uah
    }
}

@MainActor
@Observable
final class OnboardingViewModel {
    var selectedCurrency: Currency = .uah
}
