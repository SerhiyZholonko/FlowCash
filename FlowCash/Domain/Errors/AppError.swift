import Foundation

enum AppError: LocalizedError {
    case fetchFailed
    case saveFailed
    case deleteFailed
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .fetchFailed:      "Не вдалося завантажити дані"
        case .saveFailed:       "Не вдалося зберегти дані"
        case .deleteFailed:     "Не вдалося видалити дані"
        case .unknown(let e):   e.localizedDescription
        }
    }
}
