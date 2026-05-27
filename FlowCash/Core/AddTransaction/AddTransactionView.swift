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
        .onAppear { viewModel.loadCategories() }
        .sheet(isPresented: $viewModel.isShowingNoteInput) { noteSheet }
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
            Text(viewModel.selectedType == .expense ? "Нова витрата" : "Новий дохід")
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
                icon: "mic",
                label: viewModel.note.isEmpty ? "Нотатка" : viewModel.note
            ) {
                viewModel.isShowingNoteInput = true
            }

            chipButton(
                icon: "calendar",
                label: viewModel.date.isToday ? "Сьогодні" : viewModel.date.shortFormatted
            ) {
                viewModel.isShowingDatePicker.toggle()
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .overlay(alignment: .bottom) {
            if viewModel.isShowingDatePicker {
                DatePicker("", selection: $viewModel.date, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .tint(Color.accentPrimary)
                    .background(Color.bgCard, in: RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 20)
                    .offset(y: 220)
                    .zIndex(10)
            }
        }
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
        return LazyVGrid(columns: cols, spacing: 16) {
            ForEach(viewModel.filteredCategories.prefix(7), id: \.id) { category in
                categoryTile(category)
            }
            addCategoryTile
        }
        .padding(.horizontal, 20)
    }

    private func categoryTile(_ category: Category) -> some View {
        let isSelected = viewModel.selectedCategory?.id == category.id
        return Button {
            viewModel.selectedCategory = isSelected ? nil : category
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
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 24)
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
        f.locale = Locale(identifier: "uk_UA")
        f.dateFormat = "d MMM"
        return f.string(from: self)
    }
}

#Preview {
    AddTransactionView(onSaved: {})
        .injectMockStore()
}
