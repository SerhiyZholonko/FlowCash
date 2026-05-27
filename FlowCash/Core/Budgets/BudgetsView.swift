import SwiftUI

struct BudgetsView: View {
    @State private var viewModel = BudgetsViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                totalCard
                if !viewModel.budgetItems.isEmpty {
                    categorySection
                } else {
                    emptyState
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .background(Color.bgPrimary)
        .navigationTitle("Бюджети")
        .navigationBarTitleDisplayMode(.large)
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

    // MARK: - Total card

    private var totalCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Загальний бюджет")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text("\(viewModel.totalSpent.formattedAmount) / \(viewModel.totalLimit.formattedCurrency)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.borderSubtle).frame(height: 6)
                    Capsule()
                        .fill(Color.accentPrimary)
                        .frame(width: geo.size.width * CGFloat(viewModel.totalPercentage), height: 6)
                }
            }
            .frame(height: 6)

            Text("Залишилось ₴\((viewModel.totalLimit - viewModel.totalSpent).formattedAmount) · \(viewModel.daysLeft) днів до кінця місяця")
                .font(.system(size: 12))
                .foregroundStyle(Color.textSecondary)
        }
        .padding(16)
        .background(Color.bgCard, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
    }

    // MARK: - Category section

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ЗА КАТЕГОРІЯМИ")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.textSecondary)
                .tracking(0.5)

            VStack(spacing: 0) {
                ForEach(Array(viewModel.budgetItems.enumerated()), id: \.offset) { idx, item in
                    budgetRow(item)
                    if idx < viewModel.budgetItems.count - 1 {
                        Divider().padding(.leading, 60)
                    }
                }
            }
            .background(Color.bgCard, in: RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
        }
    }

    private func budgetRow(_ item: BudgetItem) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.borderSubtle, lineWidth: 3)
                    .frame(width: 44, height: 44)
                Circle()
                    .trim(from: 0, to: CGFloat(item.percentage))
                    .stroke(item.status.color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))
                Image(systemName: item.categoryIcon.isEmpty ? "ellipsis.circle" : item.categoryIcon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: item.categoryColor))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.categoryName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                    Spacer()
                    Text("\(item.percentageInt)%")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(item.status.color)
                }

                HStack {
                    Text("₴\(item.spent.formattedAmount) / ₴\(item.limit.formattedAmount)")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.textSecondary)
                    Spacer()
                    if item.status != .ok {
                        Text(item.status.label)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(item.status.color, in: Capsule())
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "target")
                .font(.system(size: 40))
                .foregroundStyle(Color.textSecondary)
            Text("Немає бюджетів")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color.bgCard, in: RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    NavigationStack {
        BudgetsView()
    }
    .injectMockStore()
}
