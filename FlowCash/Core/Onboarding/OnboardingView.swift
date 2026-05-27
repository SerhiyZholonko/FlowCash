import SwiftUI

struct OnboardingView: View {
    @State private var viewModel = OnboardingViewModel()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("currency") private var currency = "UAH"

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                logoSection

                Spacer()

                currencySection

                Spacer()

                startButton
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Logo

    private var logoSection: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.bgCard)
                    .frame(width: 100, height: 100)
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "#f87171"), Color(hex: "#fbbf24"), Color(hex: "#2dd4bf"), Color(hex: "#818cf8")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 10) {
                Text("SpendFlow")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)

                Text("Рахуй витрати за 5 секунд.\nОдин погляд — повна картина.")
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: "#6b7280"))
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Currency

    private var currencySection: some View {
        HStack(spacing: 10) {
            ForEach(Currency.allCases, id: \.self) { currency in
                currencyTile(currency)
            }
        }
    }

    private func currencyTile(_ currency: Currency) -> some View {
        let isSelected = viewModel.selectedCurrency == currency
        return Button {
            viewModel.selectedCurrency = currency
        } label: {
            VStack(spacing: 4) {
                Text(currency.symbol)
                    .font(.system(size: 22, weight: .bold))
                Text(currency.rawValue)
                    .font(.system(size: 13, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentPrimary : Color.bgCard)
            )
            .foregroundStyle(isSelected ? .white : Color(hex: "#6b7280"))
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: viewModel.selectedCurrency)
    }

    // MARK: - Start button

    private var startButton: some View {
        Button {
            currency = viewModel.selectedCurrency.rawValue
            hasCompletedOnboarding = true
        } label: {
            Text("Почати")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.accentPrimary, in: Capsule())
        }
    }
}

#Preview {
    OnboardingView()
}
