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
                        .frame(width: 120, height: 120)
                        .blur(radius: 16)

                    RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.Colors.backgroundElevated, AppTheme.Colors.backgroundCard],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 88, height: 88)
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

                    Image(systemName: "chevron.up.2")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppTheme.Colors.accentSecondary, AppTheme.Colors.accentPrimary],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
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
