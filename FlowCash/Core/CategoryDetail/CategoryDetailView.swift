import SwiftUI
import Charts

struct CategoryDetailView: View {
    @State private var viewModel: CategoryDetailViewModel
    @Environment(\.dismiss) private var dismiss

    init(stat: CategoryStat) {
        _viewModel = State(initialValue: CategoryDetailViewModel(stat: stat))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                barChartSection
                transactionsList
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .background(Color.bgPrimary)
        .navigationTitle(viewModel.stat.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Text(viewModel.stat.total.formattedCurrency)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(hex: viewModel.stat.color))
            }
        }
        .onAppear { viewModel.loadData() }
        .sheet(item: $viewModel.editingTransaction, onDismiss: { viewModel.loadData() }) { transaction in
            EditTransactionView(transaction: transaction) { viewModel.loadData() }
        }
        .alert("Помилка", isPresented: Binding(
            get: { viewModel.error != nil },
            set: { _ in viewModel.error = nil }
        )) {
            Button("OK") { viewModel.error = nil }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "")
        }
    }

    // MARK: - Bar chart

    private var barChartSection: some View {
        let bars = viewModel.monthlyBars
        let maxVal = viewModel.maxBarTotal > 0 ? viewModel.maxBarTotal : 1

        return HStack(alignment: .bottom, spacing: 10) {
            ForEach(bars) { bar in
                VStack(spacing: 6) {
                    Spacer()
                    RoundedRectangle(cornerRadius: 6)
                        .fill(bar.isCurrent
                              ? Color(hex: viewModel.stat.color)
                              : Color(hex: viewModel.stat.color).opacity(0.35))
                        .frame(height: bar.total > 0
                               ? max(8, 120 * CGFloat(bar.total / maxVal))
                               : 8)
                    Text(bar.month)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 160)
        .padding(16)
        .background(Color.bgCard, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    // MARK: - Transactions list

    private var transactionsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Транзакції")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            if viewModel.categoryTransactions.isEmpty {
                Text("Немає транзакцій у цій категорії")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(24)
                    .background(Color.bgCard, in: RoundedRectangle(cornerRadius: 14))
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.categoryTransactions.enumerated()), id: \.offset) { idx, t in
                        transactionRow(t)
                        if idx < viewModel.categoryTransactions.count - 1 {
                            Divider().padding(.leading, 56)
                        }
                    }
                }
                .background(Color.bgCard, in: RoundedRectangle(cornerRadius: 14))
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
            }
        }
    }

    private func transactionRow(_ t: Transaction) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: viewModel.stat.color))
                .frame(width: 40, height: 40)
                .overlay {
                    let icon = viewModel.stat.icon
                    Image(systemName: icon.isEmpty ? "ellipsis.circle" : icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(t.note.isEmpty ? viewModel.stat.name : t.note)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Text(t.date.transactionFormatted)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()

            Text("-₴\(t.amount.formattedAmount)")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.expenseRed)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture { viewModel.editingTransaction = t }
        .contextMenu {
            Button(role: .destructive) {
                viewModel.delete(t)
            } label: {
                Label("Видалити", systemImage: "trash")
            }
        }
    }
}

private extension Date {
    var transactionFormatted: String {
        let f = DateFormatter()
        f.locale = LocalizationManager.shared.locale
        f.dateFormat = "d MMMM"
        return f.string(from: self)
    }
}

#Preview {
    NavigationStack {
        CategoryDetailView(stat: CategoryStat(
            name: "Їжа",
            color: "#f87171",
            icon: "fork.knife",
            total: 4200
        ))
    }
    .injectMockStore()
}
