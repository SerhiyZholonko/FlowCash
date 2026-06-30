import Foundation
import LocalAuthentication

@MainActor
@Observable
final class AppLockManager {
    private let enabledKey = "faceIDLockEnabled"

    /// Чи показано екран блокування зараз.
    private(set) var isLocked: Bool

    /// Чи ввімкнено Face ID-замок (зберігається в UserDefaults).
    private(set) var isEnabled: Bool

    init() {
        let enabled = UserDefaults.standard.bool(forKey: enabledKey)
        isEnabled = enabled
        isLocked = enabled // на старті застосунок замкнено, якщо функцію ввімкнено
    }

    /// Замкнути при переході у фон (лише якщо функцію ввімкнено).
    func lockIfNeeded() {
        if isEnabled { isLocked = true }
    }

    /// Спроба розблокувати з екрана блокування.
    func unlock() async {
        guard isLocked else { return }
        if await evaluate(reason: L("Розблокуйте FlowCash")) {
            isLocked = false
        }
    }

    /// Увімкнення в налаштуваннях — підтверджуємо біометрію перед збереженням.
    func enableLock() async {
        guard await evaluate(reason: L("Увімкнути Face ID для FlowCash")) else {
            isEnabled = false
            return
        }
        isEnabled = true
        UserDefaults.standard.set(true, forKey: enabledKey)
    }

    func disableLock() {
        isEnabled = false
        isLocked = false
        UserDefaults.standard.set(false, forKey: enabledKey)
    }

    private func evaluate(reason: String) async -> Bool {
        let context = LAContext()
        context.localizedFallbackTitle = L("Ввести код-пароль")
        // .deviceOwnerAuthentication: Face ID з резервним пасскодом — щоб не замкнути себе.
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) else { return false }
        do {
            return try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
        } catch {
            return false
        }
    }
}
