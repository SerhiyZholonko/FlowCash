import Foundation

extension Task where Success == Void, Failure == Never {
    @discardableResult
    init(handlingError handler: some ErrorDisplayable, operation: @escaping () async throws -> Void) {
        self.init {
            do {
                try await operation()
            } catch {
                await MainActor.run { handler.error = error }
            }
        }
    }
}
