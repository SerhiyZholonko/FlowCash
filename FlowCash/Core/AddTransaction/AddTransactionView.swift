import SwiftUI

struct AddTransactionView: View {
    @State private var viewModel: AddTransactionViewModel
    @Environment(\.dismiss) private var dismiss
    var onSaved: () -> Void

    init(defaultType: TransactionType = .expense, onSaved: @escaping () -> Void) {
        _viewModel = State(initialValue: AddTransactionViewModel(defaultType: defaultType))
        self.onSaved = onSaved
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar
                amountDisplay
                chipsRow
                categoryGrid
                Spacer()
                numpad
                saveButton
            }
        }
        .onAppear {
            viewModel.loadCategories()
            viewModel.loadAccounts()
        }
        .sheet(isPresented: $viewModel.isShowingNoteInput) { noteSheet }
        .sheet(isPresented: $viewModel.isShowingDatePicker) { dateSheet }
        .sheet(isPresented: $viewModel.isShowingAccountPicker) { accountSheet }
        .sheet(isPresented: $viewModel.isAddingCategory) { addCategorySheet }
        .alert("Помилка", isPresented: Binding(
            get: { viewModel.error != nil },
            set: { _ in viewModel.error = nil }
        )) {
            Button("OK") { viewModel.error = nil }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "")
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Text(viewModel.selectedType == .expense ? L("Нова витрата") : L("Новий дохід"))
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.textPrimary)
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(Color.borderSubtle, in: Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }

    // MARK: - Amount display

    private var amountDisplay: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text("₴")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(amountColor)
            Text(viewModel.displayAmount)
                .font(.system(size: 52, weight: .bold))
                .foregroundStyle(amountColor)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var amountColor: Color {
        viewModel.selectedType == .expense ? Color.expenseRed : Color.incomeGreen
    }

    // MARK: - Chips row

    private var chipsRow: some View {
        HStack(spacing: 8) {
            chipButton(
                icon: "creditcard",
                label: viewModel.selectedAccount?.name ?? L("Рахунок")
            ) {
                viewModel.isShowingAccountPicker = true
            }

            chipButton(
                icon: "mic",
                label: viewModel.note.isEmpty ? L("Нотатка") : viewModel.note
            ) {
                viewModel.isShowingNoteInput = true
            }

            chipButton(
                icon: "calendar",
                label: viewModel.date.isToday ? L("Сьогодні") : viewModel.date.shortFormatted
            ) {
                viewModel.isShowingDatePicker.toggle()
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    private func chipButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
            }
            .foregroundStyle(Color.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color.bgCard, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Category grid

    private var categoryGrid: some View {
        let cols = Array(repeating: GridItem(.flexible(), spacing: 0), count: 4)
        return ScrollView(.vertical, showsIndicators: false) {
            LazyVGrid(columns: cols, spacing: 16) {
                ForEach(viewModel.filteredCategories, id: \.id) { category in
                    categoryTile(category)
                }
                addCategoryTile
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 2)
        }
        .frame(maxHeight: 180)
    }

    private func categoryTile(_ category: Category) -> some View {
        let isSelected = viewModel.selectedCategory?.id == category.id
        return Button {
            viewModel.selectedCategory = category
        } label: {
            VStack(spacing: 6) {
                Circle()
                    .fill(Color(hex: category.color))
                    .frame(width: 52, height: 52)
                    .overlay {
                        if !category.icon.isEmpty {
                            Image(systemName: category.icon)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                    .overlay {
                        if isSelected {
                            Circle().stroke(Color.textPrimary, lineWidth: 2.5)
                        }
                    }
                Text(category.name)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .buttonStyle(.plain)
    }

    private var addCategoryTile: some View {
        Button {
            viewModel.isAddingCategory = true
        } label: {
            VStack(spacing: 6) {
                Circle()
                    .strokeBorder(Color.borderSubtle, style: StrokeStyle(lineWidth: 2, dash: [4]))
                    .frame(width: 52, height: 52)
                    .overlay {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Color.textSecondary)
                    }
                Text("Додати")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Numpad

    private var numpad: some View {
        let keys: [[NumpadKey]] = [
            [.digit("7"), .digit("8"), .digit("9")],
            [.digit("4"), .digit("5"), .digit("6")],
            [.digit("1"), .digit("2"), .digit("3")],
            [.dot,        .digit("0"), .delete]
        ]
        return VStack(spacing: 2) {
            ForEach(keys.indices, id: \.self) { row in
                HStack(spacing: 2) {
                    ForEach(keys[row].indices, id: \.self) { col in
                        numpadButton(keys[row][col])
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private func numpadButton(_ key: NumpadKey) -> some View {
        Button {
            viewModel.numpadTap(key)
        } label: {
            Group {
                switch key {
                case .digit(let d):
                    Text(d)
                        .font(.system(size: 26, weight: .medium))
                        .foregroundStyle(Color.textPrimary)
                case .dot:
                    Text(".")
                        .font(.system(size: 26, weight: .medium))
                        .foregroundStyle(Color.textPrimary)
                case .delete:
                    Image(systemName: "delete.backward")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Color.textPrimary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(Color.bgCard, in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Save button

    private var saveButton: some View {
        VStack(spacing: 8) {
            if viewModel.selectedAccount == nil {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 13))
                    Text("Оберіть рахунок")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(Color.expenseRed)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.expenseRed.opacity(0.12), in: Capsule())
            }
            saveButtonBody
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 24)
    }

    private var saveButtonBody: some View {
        Button {
            Task { [weak viewModel] in
                guard let viewModel, viewModel.isValid else { return }
                try? await viewModel.save()
                onSaved()
                dismiss()
            }
        } label: {
            Text(viewModel.saveButtonTitle)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    viewModel.isValid ? amountColor : Color.borderSubtle,
                    in: Capsule()
                )
        }
        .disabled(!viewModel.isValid)
    }

    // MARK: - Add category sheet

    private var addCategorySheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    categoryPreview

                    TextField("Назва категорії", text: $viewModel.newCategoryName)
                        .font(.system(size: 16))
                        .foregroundStyle(Color.textPrimary)
                        .padding(16)
                        .background(Color.bgCard, in: RoundedRectangle(cornerRadius: 12))

                    Text("Колір")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.textSecondary)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                        ForEach(viewModel.colorSwatches, id: \.self) { hex in
                            Button {
                                viewModel.newCategoryColor = hex
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 44, height: 44)
                                    .overlay {
                                        if viewModel.newCategoryColor == hex {
                                            Circle().stroke(Color.textPrimary, lineWidth: 2.5)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Text("Іконка")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.textSecondary)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 14) {
                        ForEach(viewModel.iconOptions, id: \.self) { icon in
                            Button {
                                viewModel.newCategoryIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundStyle(viewModel.newCategoryIcon == icon ? .white : Color.textSecondary)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        viewModel.newCategoryIcon == icon ? Color.accentPrimary : Color.bgCard,
                                        in: RoundedRectangle(cornerRadius: 10)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.bgPrimary)
            .navigationTitle("Нова категорія")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Скасувати") { viewModel.isAddingCategory = false }
                        .foregroundStyle(Color.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Зберегти") { viewModel.addCategory() }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.accentPrimary)
                        .disabled(viewModel.newCategoryName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.large])
    }

    private var categoryPreview: some View {
        Circle()
            .fill(Color(hex: viewModel.newCategoryColor))
            .frame(width: 64, height: 64)
            .overlay {
                Image(systemName: viewModel.newCategoryIcon)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
    }

    // MARK: - Account sheet

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

    // MARK: - Date sheet

    private var dateSheet: some View {
        NavigationStack {
            VStack {
                DatePicker("", selection: $viewModel.date, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .tint(Color.accentPrimary)
                    .labelsHidden()
                    .padding(.horizontal, 8)
                Spacer()
            }
            .padding(20)
            .background(Color.bgPrimary)
            .navigationTitle("Дата")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { viewModel.isShowingDatePicker = false }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.accentPrimary)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Note sheet

    private var noteSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                TextField("Введіть нотатку...", text: $viewModel.note, axis: .vertical)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.textPrimary)
                    .padding(16)
                    .background(Color.bgCard, in: RoundedRectangle(cornerRadius: 12))
                Spacer()
            }
            .padding(20)
            .background(Color.bgPrimary)
            .navigationTitle("Нотатка")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { viewModel.isShowingNoteInput = false }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.accentPrimary)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Date helpers

private extension Date {
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var shortFormatted: String {
        let f = DateFormatter()
        f.locale = LocalizationManager.shared.locale
        f.dateFormat = "d MMM"
        return f.string(from: self)
    }
}

#Preview {
    AddTransactionView(onSaved: {})
        .injectMockStore()
}
