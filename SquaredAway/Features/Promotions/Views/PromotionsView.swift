import SwiftUI

struct PromotionsView: View {
    @EnvironmentObject private var authVM: AuthViewModel

    var body: some View {
        Group {
            if let userId = authVM.currentUserId {
                PromotionHubView(
                    branch: authVM.lockedBranch ?? authVM.currentProfile?.branch ?? .army,
                    userId: userId,
                    currentRank: authVM.currentProfile?.rank ?? ""
                )
            } else {
                ZStack {
                    AppTheme.Colors.backgroundPrimary.ignoresSafeArea()
                    ProgressView("Loading promotions...")
                        .tint(AppTheme.Colors.accentSecondary)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                .navigationTitle("Promotions")
            }
        }
        .task {
            await authVM.refreshProfile()
        }
    }
}

#Preview {
    NavigationStack {
        PromotionsView()
            .environmentObject(AuthViewModel())
            .preferredColorScheme(.dark)
    }
}
