import SwiftUI

struct PasswordRecoveryView: View {
    @EnvironmentObject private var authVM: AuthViewModel

    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var successMessage: String?

    var body: some View {
        ZStack {
            AppTheme.Colors.backgroundPrimary.ignoresSafeArea()

            Circle()
                .fill(AppTheme.Colors.accentPrimary.opacity(0.12))
                .frame(width: 320, height: 320)
                .blur(radius: 80)
                .offset(y: -120)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    VStack(spacing: AppTheme.Spacing.sm) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.Colors.accentPrimary.opacity(0.12))
                                .frame(width: 88, height: 88)

                            Image(systemName: "key.fill")
                                .font(.system(size: 34, weight: .semibold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [AppTheme.Colors.accentSecondary, AppTheme.Colors.accentPrimary],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }

                        Text("Reset Your Password")
                            .font(AppTheme.Typography.displayMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .multilineTextAlignment(.center)

                        Text("Create a new password for your SquaredAway account. After saving, you'll return to the app.")
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, AppTheme.Spacing.xxl)
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.bottom, AppTheme.Spacing.xl)

                    GlassCard(padding: AppTheme.Spacing.lg) {
                        VStack(spacing: AppTheme.Spacing.md) {
                            AuthTextField(
                                placeholder: "New password",
                                icon: "lock.fill",
                                text: $newPassword,
                                isSecure: true,
                                textContentType: .newPassword,
                                errorMessage: authVM.passwordError
                            )

                            AuthTextField(
                                placeholder: "Confirm new password",
                                icon: "lock.shield.fill",
                                text: $confirmPassword,
                                isSecure: true,
                                textContentType: .newPassword,
                                errorMessage: authVM.confirmPasswordError
                            )

                            if let generalError = authVM.generalError {
                                RecoveryBanner(
                                    message: generalError,
                                    color: AppTheme.Colors.error,
                                    icon: "exclamationmark.triangle.fill"
                                )
                            }

                            if let successMessage {
                                RecoveryBanner(
                                    message: successMessage,
                                    color: AppTheme.Colors.success,
                                    icon: "checkmark.circle.fill"
                                )
                            }

                            PrimaryButton("Update Password", isLoading: authVM.isLoading) {
                                Task { await submitRecovery() }
                            }
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)

                    Button {
                        Task { await authVM.cancelPasswordRecovery() }
                    } label: {
                        Text("Cancel Recovery")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                    .padding(.top, AppTheme.Spacing.lg)
                    .padding(.bottom, AppTheme.Spacing.xxl)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func submitRecovery() async {
        successMessage = nil

        do {
            try await authVM.completePasswordRecovery(
                newPassword: newPassword,
                confirmation: confirmPassword
            )
            successMessage = "Password updated."
            newPassword = ""
            confirmPassword = ""
        } catch {
            successMessage = nil
        }
    }
}

private struct RecoveryBanner: View {
    let message: String
    let color: Color
    let icon: String

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(message)
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(color)
            Spacer()
        }
        .padding(AppTheme.Spacing.sm)
        .background(color.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                .stroke(color.opacity(0.24), lineWidth: 1)
        )
        .cornerRadius(AppTheme.Radius.sm)
    }
}

#Preview {
    PasswordRecoveryView()
        .environmentObject(AuthViewModel())
        .preferredColorScheme(.dark)
}
