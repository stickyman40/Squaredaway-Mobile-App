import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @State private var showSignup = false
    @State private var showForgotPasswordSheet = false
    @State private var contentOpacity = 0.0
    @State private var contentOffset: CGFloat = 20
    @State private var resetMessage: String?

    var body: some View {
        ZStack {
            AppTheme.Colors.backgroundPrimary.ignoresSafeArea()

            VStack {
                Circle()
                    .fill(AppTheme.Colors.accentPrimary.opacity(0.12))
                    .frame(width: 300, height: 300)
                    .blur(radius: 80)
                    .offset(x: 60, y: -60)
                Spacer()
            }

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    VStack(spacing: AppTheme.Spacing.sm) {
                        ZStack {
                            RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                                .fill(AppTheme.Colors.backgroundCard)
                                .frame(width: 88, height: 88)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                                        .stroke(AppTheme.Colors.glassBorder, lineWidth: 1)
                                )
                                .shadow(color: AppTheme.Colors.accentPrimary.opacity(0.22), radius: 18, x: 0, y: 8)

                            Image("SquaredAway App Logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 64, height: 64)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }

                        VStack(spacing: 4) {
                            Text("Welcome Back")
                                .font(AppTheme.Typography.displayMedium)
                                .foregroundColor(AppTheme.Colors.textPrimary)

                            Text("Sign in to continue your mission")
                                .font(AppTheme.Typography.bodyMedium)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    }
                    .padding(.top, AppTheme.Spacing.xxl)
                    .padding(.bottom, AppTheme.Spacing.xl)

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
                                textContentType: .password,
                                errorMessage: authVM.passwordError
                            )

                            CheckboxRow(label: "Stay signed in", isChecked: $authVM.staySignedIn)
                                .padding(.top, AppTheme.Spacing.xs)

                            if let error = authVM.generalError {
                                ErrorBanner(message: error)
                            }

                            if let statusMessage = authVM.statusMessage {
                                LoginStatusBanner(
                                    message: statusMessage,
                                    color: AppTheme.Colors.success,
                                    icon: "checkmark.circle.fill"
                                )
                            }

                            if let resetMessage {
                                LoginStatusBanner(
                                    message: resetMessage,
                                    color: AppTheme.Colors.success,
                                    icon: "checkmark.circle.fill"
                                )
                            }

                            Divider()
                                .background(AppTheme.Colors.glassBorder)

                            PrimaryButton("Continue", isLoading: authVM.isLoading) {
                                Task { await authVM.signIn() }
                            }
                            .padding(.top, AppTheme.Spacing.xs)
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)

                    Button("Forgot password?") {
                        showForgotPasswordSheet = true
                    }
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.accentSecondary)
                    .padding(.top, AppTheme.Spacing.md)

                    LabelDivider(label: "New to SquaredAway?")
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.vertical, AppTheme.Spacing.lg)

                    SecondaryButton(title: "Create Account") {
                        authVM.clearErrors()
                        showSignup = true
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.bottom, AppTheme.Spacing.xxl)
                }
            }
            .opacity(contentOpacity)
            .offset(y: contentOffset)
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                contentOpacity = 1
                contentOffset = 0
            }
        }
        .sheet(isPresented: $showSignup) {
            SignupView()
                .environmentObject(authVM)
        }
        .sheet(isPresented: $showForgotPasswordSheet) {
            ForgotPasswordSheet(
                initialEmail: authVM.email,
                onSuccess: { message in
                    resetMessage = message
                }
            )
            .environmentObject(authVM)
        }
    }
}

private struct ForgotPasswordSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authVM: AuthViewModel

    let initialEmail: String
    let onSuccess: (String) -> Void

    @State private var email = ""
    @State private var localErrorMessage: String?
    @State private var successMessage: String?
    @State private var isSending = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.backgroundPrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        VStack(spacing: AppTheme.Spacing.sm) {
                            Image(systemName: "envelope.badge")
                                .font(.system(size: 34, weight: .semibold))
                                .foregroundColor(AppTheme.Colors.accentSecondary)

                            Text("Reset Password")
                                .font(AppTheme.Typography.displayMedium)
                                .foregroundColor(AppTheme.Colors.textPrimary)

                            Text("Enter your account email and we’ll send a reset link. Open that email on the same device so SquaredAway can return you to the new-password screen.")
                                .font(AppTheme.Typography.bodyMedium)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, AppTheme.Spacing.xl)

                        GlassCard(padding: AppTheme.Spacing.lg) {
                            VStack(spacing: AppTheme.Spacing.md) {
                                AuthTextField(
                                    placeholder: "Email address",
                                    icon: "envelope.fill",
                                    text: $email,
                                    keyboardType: .emailAddress,
                                    textContentType: .emailAddress,
                                    errorMessage: nil
                                )

                                if let localErrorMessage {
                                    ErrorBanner(message: localErrorMessage)
                                }

                                if let successMessage {
                                    LoginStatusBanner(
                                        message: successMessage,
                                        color: AppTheme.Colors.success,
                                        icon: "checkmark.circle.fill"
                                    )
                                }

                                PrimaryButton("Send Reset Email", isLoading: isSending) {
                                    Task { await sendPasswordReset() }
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
                    Button("Close") { dismiss() }
                        .foregroundColor(AppTheme.Colors.accentSecondary)
                }
            }
            .preferredColorScheme(.dark)
            .onAppear {
                email = initialEmail
                authVM.clearErrors()
            }
        }
    }

    private func sendPasswordReset() async {
        localErrorMessage = nil
        successMessage = nil
        isSending = true
        defer { isSending = false }

        do {
            try await authVM.requestPasswordReset(for: email)
            authVM.clearErrors()
            let message = "Reset email sent. If it lands in spam, mark it safe and open the link on this device to create a new password."
            successMessage = message
            onSuccess(message)
        } catch {
            localErrorMessage = error.localizedDescription
            authVM.clearErrors()
        }
    }
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
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}

private struct LoginStatusBanner: View {
    let message: String
    let color: Color
    let icon: String

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 15))

            Text(message)
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(color)
                .multilineTextAlignment(.leading)

            Spacer()
        }
        .padding(AppTheme.Spacing.sm)
        .background(color.opacity(0.08))
        .cornerRadius(AppTheme.Radius.sm)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        LoginView()
            .environmentObject(AuthViewModel())
            .preferredColorScheme(.dark)
    }
}
