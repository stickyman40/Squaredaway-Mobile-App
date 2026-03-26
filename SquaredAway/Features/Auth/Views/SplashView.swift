import SwiftUI

struct SplashView: View {
    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity = 0.0
    @State private var glowRadius: CGFloat = 60
    @State private var glowOpacity = 0.0
    @State private var subtitleOpacity = 0.0
    @State private var taglineOffset: CGFloat = 12

    var body: some View {
        ZStack {
            AppTheme.Gradients.splashBackground
                .ignoresSafeArea()

            Circle()
                .fill(AppTheme.Gradients.purpleGlow)
                .frame(width: 380, height: 380)
                .blur(radius: glowRadius)
                .opacity(glowOpacity)

            VStack(spacing: AppTheme.Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.accentPrimary.opacity(0.12))
                        .frame(width: 156, height: 156)
                        .blur(radius: 16)

                    RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.Colors.backgroundElevated, AppTheme.Colors.backgroundCard],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 116, height: 116)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            AppTheme.Colors.accentSecondary.opacity(0.5),
                                            AppTheme.Colors.accentPrimary.opacity(0.2)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: AppTheme.Colors.accentPrimary.opacity(0.35), radius: 20, x: 0, y: 8)

                    Image("SquaredAway App Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 82, height: 82)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                VStack(spacing: AppTheme.Spacing.xs) {
                    Text("SquaredAway")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .tracking(1.5)

                    Text("Mission Ready. Every Day.")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                        .tracking(0.5)
                        .offset(y: taglineOffset)
                }
                .opacity(subtitleOpacity)
            }
        }
        .onAppear(perform: runAnimations)
    }

    private func runAnimations() {
        withAnimation(.easeIn(duration: 0.6)) {
            glowOpacity = 1.0
            glowRadius = 80
        }

        withAnimation(.spring(response: 0.7, dampingFraction: 0.65).delay(0.15)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }

        withAnimation(.easeOut(duration: 0.5).delay(0.45)) {
            subtitleOpacity = 1.0
            taglineOffset = 0
        }
    }
}

#Preview {
    SplashView()
        .preferredColorScheme(.dark)
}
