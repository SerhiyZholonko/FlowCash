import SwiftUI
import WidgetKit

/// Керує мовою інтерфейсу. Зберігає вибір користувача та перемикає мову
/// без перезапуску застосунку (через підміну `Bundle.main`).
@MainActor
@Observable
final class LocalizationManager {
    static let shared = LocalizationManager()

    private let storageKey = "appLanguage"

    private(set) var language: AppLanguage

    /// Локаль для форматерів дат/чисел (`.environment(\.locale, …)`).
    var locale: Locale { language.locale }

    private init() {
        let stored = UserDefaults.standard.string(forKey: storageKey)
        let initial = stored.flatMap(AppLanguage.init(rawValue:)) ?? .systemDefault
        self.language = initial
        Bundle.setLanguage(initial.code)
        shareLanguageWithWidget(initial)
    }

    func setLanguage(_ language: AppLanguage) {
        guard language != self.language else { return }
        self.language = language
        UserDefaults.standard.set(language.rawValue, forKey: storageKey)
        Bundle.setLanguage(language.code)
        shareLanguageWithWidget(language)
    }

    /// Передає код мови у App Group і оновлює віджети, щоб вони рендерилися тією ж мовою.
    private func shareLanguageWithWidget(_ language: AppLanguage) {
        WidgetShared.defaults?.set(language.code, forKey: WidgetShared.languageCodeKey)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
