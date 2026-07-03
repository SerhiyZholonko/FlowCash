import SwiftUI

struct CategoryEditorView: View {
    @State private var viewModel = CategoryEditorViewModel()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isNameFocused: Bool

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 18), count: 4)

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    typePicker
                    hintLabel
                    categoryGrid(viewModel.visibleCategories)
                    newCategoryCard
                        .id("newCategory")
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .onChange(of: isNameFocused) { _, focused in
                guard focused else { return }
                withAnimation { proxy.scrollTo("newCategory", anchor: .top) }
            }
        }
        .background(Color.bgPrimary)
        .navigationTitle("Категорії")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Готово") { dismiss() }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.accentPrimary)
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

    // MARK: - Hint

    private var hintLabel: some View {
        Text("ПЕРЕТЯГНИ ДЛЯ СОРТУВАННЯ · ТАПНИ ЩОБ СХОВАТИ")
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(Color.textSecondary)
            .tracking(0.6)
    }

    // MARK: - Category grid

    private func categoryGrid(_ categories: [Category]) -> some View {
        Group {
            if categories.isEmpty {
                Text("Поки немає категорій")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.textSecondary)
            } else {
                LazyVGrid(columns: columns, spacing: 18) {
                    ForEach(categories, id: \.id) { category in
                        categoryTile(category)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func categoryTile(_ category: Category) -> some View {
        Button {
            viewModel.toggleHidden(category)
        } label: {
            VStack(spacing: 8) {
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
                    .opacity(category.isHidden ? 0.35 : 1)
                Text(category.name)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                viewModel.delete(category)
            } label: {
                Label("Видалити", systemImage: "trash")
            }
        }
    }

    // MARK: - New category card

    private var newCategoryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Нова категорія")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            TextField("Назва категорії", text: $viewModel.newCategoryName)
                .font(.system(size: 14))
                .foregroundStyle(Color.textPrimary)
                .focused($isNameFocused)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(Color.bgPrimary, in: RoundedRectangle(cornerRadius: 10))

            Text("Іконка")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.textSecondary)
            iconSwatchRow

            Text("Колір")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.textSecondary)
            colorSwatchRow

            Button(action: viewModel.addCategory) {
                Text("Додати категорію")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        viewModel.newCategoryName.trimmingCharacters(in: .whitespaces).isEmpty
                            ? Color.textSecondary.opacity(0.4)
                            : Color.accentPrimary,
                        in: RoundedRectangle(cornerRadius: 10)
                    )
            }
            .disabled(viewModel.newCategoryName.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(16)
        .background(Color.bgCard, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
    }

    private var typePicker: some View {
        Picker("Тип", selection: $viewModel.newCategoryType) {
            Text("Витрати").tag(TransactionType.expense)
            Text("Дохід").tag(TransactionType.income)
        }
        .pickerStyle(.segmented)
    }

    private var colorSwatchRow: some View {
        HStack(spacing: 8) {
            ForEach(viewModel.colorSwatches, id: \.self) { hex in
                let isSelected = viewModel.selectedColor == hex
                Circle()
                    .fill(Color(hex: hex))
                    .frame(width: 30, height: 30)
                    .overlay {
                        if isSelected {
                            Circle()
                                .stroke(Color.textPrimary, lineWidth: 2.5)
                                .padding(1.5)
                        }
                    }
                    .onTapGesture {
                        viewModel.selectedColor = hex
                    }
            }
            Spacer()
        }
    }

    private var iconSwatchRow: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(viewModel.iconOptions, id: \.self) { icon in
                let isSelected = viewModel.selectedIcon == icon
                Circle()
                    .fill(Color.bgPrimary)
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(isSelected ? Color.accentPrimary : Color.textSecondary)
                    }
                    .overlay {
                        if isSelected {
                            Circle()
                                .stroke(Color.textPrimary, lineWidth: 2.5)
                                .padding(1.5)
                        }
                    }
                    .onTapGesture {
                        viewModel.selectedIcon = icon
                    }
            }
        }
    }
}

#Preview {
    NavigationStack {
        CategoryEditorView()
    }
    .injectMockStore()
}
