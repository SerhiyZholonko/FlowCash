import SwiftUI

struct CurrencyPickerView: View {
    @AppStorage("currency") private var currency = Currency.uah.rawValue

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(Currency.allCases.enumerated()), id: \.element.id) { index, item in
                    Button {
                        currency = item.rawValue
                    } label: {
                        row(item)
                    }
                    .buttonStyle(.plain)

                    if index < Currency.allCases.count - 1 {
                        Divider().padding(.leading, 56)
                    }
                }
            }
            .background(Color.bgCard, in: RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .background(Color.bgPrimary)
        .navigationTitle("Валюта")
        .navigationBarTitleDisplayMode(.large)
    }

    private func row(_ item: Currency) -> some View {
        HStack(spacing: 12) {
            Text(item.symbol)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .frame(width: 36, height: 36)
                .background(Color.bgPrimary, in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.rawValue)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Text(item.displayName)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()

            if item.rawValue == currency {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.accentPrimary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        CurrencyPickerView()
    }
}
