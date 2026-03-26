import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @State private var showSignup = false
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
                        Task { await sendPasswordReset() }
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
    }

    private func sendPasswordReset() async {
        resetMessage = nil

        do {
            try await authVM.requestPasswordReset(for: authVM.email)
            resetMessage = "Recovery email sent. Open the link on this device to finish resetting your password."
        } catch {
            resetMessage = nil
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
