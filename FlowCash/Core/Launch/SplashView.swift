import SwiftUI

/// Заставка, що показується поки дані застосунку завантажуються (мінімум ~2 с).
/// Лого зʼявляється з масштабуванням, навколо обертається «дихаюче» кільце,
/// саме лого м'яко пульсує, а внизу проявляється назва застосунку.
struct SplashView: View {
    @State private var appeared = false
    @State private var rotation: Double = 0
    @State private var pulse = false
    @State private var trimEnd: CGFloat = 0.15

    private let logoSize: CGFloat = 100
    private let ringSize: CGFloat = 142

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            VStack(spacing: 26) {
                ZStack {
                    // Обертове кільце зі змінною довжиною дуги (ефект завантаження).
                    Circle()
                        .trim(from: 0, to: trimEnd)
                        .stroke(
                            Color.accentPrimary,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: ringSize, height: ringSize)
                        .rotationEffect(.degrees(rotation))

                    // Лого застосунку з м'якою пульсацією та світінням.
                    Image("LaunchLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: logoSize, height: logoSize)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .shadow(color: Color.accentPrimary.opacity(0.35), radius: 22)
                        .scaleEffect(pulse ? 1.06 : 0.95)
                }
                .scaleEffect(appeared ? 1 : 0.6)
                .opacity(appeared ? 1 : 0)

                Text("FlowCash")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 14)
            }
        }
        .onAppear(perform: startAnimations)
    }

    private func startAnimations() {
        // Поява: лого та назва виринають із масштабуванням.
        withAnimation(.spring(response: 0.6, dampingFraction: 0.68)) {
            appeared = true
        }
        // Безперервне обертання кільця.
        withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
            rotation = 360
        }
        // «Дихання» довжини дуги.
        withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
            trimEnd = 0.85
        }
        // М'яка пульсація лого.
        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
            pulse = true
        }
    }
}

#Preview {
    SplashView()
}
