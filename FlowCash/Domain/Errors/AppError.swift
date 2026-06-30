import Foundation

enum AppError: LocalizedError {
    case fetchFailed
    case saveFailed
    case deleteFailed
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .fetchFailed:      L("Не вдалося завантажити дані")
        case .saveFailed:       L("Не вдалося зберегти дані")
        case .deleteFailed:     L("Не вдалося видалити дані")
        case .unknown(let e):   e.localizedDescription
        }
    }
}
