import SwiftData
import Foundation

@Model
final class Budget {
    var id: UUID = UUID()
    var categoryID: UUID = UUID()
    var monthlyLimit: Double = 0

    init(
        id: UUID = UUID(),
        categoryID: UUID,
        monthlyLimit: Double
    ) {
        self.id = id
        self.categoryID = categoryID
        self.monthlyLimit = monthlyLimit
    }
}
