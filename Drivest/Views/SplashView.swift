import SwiftUI

struct SplashView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let onDismiss: () -> Void

    @State private var opacity: Double = 0

    private var foregroundColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private var backgroundColor: Color {
        colorScheme == .dark ? .black : .white
    }

    var body: some View {
        backgroundColor
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: 16) {
                    Image("SplashIcon")
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundStyle(foregroundColor)

                    Text("drivest")
                        .font(.system(size: 32, weight: .semibold, design: .rounded))
                        .foregroundStyle(foregroundColor)
                }
                .opacity(opacity)
            }
            .onAppear {
                let fadeIn = reduceMotion ? 0.15 : 0.6
                let hold = reduceMotion ? 0.4 : 1.1
                let fadeOut = reduceMotion ? 0.15 : 0.8
                withAnimation(.easeOut(duration: fadeIn)) {
                    opacity = 1
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + hold) {
                    withAnimation(.easeIn(duration: fadeOut)) {
                        opacity = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + fadeOut) {
                        onDismiss()
                    }
                }
            }
    }
}
