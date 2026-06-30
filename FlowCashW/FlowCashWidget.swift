import WidgetKit
import SwiftUI

// MARK: - Timeline

struct SnapshotEntry: TimelineEntry {
    let date: Date
    let snapshot: FinanceSnapshot
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SnapshotEntry {
        applyAppLanguage()
        return SnapshotEntry(date: .now, snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (SnapshotEntry) -> Void) {
        applyAppLanguage()
        completion(SnapshotEntry(date: .now, snapshot: load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SnapshotEntry>) -> Void) {
        applyAppLanguage()
        let entry = SnapshotEntry(date: .now, snapshot: load())
        // Оновлюємо щогодини; застосунок також примусово перезавантажує таймлайн при змінах.
        let next = Date().addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func load() -> FinanceSnapshot {
        guard let data = WidgetShared.defaults?.data(forKey: WidgetShared.snapshotKey),
              let snapshot = try? JSONDecoder().decode(FinanceSnapshot.self, from: data) else {
            return .placeholder
        }
        return snapshot
    }

    /// Рендеримо віджет тією ж мовою, що обрана в застосунку (код у App Group).
    private func applyAppLanguage() {
        let code = WidgetShared.defaults?.string(forKey: WidgetShared.languageCodeKey) ?? "uk"
        Bundle.setLanguage(code)
    }
}

// MARK: - View

struct FlowCashWidgetEntryView: View {
    var entry: SnapshotEntry

    private var snapshot: FinanceSnapshot { entry.snapshot }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(snapshot.accountName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color(hex: "#f8fafc"))
                Spacer()
                Text(snapshot.monthTitle)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "#6b7280"))
            }

            HStack(spacing: 12) {
                stat("Дохід", snapshot.incomeText, color: "#22c55e")
                stat("Витрата", snapshot.expenseText, color: "#ef4444")
                stat("Баланс", snapshot.balanceText, color: "#f8fafc")
            }

            HStack(spacing: 10) {
                actionButton(title: "Дохід", systemImage: "plus", color: "#22c55e", path: "income")
                actionButton(title: "Витрата", systemImage: "minus", color: "#ef4444", path: "expense")
            }
        }
    }

    private func stat(_ label: String, _ value: String, color: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(Bundle.main.localizedString(forKey: label, value: label, table: nil).uppercased())
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(Color(hex: "#6b7280"))
            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color(hex: color))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func actionButton(title: String, systemImage: String, color: String, path: String) -> some View {
        Link(destination: URL(string: "flowcash://add/\(path)")!) {
            Label(LocalizedStringKey(title), systemImage: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(Color(hex: color), in: Capsule())
        }
    }
}

// MARK: - Widget

struct FlowCashWidget: Widget {
    let kind = "FlowCashWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            FlowCashWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) { Color(hex: "#1a1d26") }
        }
        .configurationDisplayName("FlowCash")
        .description("Доходи, витрати та баланс за місяць")
        .supportedFamilies([.systemMedium])
    }
}

@main
struct FlowCashWidgetBundle: WidgetBundle {
    var body: some Widget {
        FlowCashWidget()
    }
}

// MARK: - Color hex helper

private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}

#Preview(as: .systemMedium) {
    FlowCashWidget()
} timeline: {
    SnapshotEntry(date: .now, snapshot: .placeholder)
}
