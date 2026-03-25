import SwiftUI

struct EmailVerificationView: View {
    @EnvironmentObject private var authVM: AuthViewModel

    let email: String

    @State private var resendCooldown = 0
    @State private var iconBounce = false

    private var canResend: Bool {
        resendCooldown == 0 && !authVM.isLoading
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.backgroundPrimary.ignoresSafeArea()

            Circle()
                .fill(AppTheme.Colors.accentPrimary.opacity(0.12))
                .frame(width: 320, height: 320)
                .blur(radius: 80)
                .offset(y: -80)

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.accentPrimary.opacity(0.1))
                        .frame(width: 100, height: 100)

                    Image(systemName: "envelope.badge.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppTheme.Colors.accentSecondary, AppTheme.Colors.accentPrimary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(iconBounce ? 1.12 : 1.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.5).repeatCount(1), value: iconBounce)
                }
                .padding(.bottom, AppTheme.Spacing.lg)

                VStack(spacing: AppTheme.Spacing.sm) {
                    Text("Check Your Email")
                        .font(AppTheme.Typography.displayMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("We sent a verification link to")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)

                    Text(email)
                        .font(AppTheme.Typography.titleSmall)
                        .foregroundColor(AppTheme.Colors.accentSecondary)
                }
                .padding(.bottom, AppTheme.Spacing.xl)

                GlassCard(padding: AppTheme.Spacing.lg) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        VerificationStep(number: "1", text: "Open the email we sent you")
                        VerificationStep(number: "2", text: "Tap the confirmation link")
                        VerificationStep(number: "3", text: "Return here and tap \"I've Verified\"")
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.bottom, AppTheme.Spacing.xl)

                if let error = authVM.generalError {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(AppTheme.Colors.error)
                            .font(.system(size: 14))
                        Text(error)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.error)
                        Spacer()
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.bottom, AppTheme.Spacing.md)
                    .transition(.opacity)
                    .animation(AppTheme.Animation.standard, value: authVM.generalError)
                }

                VStack(spacing: AppTheme.Spacing.sm) {
                    PrimaryButton("I've Verified", isLoading: authVM.isLoading) {
                        Task { await authVM.checkEmailVerified() }
                    }

                    Button {
                        guard canResend else { return }
                        Task {
                            await authVM.resendVerification()
                            startCooldown()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            if resendCooldown > 0 {
                                Image(systemName: "clock")
                                    .font(.system(size: 13))
                                Text("Resend in \(resendCooldown)s")
                            } else {
                                Text("Resend verification email")
                            }
                        }
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(canResend ? AppTheme.Colors.accentSecondary : AppTheme.Colors.textTertiary)
                    }
                    .disabled(!canResend)
                    .padding(.top, AppTheme.Spacing.xs)
                }
                .padding(.horizontal, AppTheme.Spacing.md)

                Spacer()

                Button {
                    Task { await authVM.signOut() }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Back to Login")
                    }
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textTertiary)
                }
                .padding(.bottom, AppTheme.Spacing.xl)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.3)) {
                iconBounce = true
            }
        }
    }

    private func startCooldown() {
        resendCooldown = 60
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            DispatchQueue.main.async {
                if resendCooldown > 0 {
                    resendCooldown -= 1
                } else {
                    timer.invalidate()
                }
            }
        }
    }
}

private struct VerificationStep: View {
    let number: String
    let text: String

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Text(number)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(AppTheme.Colors.accentPrimary)
                .frame(width: 28, height: 28)
                .background(AppTheme.Colors.accentPrimary.opacity(0.15))
                .clipShape(Circle())

            Text(text)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)

            Spacer()
        }
    }
}

#Preview {
    EmailVerificationView(email: "soldier@army.mil")
        .environmentObject(AuthViewModel())
        .preferredColorScheme(.dark)
}
