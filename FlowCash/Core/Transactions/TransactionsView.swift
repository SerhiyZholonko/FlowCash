import SwiftUI

struct TransactionsView: View {
    @State private var viewModel = TransactionsViewModel()

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if viewModel.grouped.isEmpty && viewModel.searchText.isEmpty {
                    emptyState
                } else {
                    transactionsList
                }
            }

            addButton
        }
        .background(Color.bgPrimary)
        .navigationTitle("Транзакції")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Пошук транзакцій"
        )
        .sheet(isPresented: $viewModel.isAddingTransaction, onDismiss: { viewModel.loadData() }) {
            AddTransactionView(onSaved: { viewModel.loadData() })
        }
        .sheet(item: $viewModel.editingTransaction, onDismiss: { viewModel.loadData() }) { transaction in
            EditTransactionView(transaction: transaction) { viewModel.loadData() }
        }
        .onAppear { viewModel.loadData() }
        .alert("Помилка", isPresented: Binding(
            get: { viewModel.error != nil },
            set: { _ in viewModel.error = nil }
        )) {
            Button("OK") { viewModel.error = nil }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "")
        }
    }

    // MARK: - List

    private var transactionsList: some View {
        List {
            ForEach(viewModel.grouped) { group in
                Section {
                    ForEach(group.transactions, id: \.id) { transaction in
                        transactionRow(transaction)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.bgCard)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    viewModel.delete(transaction)
                                } label: {
                                    Label("Видалити", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    viewModel.editingTransaction = transaction
                                } label: {
                                    Label("Змінити", systemImage: "pencil")
                                }
                                .tint(Color.accentPrimary)
                            }
                    }
                } header: {
                    groupHeader(group)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.bgPrimary)
    }

    private func groupHeader(_ group: TransactionGroup) -> some View {
        HStack {
            Text(group.title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.textSecondary)
            Spacer()
            Text(group.total.formattedSignedCurrency)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(group.total >= 0 ? Color.incomeGreen : Color.expenseRed)
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))
    }

    private func transactionRow(_ transaction: Transaction) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: transaction.category?.color ?? "#cbd5e1"))
                .frame(width: 44, height: 44)
                .overlay {
                    let icon = transaction.category?.icon ?? "ellipsis.circle"
                    Image(systemName: icon.isEmpty ? "ellipsis.circle" : icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.category?.name ?? "Без категорії")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                if !transaction.note.isEmpty {
                    Text(transaction.note)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text(transaction.type == .expense ? "-₴\(transaction.amount.formattedAmount)" : "+₴\(transaction.amount.formattedAmount)")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(transaction.type == .expense ? Color.expenseRed : Color.incomeGreen)
        }
        .contentShape(Rectangle())
        .onTapGesture { viewModel.editingTransaction = transaction }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color.textSecondary)
            Text("Немає транзакцій")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.textSecondary)
            Text("Натисніть + щоб додати першу")
                .font(.system(size: 13))
                .foregroundStyle(Color.textSecondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - FAB

    private var addButton: some View {
        Button { viewModel.isAddingTransaction = true } label: {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color.accentPrimary, in: Circle())
                .shadow(color: Color.accentPrimary.opacity(0.35), radius: 12, y: 4)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 24)
    }
}

#Preview {
    NavigationStack {
        TransactionsView()
    }
    .injectMockStore()
}
