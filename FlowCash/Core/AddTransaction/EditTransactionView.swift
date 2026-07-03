import SwiftUI

struct EditTransactionView: View {
    @State private var viewModel: EditTransactionViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirm = false
    var onSaved: () -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

    init(transaction: Transaction, onSaved: @escaping () -> Void) {
        _viewModel = State(initialValue: EditTransactionViewModel(transaction: transaction))
        self.onSaved = onSaved
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    amountCard
                    typeCard
                    accountCard
                    categoryCard
                    detailsCard
                    deleteButton
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(Color.bgPrimary)
            .navigationTitle("Редагування")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Скасувати") { dismiss() }
                        .font(.system(size: 16))
                        .foregroundStyle(Color.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Image(systemName: "trash")
                    }
                    .tint(Color.expenseRed)
                    .confirmationDialog(
                        "Видалити транзакцію?",
                        isPresented: $showDeleteConfirm,
                        titleVisibility: .visible
                    ) {
                        Button("Видалити", role: .destructive) { performDelete() }
                        Button("Скасувати", role: .cancel) {}
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Зберегти") {
                        Task { [weak viewModel] in
                            guard let viewModel, viewModel.isValid else { return }
                            try? await viewModel.save()
                            onSaved()
                            dismiss()
                        }
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(viewModel.isValid ? Color.accentPrimary : Color.textSecondary)
                    .disabled(!viewModel.isValid)
                }
            }
            .onAppear {
                viewModel.loadCategories()
                viewModel.loadAccounts()
            }
            .onChange(of: viewModel.selectedType) { _, _ in
                viewModel.typeChanged()
            }
            .sheet(isPresented: $viewModel.isShowingAccountPicker) { accountSheet }
            .alert("Помилка", isPresented: Binding(
                get: { viewModel.error != nil },
                set: { _ in viewModel.error = nil }
            )) {
                Button("OK") { viewModel.error = nil }
            } message: {
                Text(viewModel.error?.localizedDescription ?? "")
            }
        }
    }

    // MARK: - Delete

    private var deleteButton: some View {
        Button(role: .destructive) {
            showDeleteConfirm = true
        } label: {
            Label("Видалити транзакцію", systemImage: "trash")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.expenseRed)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.expenseRed.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private func performDelete() {
        Task { [weak viewModel] in
            guard let viewModel else { return }
            do {
                try await viewModel.delete()
                onSaved()
                dismiss()
            } catch {
                viewModel.error = error
            }
        }
    }

    // MARK: - Amount

    private var amountCard: some View {
        VStack(spacing: 4) {
            Text("СУМА")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.textSecondary)
                .tracking(0.6)
            TextField("0", text: $viewModel.amount)
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)
                .keyboardType(.decimalPad)
            Text("₴ гривень")
                .font(.system(size: 13))
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.bgCard, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    // MARK: - Type

    private var typeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("ТИП")
            Picker("Тип", selection: $viewModel.selectedType) {
                ForEach(TransactionType.allCases, id: \.self) { type in
                    Text(type.title).tag(type)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(16)
        .background(Color.bgCard, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    // MARK: - Account

    private var accountCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("РАХУНОК")
            Button {
                viewModel.isShowingAccountPicker = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "creditcard")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.textSecondary)
                    Text(viewModel.selectedAccount?.name ?? L("Оберіть рахунок"))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(viewModel.selectedAccount == nil ? Color.expenseRed : Color.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.textSecondary)
                }
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color.bgCard, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    private var accountSheet: some View {
        NavigationStack {
            Group {
                if viewModel.accounts.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "creditcard")
                            .font(.system(size: 32))
                            .foregroundStyle(Color.textSecondary)
                        Text("Немає рахунків")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.textPrimary)
                        Text("Спочатку додайте рахунок у налаштуваннях.")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(40)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(viewModel.accounts, id: \.id) { account in
                                accountRow(account)
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .background(Color.bgPrimary)
            .navigationTitle("Рахунок")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { viewModel.isShowingAccountPicker = false }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.accentPrimary)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func accountRow(_ account: Account) -> some View {
        let isSelected = viewModel.selectedAccount?.id == account.id
        return Button {
            viewModel.selectedAccount = account
            viewModel.isShowingAccountPicker = false
        } label: {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color(hex: account.color))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: account.icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                Text(account.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.accentPrimary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.bgCard, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Category

    private var categoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("КАТЕГОРІЯ")
            if viewModel.categories.isEmpty {
                Text("Завантаження...")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.textSecondary)
            } else {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(viewModel.filteredCategories, id: \.id) { category in
                        categoryTile(category)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.bgCard, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    private func categoryTile(_ category: Category) -> some View {
        let isSelected = viewModel.selectedCategory?.id == category.id
        return Button {
            viewModel.selectedCategory = category
        } label: {
            VStack(spacing: 6) {
                Circle()
                    .fill(Color(hex: category.color))
                    .frame(width: 48, height: 48)
                    .overlay {
                        if !category.icon.isEmpty {
                            Image(systemName: category.icon)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                    .overlay {
                        if isSelected {
                            Circle().stroke(Color.textPrimary, lineWidth: 2.5)
                        }
                    }
                Text(category.name)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Details

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("ДЕТАЛІ")
            VStack(spacing: 0) {
                DatePicker("Дата", selection: $viewModel.date, displayedComponents: .date)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.textPrimary)
                    .padding(.vertical, 12)
                Divider().background(Color.borderSubtle)
                TextField("Примітка (необов'язково)", text: $viewModel.note)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.textPrimary)
                    .padding(.vertical, 12)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .background(Color.bgCard, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    private func sectionLabel(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(Color.textSecondary)
            .tracking(0.6)
    }
}
