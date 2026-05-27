import SwiftUI

struct SettingsView: View {
    @AppStorage("currency") private var currency = "UAH"

    private let userName = "Serhii Zholonko"
    private let userEmail = "serhiizholonko@gmail.com"

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                profileCard
                proBanner
                mainMenu
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(Color.bgPrimary)
        .navigationTitle("Налаштування")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Profile card

    private var profileCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.accentPrimary)
                    .frame(width: 50, height: 50)
                Text(initials)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(userName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Text(userEmail)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.textSecondary)
            }
            Spacer()
        }
        .padding(16)
        .background(Color.bgCard, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
    }

    // MARK: - Pro banner

    private var proBanner: some View {
        NavigationLink(destination: PaywallView()) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("SpendFlow Pro")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Синхронізація, експорт, без реклами")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.8))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(16)
            .background(Color.accentPrimary, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Main menu

    private var mainMenu: some View {
        VStack(spacing: 0) {
            NavigationLink(destination: CategoryEditorView()) {
                menuRow(icon: "tag.fill", iconColor: Color.accentPrimary, title: "Категорії")
            }
            .buttonStyle(.plain)

            menuDivider

            NavigationLink(destination: AccountsView()) {
                menuRow(icon: "creditcard.fill", iconColor: Color(hex: "#22c55e"), title: "Рахунки")
            }
            .buttonStyle(.plain)

            menuDivider

            currencyRow

            menuDivider

            menuRow(icon: "lock.fill", iconColor: Color(hex: "#f59e0b"), title: "Код-пароль", trailing: "Вимк.")
            menuDivider
            menuRow(icon: "icloud.fill", iconColor: Color(hex: "#60a5fa"), title: "iCloud синхронізація", trailing: "Увімк.")
            menuDivider
            menuRow(icon: "square.and.arrow.up.fill", iconColor: Color(hex: "#a3e635"), title: "Експорт даних")
        }
        .background(Color.bgCard, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
    }

    private var menuDivider: some View {
        Divider().padding(.leading, 56)
    }

    private func menuRow(
        icon: String,
        iconColor: Color,
        title: String,
        trailing: String = ""
    ) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(iconColor)
                .frame(width: 36, height: 36)
                .overlay {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                }
            Text(title)
                .font(.system(size: 15))
                .foregroundStyle(Color.textPrimary)
            Spacer()
            if !trailing.isEmpty {
                Text(trailing)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.textSecondary)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.textSecondary.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var currencyRow: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: "#f87171"))
                .frame(width: 36, height: 36)
                .overlay {
                    Image(systemName: "dollarsign")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                }
            Text("Валюти")
                .font(.system(size: 15))
                .foregroundStyle(Color.textPrimary)
            Spacer()
            Text(currency)
                .font(.system(size: 14))
                .foregroundStyle(Color.textSecondary)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.textSecondary.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var initials: String {
        let parts = userName.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last = parts.last?.prefix(1) ?? ""
        return "\(first)\(last)"
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .injectMockStore()
}
