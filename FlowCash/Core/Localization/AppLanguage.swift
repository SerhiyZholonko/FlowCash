import Foundation

/// Підтримувані мови інтерфейсу. `rawValue` зберігається в UserDefaults.
enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case ukrainian
    case english

    var id: String { rawValue }

    /// Код теки локалізації (`uk.lproj` / `en.lproj`).
    var code: String {
        switch self {
        case .ukrainian: "uk"
        case .english: "en"
        }
    }

    /// Локаль для форматування дат і чисел.
    var locale: Locale {
        switch self {
        case .ukrainian: Locale(identifier: "uk_UA")
        case .english: Locale(identifier: "en_US")
        }
    }

    /// Назва мови її ж мовою — для перемикача в Налаштуваннях.
    var displayName: String {
        switch self {
        case .ukrainian: "Українська"
        case .english: "English"
        }
    }

    /// Мова за замовчуванням при першому запуску — за мовою системи.
    static var systemDefault: AppLanguage {
        let preferred = Locale.preferredLanguages.first ?? "uk"
        return preferred.hasPrefix("en") ? .english : .ukrainian
    }
}
