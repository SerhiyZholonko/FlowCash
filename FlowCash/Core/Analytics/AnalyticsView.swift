import SwiftUI
import Charts

struct StatsView: View {
    @State private var viewModel = StatsViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                periodPicker
                summaryCards
                kindPicker
                donutSection
                categoryList
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .background(Color.bgPrimary)
        .navigationTitle("Статистика")
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

    // MARK: - Period picker

    private var periodPicker: some View {
        HStack(spacing: 0) {
            ForEach(StatsPeriod.allCases, id: \.self) { period in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.selectedPeriod = period
                    }
                } label: {
                    Text(LocalizedStringKey(period.rawValue))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(viewModel.selectedPeriod == period ? .white : Color.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background {
                            if viewModel.selectedPeriod == period {
                                Capsule().fill(Color.accentPrimary)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.bgCard, in: Capsule())
        .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
    }

    // MARK: - Summary cards

    private var summaryCards: some View {
        HStack(spacing: 12) {
            summaryCard(title: "Дохід", value: viewModel.totalIncome, color: .incomeGreen)
            summaryCard(title: "Витрати", value: viewModel.totalExpense, color: .expenseRed)
            summaryCard(
                title: "Баланс",
                value: viewModel.totalBalance,
                color: viewModel.totalBalance >= 0 ? .incomeGreen : .expenseRed
            )
        }
    }

    private func summaryCard(title: LocalizedStringKey, value: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.textSecondary)
            Text(value.formattedCurrency)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(color)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.bgCard, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
    }

    // MARK: - Kind picker

    private var kindPicker: some View {
        HStack(spacing: 0) {
            ForEach(StatsKind.allCases, id: \.self) { kind in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.selectedKind = kind
                    }
                } label: {
                    Text(LocalizedStringKey(kind.rawValue))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(viewModel.selectedKind == kind ? .white : Color.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background {
                            if viewModel.selectedKind == kind {
                                Capsule().fill(Color.accentPrimary)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.bgCard, in: Capsule())
        .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
    }

    // MARK: - Donut

    private var donutSection: some View {
        ZStack {
            if viewModel.categoryStats.isEmpty {
                Circle()
                    .stroke(Color.borderSubtle, lineWidth: 28)
                    .frame(width: 200, height: 200)
            } else {
                Chart(viewModel.categoryStats) { stat in
                    SectorMark(
                        angle: .value("Сума", stat.total),
                        innerRadius: .ratio(0.62),
                        angularInset: 2
                    )
                    .foregroundStyle(Color(hex: stat.color))
                    .cornerRadius(4)
                }
                .frame(width: 200, height: 200)
            }

            VStack(spacing: 2) {
                Text(LocalizedStringKey(viewModel.selectedKind.rawValue))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
                Text(viewModel.selectedTotal.formattedCurrency)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
            }
        }
        .frame(height: 200)
    }

    // MARK: - Category list

    private var categoryList: some View {
        VStack(spacing: 0) {
            ForEach(Array(viewModel.categoryStats.enumerated()), id: \.offset) { idx, stat in
                categoryRow(stat: stat)
                if idx < viewModel.categoryStats.count - 1 {
                    Divider().padding(.leading, 16)
                }
            }
        }
        .background(Color.bgCard, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
    }

    private func categoryRow(stat: CategoryStat) -> some View {
        let pct = stat.total / viewModel.selectedTotalForPercent

        return HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: stat.color))
                .frame(width: 10, height: 10)

            Text(stat.name)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
                .frame(minWidth: 80, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.borderSubtle).frame(height: 4)
                    Capsule()
                        .fill(Color(hex: stat.color))
                        .frame(width: geo.size.width * CGFloat(pct), height: 4)
                }
                .frame(maxHeight: .infinity)
            }
            .frame(height: 4)

            Text(stat.total.formattedCurrency)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
                .frame(minWidth: 65, alignment: .trailing)

            Text(String(format: "%d%%", Int(pct * 100)))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.textSecondary)
                .frame(minWidth: 32, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

#Preview {
    NavigationStack {
        StatsView()
    }
    .injectMockStore()
}
