import SwiftUI

struct ContentView: View {
    @StateObject private var authVM = AuthViewModel()
    @State private var splashComplete = false

    var body: some View {
        ZStack {
            AppTheme.Colors.backgroundPrimary.ignoresSafeArea()

            if !splashComplete {
                SplashView()
                    .transition(.opacity)
                    .onAppear(perform: scheduleSplashDismiss)
            } else {
                switch authVM.authState {
                case .unknown:
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(AppTheme.Colors.accentPrimary)
                        .scaleEffect(1.4)
                        .transition(.opacity)

                case .unauthenticated:
                    NavigationStack {
                        LoginView()
                            .environmentObject(authVM)
                    }
                    .transition(.opacity)

                case .pendingVerification(let email):
                    EmailVerificationView(email: email)
                        .environmentObject(authVM)
                        .transition(.opacity)

                case .passwordRecovery:
                    PasswordRecoveryView()
                        .environmentObject(authVM)
                        .transition(.opacity)

                case .needsOnboarding:
                    OnboardingView()
                        .environmentObject(authVM)
                        .transition(.opacity)

                case .authenticated:
                    DashboardView()
                        .environmentObject(authVM)
                        .transition(.opacity)
                }
            }
        }
        .animation(AppTheme.Animation.slow, value: splashComplete)
        .animation(AppTheme.Animation.standard, value: authVM.authState)
        .preferredColorScheme(.dark)
        .onOpenURL { url in
            Task { await authVM.handleIncomingURL(url) }
        }
    }

    private func scheduleSplashDismiss() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.5)) {
                splashComplete = true
            }
        }
    }
}

#Preview {
    ContentView()
}
