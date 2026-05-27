import SwiftUI

struct MonthSelectorView: View {
    @Binding var selectedDate: Date

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "uk_UA")
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: selectedDate).capitalized
    }

    var body: some View {
        HStack(spacing: 0) {
            Button {
                selectedDate = Calendar.current.date(
                    byAdding: .month, value: -1, to: selectedDate
                ) ?? selectedDate
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
                    .frame(width: 36, height: 36)
            }
            Spacer()
            Text(monthTitle)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
            Spacer()
            Button {
                let next = Calendar.current.date(
                    byAdding: .month, value: 1, to: selectedDate
                ) ?? selectedDate
                if next <= Date() {
                    selectedDate = next
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(
                        isCurrentMonth ? Color.textSecondary.opacity(0.3) : Color.textSecondary
                    )
                    .frame(width: 36, height: 36)
            }
            .disabled(isCurrentMonth)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.bgCard, in: RoundedRectangle(cornerRadius: 10))
    }

    private var isCurrentMonth: Bool {
        Calendar.current.isDate(selectedDate, equalTo: Date(), toGranularity: .month)
    }
}

#Preview {
    MonthSelectorView(selectedDate: .constant(Date()))
        .padding()
        .background(Color.bgPrimary)
}
