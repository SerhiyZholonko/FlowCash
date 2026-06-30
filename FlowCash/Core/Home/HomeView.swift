import SwiftUI
import Charts

enum HomeRoute: Hashable {
    case transactions
    case income
    case stats
    case accounts
    case budgets
    case settings
    case category(CategoryStat)
}

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @State private var path: [HomeRoute] = []
    @Environment(AccountSelection.self) private var accountSelection
    @Environment(DeepLinkRouter.self) private var deepLink

    private var selectedAccount: Account? {
        accountSelection.resolve(in: viewModel.accounts)
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 20) {
                        headerRow
                        accountSelector
                        donutSection
                        statsRow
                        topExpensesSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 100)
                }
                .background(Color.bgPrimary)

                actionButtons
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .transactions:       TransactionsView()
                case .income:             TransactionsView(typeFilter: .income)
                case .stats:              StatsView()
                case .accounts:           AccountsView()
                case .budgets:            BudgetsView()
                case .settings:           SettingsView()
                case .category(let stat): CategoryDetailView(stat: stat)
                }
            }
        }
        .preferredColorScheme(.dark)
        .overlay {
            if viewModel.isLoading {
                SplashView()
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.35), value: viewModel.isLoading)
        .onAppear {
            viewModel.preferredAccountId = accountSelection.selectedId
            viewModel.loadData()
            handlePendingAdd()
        }
        .onChange(of: accountSelection.selectedId) { _, newId in
            viewModel.preferredAccountId = newId
            viewModel.writeWidgetSnapshot()
        }
        .onChange(of: path) { _, newPath in
            // Повернулися на корінь (напр. після видалення рахунку в AccountsView) —
            // перезавантажуємо дані, щоб головна не показувала видалений рахунок.
            if newPath.isEmpty { viewModel.loadData() }
        }
        .onChange(of: deepLink.pendingAdd) { _, _ in
            handlePendingAdd()
        }
        .sheet(isPresented: $viewModel.isAddingExpense, onDismiss: { viewModel.loadData() }) {
            AddTransactionView(defaultType: .expense) { viewModel.loadData() }
        }
        .sheet(isPresented: $viewModel.isAddingIncome, onDismiss: { viewModel.loadData() }) {
            AddTransactionView(defaultType: .income) { viewModel.loadData() }
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

    // MARK: - Account selector

    private var accountSelector: some View {
        Menu {
            ForEach(viewModel.accounts, id: \.id) { account in
                Button {
                    accountSelection.selectedId = account.id
                } label: {
                    if selectedAccount?.id == account.id {
                        Label(account.name, systemImage: "checkmark")
                    } else {
                        Text(account.name)
                    }
                }
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: selectedAccount?.icon ?? "creditcard")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(Color(hex: selectedAccount?.color ?? "#3b82f6"), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(selectedAccount?.name ?? L("Немає рахунків"))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.textPrimary)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.textSecondary)
                    }
                    Text((selectedAccount?.balance ?? 0).formattedCurrency)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                }
                Spacer()
            }
            .padding(14)
            .background(Color.bgCard, in: RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(viewModel.accounts.isEmpty)
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            Button {
                viewModel.selectedMonth = Calendar.current.date(
                    byAdding: .month, value: -1, to: viewModel.selectedMonth
                ) ?? viewModel.selectedMonth
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
                    .frame(width: 32, height: 32)
            }

            Spacer()

            Text(monthTitle)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color.textPrimary)

            Spacer()

            HStack(spacing: 4) {
                Button {
                    let next = Calendar.current.date(
                        byAdding: .month, value: 1, to: viewModel.selectedMonth
                    ) ?? viewModel.selectedMonth
                    if next <= Date() { viewModel.selectedMonth = next }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isCurrentMonth ? Color.borderSubtle : Color.textSecondary)
                        .frame(width: 32, height: 32)
                }
                .disabled(isCurrentMonth)

                Button { path.append(.settings) } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                        .frame(width: 44, height: 44)
                        .background(Color.bgCard, in: Circle())
                }
            }
        }
    }

    // MARK: - Donut chart

    private var donutSection: some View {
        ZStack {
            if viewModel.expensesByCategory.isEmpty {
                emptyDonut
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
                .frame(width: 220, height: 220)
            }

            VStack(spacing: 2) {
                Text("ВИТРАЧЕНО")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
                    .tracking(0.5)
                Text(viewModel.totalExpense.formattedCurrency)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                Text(monthTitle.lowercased())
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .frame(height: 220)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { path.append(.stats) }
    }

    private var emptyDonut: some View {
        Circle()
            .stroke(Color.borderSubtle, lineWidth: 28)
            .frame(width: 196, height: 196)
            .overlay {
                VStack(spacing: 2) {
                    Text("ВИТРАЧЕНО")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.textSecondary)
                        .tracking(0.5)
                    Text("0 ₴")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                    Text(monthTitle.lowercased())
                        .font(.system(size: 12))
                        .foregroundStyle(Color.textSecondary)
                }
            }
    }

    // MARK: - Stats row

    private var statsRow: some View {
        HStack(spacing: 12) {
            Button { path.append(.income) } label: {
                statCard(dot: Color.incomeGreen, label: "ДОХІД МІСЯЦЯ", value: viewModel.totalIncome.formattedCurrency)
            }
            .buttonStyle(.plain)

            Button { path.append(.accounts) } label: {
                statCard(dot: Color.accentPrimary, label: "БАЛАНС МІСЯЦЯ", value: viewModel.totalBalance.formattedCurrency)
            }
            .buttonStyle(.plain)
        }
    }

    private func statCard(dot: Color, label: LocalizedStringKey, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Circle().fill(dot).frame(width: 8, height: 8)
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
                    .tracking(0.4)
            }
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.bgCard, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
    }

    // MARK: - Top expenses

    private var topExpensesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("НАЙБІЛЬШІ ВИТРАТИ")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
                    .tracking(0.5)
                Spacer()
                Button { path.append(.transactions) } label: {
                    Text("Усі →")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.accentPrimary)
                }
                .buttonStyle(.plain)
            }

            if viewModel.topExpenses.isEmpty {
                Text("Витрат ще немає")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
                    .background(Color.bgCard, in: RoundedRectangle(cornerRadius: 14))
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.topExpenses.enumerated()), id: \.offset) { idx, stat in
                        Button {
                            path.append(.category(stat))
                        } label: {
                            topExpenseRow(stat: stat)
                        }
                        .buttonStyle(.plain)
                        if idx < viewModel.topExpenses.count - 1 {
                            Divider().padding(.leading, 60)
                        }
                    }
                }
                .background(Color.bgCard, in: RoundedRectangle(cornerRadius: 14))
                .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
            }
        }
    }

    private func topExpenseRow(stat: CategoryStat) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: stat.color))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: stat.icon.isEmpty ? "ellipsis.circle" : stat.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(stat.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.borderSubtle).frame(height: 3)
                        let pct = stat.total / viewModel.totalExpenseForPercent
                        Capsule()
                            .fill(Color(hex: stat.color))
                            .frame(width: geo.size.width * CGFloat(pct), height: 3)
                    }
                }
                .frame(height: 3)
            }

            Text(stat.total.formattedCurrency)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
                .fixedSize()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    // MARK: - Action buttons

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button { viewModel.isAddingIncome = true } label: {
                Label("Дохід", systemImage: "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.incomeGreen, in: Capsule())
            }
            Button { viewModel.isAddingExpense = true } label: {
                Label("Витрата", systemImage: "minus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.expenseRed, in: Capsule())
            }

         
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
        .background(
            Color.bgPrimary
                .shadow(color: .black.opacity(0.12), radius: 12, y: -4)
                .ignoresSafeArea()
        )
    }

    // MARK: - Helpers

    private var monthTitle: String {
        let f = DateFormatter()
        f.locale = LocalizationManager.shared.locale
        f.dateFormat = "LLLL yyyy"
        return f.string(from: viewModel.selectedMonth).capitalized
    }

    private var isCurrentMonth: Bool {
        Calendar.current.isDate(viewModel.selectedMonth, equalTo: Date(), toGranularity: .month)
    }

    // MARK: - Deep link

    private func handlePendingAdd() {
        guard let type = deepLink.pendingAdd else { return }
        switch type {
        case .income:  viewModel.isAddingIncome = true
        case .expense: viewModel.isAddingExpense = true
        }
        deepLink.pendingAdd = nil
    }
}

#Preview {
    HomeView()
        .environment(AccountSelection())
        .environment(DeepLinkRouter())
        .injectMockStore()
}
