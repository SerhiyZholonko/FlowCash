import Foundation

/// Локалізований рядок з урахуванням обраної В ЗАСТОСУНКУ мови.
///
/// Іде через `Bundle.main.localizedString(forKey:…)`, який підмінено у
/// `Bundle.setLanguage(_:)`. На відміну від `String(localized:)`, що резолвиться
/// через системні `AppleLanguages` й ігнорує внутрішній перемикач мови.
func L(_ key: String) -> String {
    Bundle.main.localizedString(forKey: key, value: key, table: nil)
}

/// Локалізований формат із аргументами (напр. `L("Доступно: %@", value)`).
func L(_ key: String, _ args: CVarArg...) -> String {
    let format = Bundle.main.localizedString(forKey: key, value: key, table: nil)
    return String(format: format, locale: LocalizationManager.shared.locale, arguments: args)
}
