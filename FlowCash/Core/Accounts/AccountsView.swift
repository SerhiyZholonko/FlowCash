import SwiftUI

struct AccountsView: View {
    @State private var viewModel = AccountsViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                totalBalanceCard
                accountsList
                transferButton
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .background(Color.bgPrimary)
        .navigationTitle("Рахунки")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    // TODO: Add account sheet
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.accentPrimary)
                }
            }
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

    // MARK: - Total balance card

    private var totalBalanceCard: some View {
        VStack(spacing: 4) {
            Text("ЗАГАЛЬНИЙ БАЛАНС")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.textSecondary)
                .tracking(0.5)
            Text(viewModel.totalBalance.formattedCurrency)
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(Color.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.bgCard, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    // MARK: - Accounts list

    private var accountsList: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.accounts, id: \.id) { account in
                accountCard(account)
            }
        }
    }

    private func accountCard(_ account: Account) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: account.icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                Text(account.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                Spacer()
            }
            Text(account.balance.formattedCurrency)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white)
        }
        .padding(20)
        .background(Color(hex: account.color), in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color(hex: account.color).opacity(0.3), radius: 8, y: 4)
    }

    // MARK: - Transfer button

    private var transferButton: some View {
        Button {
            // TODO: Transfer sheet
        } label: {
            Text("Переказ між рахунками")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.bgCard, in: RoundedRectangle(cornerRadius: 14))
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        AccountsView()
    }
    .injectMockStore()
}
