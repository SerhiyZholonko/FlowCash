import Foundation

/// Підтримувані мови інтерфейсу. `rawValue` зберігається в UserDefaults.
enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case ukrainian
    case english
    case german
    case spanish
    case italian
    case malay
    case portugueseBrazil
    case chineseSimplified
    case turkish
    case polish
    case croatian
    case norwegianBokmal
    case french

    var id: String { rawValue }

    /// Код теки локалізації (`uk.lproj` / `en.lproj` / `pt-BR.lproj` / `zh-Hans.lproj` …).
    var code: String {
        switch self {
        case .ukrainian: "uk"
        case .english: "en"
        case .german: "de"
        case .spanish: "es"
        case .italian: "it"
        case .malay: "ms"
        case .portugueseBrazil: "pt-BR"
        case .chineseSimplified: "zh-Hans"
        case .turkish: "tr"
        case .polish: "pl"
        case .croatian: "hr"
        case .norwegianBokmal: "nb"
        case .french: "fr"
        }
    }

    /// Локаль для форматування дат і чисел.
    var locale: Locale {
        switch self {
        case .ukrainian: Locale(identifier: "uk_UA")
        case .english: Locale(identifier: "en_US")
        case .german: Locale(identifier: "de_DE")
        case .spanish: Locale(identifier: "es_ES")
        case .italian: Locale(identifier: "it_IT")
        case .malay: Locale(identifier: "ms_MY")
        case .portugueseBrazil: Locale(identifier: "pt_BR")
        case .chineseSimplified: Locale(identifier: "zh_Hans")
        case .turkish: Locale(identifier: "tr_TR")
        case .polish: Locale(identifier: "pl_PL")
        case .croatian: Locale(identifier: "hr_HR")
        case .norwegianBokmal: Locale(identifier: "nb_NO")
        case .french: Locale(identifier: "fr_FR")
        }
    }

    /// Назва мови її ж мовою — для перемикача в Налаштуваннях.
    var displayName: String {
        switch self {
        case .ukrainian: "Українська"
        case .english: "English"
        case .german: "Deutsch"
        case .spanish: "Español"
        case .italian: "Italiano"
        case .malay: "Bahasa Melayu"
        case .portugueseBrazil: "Português"
        case .chineseSimplified: "简体中文"
        case .turkish: "Türkçe"
        case .polish: "Polski"
        case .croatian: "Hrvatski"
        case .norwegianBokmal: "Norsk Bokmål"
        case .french: "Français"
        }
    }

    /// Мова за замовчуванням при першому запуску — за мовою системи.
    /// Зіставляє системний код (`Locale.preferredLanguages`) з відповідним `code`
    /// (спершу повний збіг `pt-BR`/`zh-Hans`, потім за дволітерним префіксом).
    static var systemDefault: AppLanguage {
        let preferred = Locale.preferredLanguages.first ?? "uk"
        let normalized = preferred.replacingOccurrences(of: "_", with: "-").lowercased()
        // Повний збіг із кодом (для `pt-BR`, `zh-Hans` тощо).
        if let exact = allCases.first(where: { normalized.hasPrefix($0.code.lowercased()) }) {
            return exact
        }
        // Збіг за мовним префіксом (`de-AT` → `de`, `zh-Hant` → `zh-Hans`).
        let prefix = String(normalized.prefix(2))
        if let byPrefix = allCases.first(where: { $0.code.lowercased().hasPrefix(prefix) }) {
            return byPrefix
        }
        return .ukrainian
    }
}
