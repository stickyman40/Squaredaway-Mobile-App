import SwiftUI

struct ContentView: View {
    @StateObject private var authVM = AuthViewModel()
    private let launchesDashboardForUITests = Self.isUITestFlagEnabled("UITEST_SHOW_DASHBOARD")
    private let launchesFuelCheckForUITests = Self.isUITestFlagEnabled("UITEST_SHOW_FUEL_CHECK")
    private let launchesPTForUITests = Self.isUITestFlagEnabled("UITEST_SHOW_PT")
    private let launchesPromotionsForUITests = Self.isUITestFlagEnabled("UITEST_SHOW_PROMOTIONS")
    @State private var splashComplete = Self.isUITestFlagEnabled("UITEST_SKIP_SPLASH")
        || Self.isUITestFlagEnabled("UITEST_SHOW_DASHBOARD")
        || Self.isUITestFlagEnabled("UITEST_SHOW_FUEL_CHECK")
        || Self.isUITestFlagEnabled("UITEST_SHOW_PT")
        || Self.isUITestFlagEnabled("UITEST_SHOW_PROMOTIONS")

    var body: some View {
        ZStack {
            AppTheme.Colors.backgroundPrimary.ignoresSafeArea()

            if launchesFuelCheckForUITests {
                NavigationStack {
                    FuelCheckHomeView()
                        .environmentObject(authVM)
                }
                .transition(.opacity)
            } else if launchesPromotionsForUITests {
                NavigationStack {
                    PromotionHubView(
                        branch: .army,
                        userId: UUID(uuidString: "11111111-1111-1111-1111-111111111111") ?? UUID(),
                        currentRank: "Sergeant (E-5)"
                    )
                }
                .transition(.opacity)
            } else if launchesPTForUITests {
                NavigationStack {
                    PTDashboardView()
                        .environmentObject(authVM)
                }
                .transition(.opacity)
            } else if launchesDashboardForUITests {
                DashboardView()
                    .environmentObject(authVM)
                    .transition(.opacity)
            } else if !splashComplete {
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
        if Self.isUITestFlagEnabled("UITEST_SKIP_SPLASH")
            || Self.isUITestFlagEnabled("UITEST_SHOW_DASHBOARD")
            || Self.isUITestFlagEnabled("UITEST_SHOW_FUEL_CHECK")
            || Self.isUITestFlagEnabled("UITEST_SHOW_PT")
            || Self.isUITestFlagEnabled("UITEST_SHOW_PROMOTIONS") {
            splashComplete = true
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.5)) {
                splashComplete = true
            }
        }
    }

    private static func isUITestFlagEnabled(_ flag: String) -> Bool {
#if DEBUG
        ProcessInfo.processInfo.arguments.contains(flag)
#else
        false
#endif
    }
}

#Preview {
    ContentView()
}
