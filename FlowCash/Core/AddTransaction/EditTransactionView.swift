import SwiftUI

struct EditTransactionView: View {
    @State private var viewModel: EditTransactionViewModel
    @Environment(\.dismiss) private var dismiss
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
                    categoryCard
                    detailsCard
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
            .onAppear { viewModel.loadCategories() }
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
                    ForEach(viewModel.categories, id: \.id) { category in
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
            viewModel.selectedCategory = isSelected ? nil : category
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

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(Color.textSecondary)
            .tracking(0.6)
    }
}
