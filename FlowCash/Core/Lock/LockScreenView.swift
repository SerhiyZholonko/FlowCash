import SwiftUI

struct LockScreenView: View {
    let onUnlock: () async -> Void

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "faceid")
                    .font(.system(size: 56, weight: .regular))
                    .foregroundStyle(Color.accentPrimary)

                Text("FlowCash заблоковано")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)

                Button {
                    Task { await onUnlock() }
                } label: {
                    Label("Розблокувати", systemImage: "faceid")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28)
                        .frame(height: 52)
                        .background(Color.accentPrimary, in: Capsule())
                }
            }
        }
        .task { await onUnlock() } // авто-промпт Face ID при появі екрана
    }
}

#Preview {
    LockScreenView(onUnlock: {})
}
