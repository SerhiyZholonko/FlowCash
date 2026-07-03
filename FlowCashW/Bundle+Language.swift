import Foundation

// ВАЖЛИВО: ідентична копія у застосунку (FlowCash/Core/Localization/Bundle+Language.swift).

private var bundleAssociationKey: UInt8 = 0

/// Підклас Bundle, що перенаправляє пошук локалізованих рядків у вибрану `.lproj`.
private final class LocalizedBundle: Bundle, @unchecked Sendable {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        if let bundle = objc_getAssociatedObject(self, &bundleAssociationKey) as? Bundle {
            return bundle.localizedString(forKey: key, value: value, table: tableName)
        }
        // Для обраної мови немає `.lproj` (це source-мова `uk`, ключі вже українські).
        // Повертаємо сам ключ, а НЕ `super` — інакше система резолвить рядок за
        // глобальною мовою телефону й бере чужий переклад із її `.lproj`.
        if let value, !value.isEmpty { return value }
        return key
    }
}

extension Bundle {
    /// Переключає мову на рівні `Bundle.main`, тож усі `Text("…")` беруть рядки з обраної `.lproj`.
    static func setLanguage(_ code: String) {
        object_setClass(Bundle.main, LocalizedBundle.self)
        let lprojPath = Bundle.main.path(forResource: code, ofType: "lproj")
        let languageBundle = lprojPath.flatMap { Bundle(path: $0) }
        objc_setAssociatedObject(
            Bundle.main,
            &bundleAssociationKey,
            languageBundle,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
    }
}
