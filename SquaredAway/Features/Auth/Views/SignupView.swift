import SwiftUI

struct SignupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authVM: AuthViewModel

    private var passwordStrength: PasswordStrength {
        PasswordStrength(password: authVM.password)
    }

    private var passwordsMatch: Bool {
        !authVM.confirmPassword.isEmpty && authVM.confirmPassword == authVM.password
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.backgroundPrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        VStack(spacing: AppTheme.Spacing.sm) {
                            Text("Create Account")
                                .font(AppTheme.Typography.displayMedium)
                                .foregroundColor(AppTheme.Colors.textPrimary)

                            Text("Set up your auth profile to start onboarding.")
                                .font(AppTheme.Typography.bodyMedium)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, AppTheme.Spacing.xl)

                        GlassCard(padding: AppTheme.Spacing.lg) {
                            VStack(spacing: AppTheme.Spacing.md) {
                                AuthTextField(
                                    placeholder: "Military email",
                                    icon: "envelope.fill",
                                    text: $authVM.email,
                                    keyboardType: .emailAddress,
                                    textContentType: .emailAddress,
                                    errorMessage: authVM.emailError
                                )

                                AuthTextField(
                                    placeholder: "Password",
                                    icon: "lock.fill",
                                    text: $authVM.password,
                                    isSecure: true,
                                    textContentType: .newPassword,
                                    errorMessage: authVM.passwordError
                                )

                                PasswordStrengthView(strength: passwordStrength)

                                AuthTextField(
                                    placeholder: "Confirm password",
                                    icon: "checkmark.shield.fill",
                                    text: $authVM.confirmPassword,
                                    isSecure: true,
                                    textContentType: .newPassword,
                                    errorMessage: authVM.confirmPasswordError
                                )

                                if !authVM.confirmPassword.isEmpty {
                                    HStack(spacing: AppTheme.Spacing.xs) {
                                        Image(systemName: passwordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                                            .foregroundColor(passwordsMatch ? AppTheme.Colors.success : AppTheme.Colors.error)
                                        Text(passwordsMatch ? "Passwords match" : "Passwords do not match")
                                            .font(AppTheme.Typography.caption)
                                            .foregroundColor(passwordsMatch ? AppTheme.Colors.success : AppTheme.Colors.error)
                                        Spacer()
                                    }
                                    .transition(.opacity)
                                }

                                if let error = authVM.generalError {
                                    ErrorBanner(message: error)
                                }

                                PrimaryButton("Create Account", isLoading: authVM.isLoading) {
                                    Task {
                                        await authVM.signUp()
                                        if case .pendingVerification = authVM.authState {
                                            dismiss()
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.bottom, AppTheme.Spacing.xxl)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.Colors.accentSecondary)
                }
            }
            .preferredColorScheme(.dark)
            .onAppear {
                authVM.clearErrors()
                authVM.password = ""
                authVM.confirmPassword = ""
            }
        }
    }
}

private struct PasswordStrengthView: View {
    let strength: PasswordStrength

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            HStack(spacing: AppTheme.Spacing.xs) {
                ForEach(0..<4, id: \.self) { index in
                    RoundedRectangle(cornerRadius: AppTheme.Radius.full)
                        .fill(index < strength.level ? strength.color : AppTheme.Colors.glassBorder)
                        .frame(maxWidth: .infinity)
                        .frame(height: 6)
                }
            }

            Text(strength.label)
                .font(AppTheme.Typography.caption)
                .foregroundColor(strength.color)
        }
    }
}

private struct PasswordStrength {
    let level: Int
    let label: String
    let color: Color

    init(password: String) {
        var score = 0
        if password.count >= 8 { score += 1 }
        if password.rangeOfCharacter(from: .uppercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil { score += 1 }
        if password.rangeOfCharacter(from: CharacterSet.punctuationCharacters.union(.symbols)) != nil { score += 1 }

        level = max(1, min(score, 4))

        switch score {
        case 0:
            label = "Use at least 8 characters with upper, number, and symbol."
            color = AppTheme.Colors.textTertiary
        case 1:
            label = "Weak password"
            color = AppTheme.Colors.error
        case 2:
            label = "Fair password"
            color = AppTheme.Colors.warning
        case 3:
            label = "Strong password"
            color = AppTheme.Colors.accentSecondary
        default:
            label = "Very strong password"
            color = AppTheme.Colors.success
        }
    }
}

#Preview {
    SignupView()
        .environmentObject(AuthViewModel())
        .preferredColorScheme(.dark)
}

private struct ErrorBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(AppTheme.Colors.error)
                .font(.system(size: 15))

            Text(message)
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Colors.error)
                .multilineTextAlignment(.leading)

            Spacer()
        }
        .padding(AppTheme.Spacing.sm)
        .background(AppTheme.Colors.error.opacity(0.08))
        .cornerRadius(AppTheme.Radius.sm)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                .stroke(AppTheme.Colors.error.opacity(0.2), lineWidth: 1)
        )
    }
}
