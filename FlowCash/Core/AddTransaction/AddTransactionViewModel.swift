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

    var isAddingCategory = false
    var newCategoryName = ""
    var newCategoryColor = "#f87171"
    var newCategoryIcon = "tag"

    let colorSwatches: [String] = [
        "#f87171", "#fb923c", "#fbbf24", "#c084fc",
        "#2dd4bf", "#818cf8", "#22d3ee", "#e879f9"
    ]

    let iconOptions: [String] = [
        "tag", "fork.knife", "cup.and.saucer", "cart", "bag", "tram",
        "car", "fuelpump", "airplane", "house", "gamecontroller", "heart",
        "pills", "tshirt", "graduationcap", "book", "gift", "sparkles",
        "figure.run", "dumbbell", "pawprint", "phone", "wifi", "doc.text",
        "creditcard", "banknote", "laptopcomputer", "music.note", "camera",
        "leaf", "wrench.and.screwdriver", "ellipsis.circle"
    ]

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
            return L("Зберегти у «%@»", category.name)
        }
        return selectedType == .expense
            ? L("Зберегти витрату")
            : L("Зберегти дохід")
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

    func addCategory() {
        let name = newCategoryName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let category = Category(
            name: name,
            icon: newCategoryIcon,
            color: newCategoryColor,
            type: selectedType,
            order: categories.count
        )
        Task(handlingError: self) { [weak self] in
            guard let self else { return }
            try await store.add(category)
            categories.append(category)
            selectedCategory = category
            newCategoryName = ""
            newCategoryColor = colorSwatches.first ?? "#f87171"
            newCategoryIcon = iconOptions.first ?? "tag"
            isAddingCategory = false
        }
    }

    func save() async throws {
        let accounts = try await store.fetchAccounts()
        let account = resolveSelectedAccount(accounts)

        let transaction = Transaction(
            amount: amountValue,
            type: selectedType,
            category: selectedCategory,
            date: date,
            note: note
        )
        transaction.account = account
        try await store.add(transaction)

        if let account {
            account.balance += transaction.signedAmount
            try await store.update(account)
        }
    }

    private func resolveSelectedAccount(_ accounts: [Account]) -> Account? {
        if let stored = UserDefaults.standard.string(forKey: AccountSelection.key),
           let id = UUID(uuidString: stored),
           let match = accounts.first(where: { $0.id == id }) {
            return match
        }
        return accounts.first
    }
}

enum NumpadKey {
    case digit(String)
    case dot
    case delete
}
