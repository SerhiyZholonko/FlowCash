import SwiftUI
import Charts

struct StatsView: View {
    @State private var viewModel = StatsViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                periodPicker
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
                    Text(period.rawValue)
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

    // MARK: - Donut

    private var donutSection: some View {
        ZStack {
            if viewModel.expensesByCategory.isEmpty {
                Circle()
                    .stroke(Color.borderSubtle, lineWidth: 28)
                    .frame(width: 200, height: 200)
            } else {
                Chart(viewModel.expensesByCategory) { stat in
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
                Text("Всього")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
                Text(viewModel.totalExpense.formattedCurrency)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
            }
        }
        .frame(height: 200)
    }

    // MARK: - Category list

    private var categoryList: some View {
        VStack(spacing: 0) {
            ForEach(Array(viewModel.expensesByCategory.enumerated()), id: \.offset) { idx, stat in
                categoryRow(stat: stat)
                if idx < viewModel.expensesByCategory.count - 1 {
                    Divider().padding(.leading, 16)
                }
            }
        }
        .background(Color.bgCard, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
    }

    private func categoryRow(stat: CategoryStat) -> some View {
        let pct = stat.total / viewModel.totalExpenseForPercent

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
