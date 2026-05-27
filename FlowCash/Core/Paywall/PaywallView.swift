import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: PaywallPlan = .yearly

    enum PaywallPlan { case yearly, monthly }

    private let features = [
        ("lock.fill",    "Код-пароль та Face ID"),
        ("icloud.fill",  "Синхронізація через iCloud"),
        ("infinity",     "Необмежені рахунки"),
        ("doc.fill",     "Експорт у CSV та PDF")
    ]

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.bgPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer().frame(height: 20)
                    headerSection
                    featuresList
                    planPicker
                    Spacer()
                    ctaSection
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }

            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
                    .frame(width: 30, height: 30)
                    .background(Color.borderSubtle, in: Circle())
            }
            .padding(20)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.accentPrimary.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: "star.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.accentPrimary)
            }

            VStack(spacing: 6) {
                Text("SpendFlow Pro")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                Text("Усі можливості без обмежень")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.textSecondary)
            }
        }
    }

    // MARK: - Features

    private var featuresList: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(features, id: \.0) { icon, title in
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.incomeGreen)
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.textPrimary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.bgCard, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    // MARK: - Plan picker

    private var planPicker: some View {
        HStack(spacing: 12) {
            planTile(plan: .yearly,  title: "Рік",    price: "₴749", period: "рік")
            planTile(plan: .monthly, title: "Місяць", price: "₴99",  period: "міс")
        }
    }

    private func planTile(plan: PaywallPlan, title: String, price: String, period: String) -> some View {
        let isSelected = selectedPlan == plan
        return Button {
            selectedPlan = plan
        } label: {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                Text("\(price) / \(period)")
                    .font(.system(size: 12))
            }
            .foregroundStyle(isSelected ? .white : Color.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isSelected ? Color.accentPrimary : Color.bgCard,
                in: RoundedRectangle(cornerRadius: 14)
            )
            .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: selectedPlan)
    }

    // MARK: - CTA

    private var ctaSection: some View {
        VStack(spacing: 12) {
            Button {
                // TODO: StoreKit purchase
                dismiss()
            } label: {
                Text("Спробувати 7 днів безкоштовно")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.accentPrimary, in: Capsule())
            }

            Text("Далі ₴749/рік · Скасуйте будь-коли")
                .font(.system(size: 12))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    PaywallView()
}
