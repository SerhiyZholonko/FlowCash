import Foundation

struct CategoryStat: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let color: String
    let icon: String
    let total: Double
}
