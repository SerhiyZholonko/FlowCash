import Foundation

enum Currency: String, CaseIterable {
    case uah = "UAH"
    case usd = "USD"
    case eur = "EUR"
    case pln = "PLN"

    var symbol: String {
        switch self {
        case .uah: "₴"
        case .usd: "$"
        case .eur: "€"
        case .pln: "zł"
        }
    }
}

@MainActor
@Observable
final class OnboardingViewModel {
    var selectedCurrency: Currency = .uah
}
