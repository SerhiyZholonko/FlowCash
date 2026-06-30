import Foundation

private var bundleAssociationKey: UInt8 = 0

/// Підклас Bundle, що перенаправляє пошук локалізованих рядків у вибрану `.lproj`.
private final class LocalizedBundle: Bundle, @unchecked Sendable {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        guard let bundle = objc_getAssociatedObject(self, &bundleAssociationKey) as? Bundle else {
            return super.localizedString(forKey: key, value: value, table: tableName)
        }
        return bundle.localizedString(forKey: key, value: value, table: tableName)
    }
}

extension Bundle {
    /// Перемикає мову застосунку без перезапуску: підміняє клас `Bundle.main`,
    /// тож усі `Text("…")` і `String(localized:)` беруть рядки з обраної `.lproj`.
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
