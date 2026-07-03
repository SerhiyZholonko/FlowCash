import Foundation
import SwiftUI
import FactoryKit

@MainActor
@Observable
final class CategoryEditorViewModel: ErrorDisplayable, AlertDisplayable {
    var categories: [Category] = []
    var newCategoryName: String = ""
    var newCategoryType: TransactionType = .expense
    var selectedColor: String = "#f87171"
    var selectedIcon: String = "tag"
    var error: Error?
    var alert: AppAlert?

    /// Категорії обраного типу — керується верхнім Picker'ом (newCategoryType),
    /// який водночас задає тип для нової категорії.
    var visibleCategories: [Category] {
        categories.filter { $0.type == newCategoryType }
    }

    let colorSwatches: [String] = [
        "#f87171", "#fb923c", "#fbbf24", "#c084fc",
        "#2dd4bf", "#818cf8", "#22d3ee", "#e879f9"
    ]

    let iconOptions: [String] = [
        "fork.knife", "cup.and.saucer", "tram", "gamecontroller",
        "heart", "house", "tshirt", "graduationcap",
        "gift", "airplane", "antenna.radiowaves.left.and.right", "sparkles",
        "figure.run", "cart", "banknote", "tag"
    ]

    @ObservationIgnored
    @Injected(\.dataStore) private var store

    func loadCategories() {
        Task(handlingError: self) { [weak self] in
            guard let self else { return }
            categories = try await store.fetchCategories()
        }
    }

    func toggleHidden(_ category: Category) {
        Task(handlingError: self) { [weak self] in
            guard let self else { return }
            category.isHidden.toggle()
            try await store.update(category)
            if let idx = categories.firstIndex(where: { $0.id == category.id }) {
                categories[idx] = category
            }
        }
    }

    func addCategory() {
        let name = newCategoryName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let newCategory = Category(
            name: name,
            icon: selectedIcon,
            color: selectedColor,
            type: newCategoryType,
            order: categories.count
        )
        Task(handlingError: self) { [weak self] in
            guard let self else { return }
            try await store.add(newCategory)
            categories.append(newCategory)
            newCategoryName = ""
            selectedIcon = "tag"
        }
    }

    func delete(_ category: Category) {
        Task(handlingError: self) { [weak self] in
            guard let self else { return }
            try await store.delete(category)
            categories.removeAll { $0.id == category.id }
        }
    }

    func moveCategories(from source: IndexSet, to destination: Int) {
        categories.move(fromOffsets: source, toOffset: destination)
        for (index, category) in categories.enumerated() {
            category.order = index
        }
        Task(handlingError: self) { [weak self] in
            guard let self else { return }
            for category in categories {
                try await store.update(category)
            }
        }
    }
}
