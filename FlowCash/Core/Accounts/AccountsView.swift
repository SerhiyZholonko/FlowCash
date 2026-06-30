import SwiftUI

struct AccountsView: View {
    @State private var viewModel = AccountsViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                totalBalanceCard
                accountsList
                transferButton
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .background(Color.bgPrimary)
        .navigationTitle("Рахунки")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.presentNewAccount()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.accentPrimary)
                }
            }
        }
        .onAppear { viewModel.loadData() }
        .sheet(isPresented: $viewModel.isShowingEditor) { editorSheet }
        .sheet(isPresented: $viewModel.isShowingTransfer) { transferSheet }
        .alert("Помилка", isPresented: Binding(
            get: { viewModel.error != nil },
            set: { _ in viewModel.error = nil }
        )) {
            Button("OK") { viewModel.error = nil }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "")
        }
    }

    // MARK: - Total balance card

    private var totalBalanceCard: some View {
        VStack(spacing: 4) {
            Text("ЗАГАЛЬНИЙ БАЛАНС")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.textSecondary)
                .tracking(0.5)
            Text(viewModel.totalBalance.formattedCurrency)
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(Color.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.bgCard, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    // MARK: - Accounts list

    private var accountsList: some View {
        VStack(spacing: 12) {
            if viewModel.accounts.isEmpty {
                emptyState
            } else {
                ForEach(viewModel.accounts, id: \.id) { account in
                    Button {
                        viewModel.presentEdit(account)
                    } label: {
                        accountCard(account)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button { viewModel.presentEdit(account) } label: {
                            Label("Редагувати", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            viewModel.deleteAccount(account)
                        } label: {
                            Label("Видалити", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        Text("Ще немає рахунків.\nДодайте перший кнопкою «+».")
            .font(.system(size: 14))
            .foregroundStyle(Color.textSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .background(Color.bgCard, in: RoundedRectangle(cornerRadius: 14))
    }

    private func accountCard(_ account: Account) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: account.icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                Text(account.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                Spacer()
                Text(account.type.title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
            }
            Text(account.balance.formattedCurrency)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white)
        }
        .padding(20)
        .background(Color(hex: account.color), in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color(hex: account.color).opacity(0.3), radius: 8, y: 4)
    }

    // MARK: - Transfer button

    private var transferButton: some View {
        Button {
            viewModel.presentTransfer()
        } label: {
            Text("Переказ між рахунками")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.bgCard, in: RoundedRectangle(cornerRadius: 14))
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(viewModel.accounts.count < 2)
        .opacity(viewModel.accounts.count < 2 ? 0.4 : 1)
    }

    // MARK: - Editor sheet

    private var editorSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    fieldLabel("Назва")
                    TextField("Напр. Готівка", text: $viewModel.draftName)
                        .font(.system(size: 16))
                        .foregroundStyle(Color.textPrimary)
                        .padding(16)
                        .background(Color.bgCard, in: RoundedRectangle(cornerRadius: 12))

                    fieldLabel("Тип")
                    Picker("Тип", selection: $viewModel.draftType) {
                        ForEach(AccountType.allCases, id: \.self) { type in
                            Text(type.title).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)

                    fieldLabel("Баланс")
                    TextField("0", text: $viewModel.draftBalance)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 16))
                        .foregroundStyle(Color.textPrimary)
                        .padding(16)
                        .background(Color.bgCard, in: RoundedRectangle(cornerRadius: 12))

                    fieldLabel("Колір")
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                        ForEach(viewModel.colorSwatches, id: \.self) { hex in
                            Button {
                                viewModel.draftColor = hex
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 44, height: 44)
                                    .overlay {
                                        if viewModel.draftColor == hex {
                                            Circle().stroke(Color.textPrimary, lineWidth: 2.5)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.bgPrimary)
            .navigationTitle(viewModel.editingAccount == nil ? L("Новий рахунок") : L("Редагувати рахунок"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Скасувати") { viewModel.isShowingEditor = false }
                        .foregroundStyle(Color.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Зберегти") { viewModel.saveAccount() }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.accentPrimary)
                        .disabled(!viewModel.isEditorValid)
                }
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - Transfer sheet

    private var transferSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                fieldLabel("Звідки")
                accountPicker(selection: $viewModel.transferFromId)

                fieldLabel("Куди")
                accountPicker(selection: $viewModel.transferToId)

                fieldLabel("Сума")
                TextField("0", text: $viewModel.transferAmount)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.textPrimary)
                    .padding(16)
                    .background(Color.bgCard, in: RoundedRectangle(cornerRadius: 12))

                if let from = viewModel.transferFrom {
                    Text("Доступно: \(from.balance.formattedCurrency)")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.textSecondary)
                }

                Spacer()

                Button {
                    viewModel.transfer()
                } label: {
                    Text("Переказати")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            viewModel.isTransferValid ? Color.accentPrimary : Color.borderSubtle,
                            in: Capsule()
                        )
                }
                .disabled(!viewModel.isTransferValid)
            }
            .padding(20)
            .background(Color.bgPrimary)
            .navigationTitle("Переказ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Скасувати") { viewModel.isShowingTransfer = false }
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func accountPicker(selection: Binding<UUID?>) -> some View {
        Picker("", selection: selection) {
            ForEach(viewModel.accounts, id: \.id) { account in
                Text(account.name).tag(account.id as UUID?)
            }
        }
        .pickerStyle(.menu)
        .tint(Color.textPrimary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.bgCard, in: RoundedRectangle(cornerRadius: 12))
    }

    private func fieldLabel(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color.textSecondary)
    }
}

#Preview {
    NavigationStack {
        AccountsView()
    }
    .injectMockStore()
}
