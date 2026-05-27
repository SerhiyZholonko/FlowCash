import SwiftUI

extension Color {
    // MARK: - Backgrounds
    static let bgPrimary = Color(hex: "#1a1d26")
    static let bgCard = Color(hex: "#252836")

    // MARK: - Text
    static let textPrimary = Color(hex: "#f8fafc")
    static let textSecondary = Color(hex: "#6b7280")

    // MARK: - Accent
    static let accentPrimary = Color(hex: "#3b82f6")

    // MARK: - Border
    static let borderSubtle = Color(hex: "#374151")

    // MARK: - Category colors
    static let categoryFood = Color(hex: "#f87171")
    static let categoryCafe = Color(hex: "#fb923c")
    static let categoryTransport = Color(hex: "#fbbf24")
    static let categoryEntertainment = Color(hex: "#c084fc")
    static let categoryHealth = Color(hex: "#f472b6")
    static let categoryHome = Color(hex: "#2dd4bf")
    static let categoryClothes = Color(hex: "#818cf8")
    static let categoryEducation = Color(hex: "#60a5fa")
    static let categoryGifts = Color(hex: "#fb7185")
    static let categoryTravel = Color(hex: "#34d399")
    static let categoryCommunication = Color(hex: "#22d3ee")
    static let categoryBeauty = Color(hex: "#e879f9")
    static let categorySport = Color(hex: "#a3e635")
    static let categoryBills = Color(hex: "#94a3b8")
    static let categoryOther = Color(hex: "#cbd5e1")

    // MARK: - Semantic
    static let incomeGreen = Color(hex: "#22c55e")
    static let expenseRed = Color(hex: "#ef4444")

    // MARK: - Init from hex
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b, a: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8) & 0xFF) / 255
            b = Double(int & 0xFF) / 255
            a = 1
        case 8:
            r = Double((int >> 24) & 0xFF) / 255
            g = Double((int >> 16) & 0xFF) / 255
            b = Double((int >> 8) & 0xFF) / 255
            a = Double(int & 0xFF) / 255
        default:
            r = 1; g = 1; b = 1; a = 1
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

extension Color {
    static func category(hex: String) -> Color {
        Color(hex: hex)
    }
}
