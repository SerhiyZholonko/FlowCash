import Foundation
import FactoryKit

@MainActor
@Observable
final class AddTransactionViewModel: ErrorDisplayable, AlertDisplayable {
    var amountString: String = "0"
    var selectedType: TransactionType
    var note: String = ""
    var date: Date = .now
    var categories: [Category] = []
    var selectedCategory: Category?
    var error: Error?
    var alert: AppAlert?
    var isShowingDatePicker = false
    var isShowingNoteInput = false

    init(defaultType: TransactionType = .expense) {
        self.selectedType = defaultType
    }

    @ObservationIgnored
    @Injected(\.dataStore) private var store

    var amountValue: Double { Double(amountString) ?? 0 }
    var isValid: Bool { amountValue > 0 }

    var displayAmount: String {
        amountString == "0" ? "0" : amountString
    }

    var saveButtonTitle: String {
        if let category = selectedCategory {
            return "Зберегти у «\(category.name)»"
        }
        return selectedType == .expense ? "Зберегти витрату" : "Зберегти дохід"
    }

    var filteredCategories: [Category] {
        categories.filter { $0.type == selectedType && !$0.isHidden }
    }

    // MARK: - Numpad

    func numpadTap(_ key: NumpadKey) {
        switch key {
        case .digit(let d):
            if amountString == "0" {
                amountString = d
            } else if amountString.count < 9 {
                amountString += d
            }
        case .dot:
            if !amountString.contains(".") && amountString.count < 8 {
                amountString += "."
            }
        case .delete:
            if amountString.count <= 1 {
                amountString = "0"
            } else {
                amountString.removeLast()
            }
        }
    }

    // MARK: - Load & Save

    func loadCategories() {
        Task(handlingError: self) { [weak self] in
            guard let self else { return }
            let all = try await store.fetchCategories()
            categories = all
            let type = selectedType
            if selectedCategory == nil {
                selectedCategory = all.first { $0.type == type && !$0.isHidden }
            }
        }
    }

    func save() async throws {
        let transaction = Transaction(
            amount: amountValue,
            type: selectedType,
            category: selectedCategory,
            date: date,
            note: note
        )
        try await store.add(transaction)
    }
}

enum NumpadKey {
    case digit(String)
    case dot
    case delete
}
