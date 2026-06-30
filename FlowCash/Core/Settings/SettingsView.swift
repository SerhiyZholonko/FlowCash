import SwiftUI

struct SettingsView: View {
    @AppStorage("currency") private var currency = "UAH"
    @AppStorage("iCloudSyncEnabled") private var iCloudSyncEnabled = true
    @Environment(AppLockManager.self) private var lock
    @Environment(AccountSelection.self) private var accountSelection
    @Environment(LocalizationManager.self) private var localization
    @State private var viewModel = SettingsViewModel()
    @State private var showRestartNotice = false
    @State private var showDeleteConfirm = false

    private var selectedAccount: Account? {
        accountSelection.resolve(in: viewModel.accounts)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
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
        .onAppear { viewModel.load() }
        .sheet(item: $viewModel.exportFile) { file in
            ShareSheet(items: [file.url])
        }
        .alert("Помилка", isPresented: Binding(
            get: { viewModel.error != nil },
            set: { _ in viewModel.error = nil }
        )) {
            Button("OK") { viewModel.error = nil }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "")
        }
        .confirmationDialog(
            "Видалити всі дані?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Видалити все", role: .destructive) {
                viewModel.deleteAllICloudData()
            }
            Button("Скасувати", role: .cancel) {}
        } message: {
            Text("Усі транзакції та рахунки буде видалено, зокрема з iCloud. Категорії скинуться до дефолтних.")
        }
        .alert("Перезапустіть застосунок", isPresented: Binding(
            get: { showRestartNotice || viewModel.didDeleteAllData },
            set: { _ in
                showRestartNotice = false
                viewModel.didDeleteAllData = false
            }
        )) {
            Button("OK") {
                showRestartNotice = false
                viewModel.didDeleteAllData = false
            }
        } message: {
            Text("Зміни наберуть чинності після перезапуску застосунку.")
        }
    }

    // MARK: - Pro banner

    private var proBanner: some View {
        // SpendFlow Pro тимчасово вимкнено — функція ще не готова.
        EmptyView()
//        NavigationLink(destination: PaywallView()) {
//            HStack(spacing: 12) {
//                VStack(alignment: .leading, spacing: 2) {
//                    Text("SpendFlow Pro")
//                        .font(.system(size: 15, weight: .bold))
//                        .foregroundStyle(.white)
//                    Text("Синхронізація, експорт, без реклами")
//                        .font(.system(size: 12))
//                        .foregroundStyle(.white.opacity(0.8))
//                }
//                Spacer()
//                Image(systemName: "chevron.right")
//                    .font(.system(size: 13, weight: .semibold))
//                    .foregroundStyle(.white.opacity(0.7))
//            }
//            .padding(16)
//            .background(Color.accentPrimary, in: RoundedRectangle(cornerRadius: 14))
//        }
//        .buttonStyle(.plain)
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

            activeAccountRow

            menuDivider

            NavigationLink(destination: CurrencyPickerView()) {
                currencyRow
            }
            .buttonStyle(.plain)

            menuDivider

            languageRow

            menuDivider

            faceIDRow
            menuDivider
            iCloudRow
            menuDivider
            Button {
                viewModel.exportCSV()
            } label: {
                menuRow(icon: "square.and.arrow.up.fill", iconColor: Color(hex: "#a3e635"), title: "Експорт даних")
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.hasData)
            .opacity(viewModel.hasData ? 1 : 0.4)

            #if DEBUG
            menuDivider
            Button {
                showDeleteConfirm = true
            } label: {
                menuRow(icon: "trash.fill", iconColor: Color(hex: "#ef4444"), title: "Видалити всі дані (Debug)")
            }
            .buttonStyle(.plain)
            #endif
        }
        .background(Color.bgCard, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
    }

    private var menuDivider: some View {
        Divider().padding(.leading, 56)
    }

    // MARK: - Active account row

    private var activeAccountRow: some View {
        Menu {
            ForEach(viewModel.accounts, id: \.id) { account in
                Button {
                    accountSelection.selectedId = account.id
                } label: {
                    if selectedAccount?.id == account.id {
                        Label(account.name, systemImage: "checkmark")
                    } else {
                        Text(account.name)
                    }
                }
            }
        } label: {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: selectedAccount?.color ?? "#3b82f6"))
                    .frame(width: 36, height: 36)
                    .overlay {
                        Image(systemName: selectedAccount?.icon ?? "creditcard.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                Text("Активний рахунок")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text(selectedAccount?.name ?? "—")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.textSecondary)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.textSecondary.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .disabled(viewModel.accounts.isEmpty)
    }

    // MARK: - Language row

    private var languageRow: some View {
        Menu {
            ForEach(AppLanguage.allCases) { language in
                Button {
                    localization.setLanguage(language)
                } label: {
                    if localization.language == language {
                        Label(language.displayName, systemImage: "checkmark")
                    } else {
                        Text(language.displayName)
                    }
                }
            }
        } label: {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: "#8b5cf6"))
                    .frame(width: 36, height: 36)
                    .overlay {
                        Image(systemName: "globe")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                Text("Мова")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text(localization.language.displayName)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.textSecondary)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.textSecondary.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Face ID row

    private var faceIDRow: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: "#f59e0b"))
                .frame(width: 36, height: 36)
                .overlay {
                    Image(systemName: "faceid")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                }
            Text("Face ID")
                .font(.system(size: 15))
                .foregroundStyle(Color.textPrimary)
            Spacer()
            Toggle("", isOn: Binding(
                get: { lock.isEnabled },
                set: { newValue in
                    if newValue {
                        Task { await lock.enableLock() }
                    } else {
                        lock.disableLock()
                    }
                }
            ))
            .labelsHidden()
            .tint(Color.accentPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - iCloud status row

    private var iCloudRow: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: "#60a5fa"))
                .frame(width: 36, height: 36)
                .overlay {
                    Image(systemName: "icloud.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                }
            Text("iCloud синхронізація")
                .font(.system(size: 15))
                .foregroundStyle(Color.textPrimary)
            Spacer()
            Toggle("", isOn: Binding(
                get: { iCloudSyncEnabled },
                set: { newValue in
                    iCloudSyncEnabled = newValue
                    showRestartNotice = true
                }
            ))
            .labelsHidden()
            .tint(Color.accentPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func menuRow(
        icon: String,
        iconColor: Color,
        title: LocalizedStringKey,
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
        .contentShape(Rectangle())
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
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environment(AppLockManager())
    .environment(AccountSelection())
    .environment(LocalizationManager.shared)
    .injectMockStore()
}
