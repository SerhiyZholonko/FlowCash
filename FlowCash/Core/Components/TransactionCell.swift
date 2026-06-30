import SwiftUI

struct TransactionCell: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            categoryIcon
            VStack(alignment: .leading, spacing: 3) {
                Text(transaction.category?.name ?? L("Без категорії"))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                if !transaction.note.isEmpty {
                    Text(transaction.note)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.textSecondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(amountFormatted)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(transaction.type == .income ? Color.incomeGreen : Color.expenseRed)
                Text(transaction.date, style: .date)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .padding(12)
        .background(Color.bgCard, in: RoundedRectangle(cornerRadius: 12))
    }

    private var categoryIcon: some View {
        Circle()
            .fill(categoryColor)
            .frame(width: 44, height: 44)
            .overlay {
                if let icon = transaction.category?.icon, !icon.isEmpty {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
    }

    private var categoryColor: Color {
        if let hex = transaction.category?.color {
            return Color(hex: hex)
        }
        return Color.textSecondary.opacity(0.3)
    }

    private var amountFormatted: String {
        let sign = transaction.type == .income ? "+" : "-"
        return "\(sign)\(transaction.amount.formatted(.number.precision(.fractionLength(0))))"
    }
}
