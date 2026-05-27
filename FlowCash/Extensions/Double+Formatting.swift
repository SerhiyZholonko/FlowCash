import Foundation

extension Double {
    var formattedCurrency: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        let number = formatter.string(from: NSNumber(value: self)) ?? "\(Int(self))"
        return "\(number) ₴"
    }

    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: self)) ?? "\(Int(self))"
    }

    var formattedSignedCurrency: String {
        let sign = self >= 0 ? "+" : "-"
        let abs = Swift.abs(self)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.maximumFractionDigits = 0
        let number = formatter.string(from: NSNumber(value: abs)) ?? "\(Int(abs))"
        return "\(sign)₴\(number)"
    }
}
