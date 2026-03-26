import SwiftUI

struct BranchLockWarning: View {
    @Binding var isPresented: Bool
    let selectedBranch: MilitaryBranch
    let onConfirm: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }

            VStack(spacing: AppTheme.Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.warning.opacity(0.12))
                        .frame(width: 72, height: 72)

                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.warning)
                }

                VStack(spacing: AppTheme.Spacing.xs) {
                    Text("Branch Is Permanent")
                        .font(AppTheme.Typography.titleLarge)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("Once onboarding is completed, your branch is locked to this account. If you ever need a different branch, you will need a new account.")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: selectedBranch.icon)
                        .foregroundColor(Color(hex: selectedBranch.color))
                    Text(selectedBranch.rawValue)
                        .font(AppTheme.Typography.titleSmall)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(Color(hex: selectedBranch.color).opacity(0.12))
                .overlay(
                    Capsule()
                        .stroke(Color(hex: selectedBranch.color).opacity(0.25), lineWidth: 1)
                )
                .cornerRadius(AppTheme.Radius.full)

                VStack(spacing: AppTheme.Spacing.sm) {
                    Button {
                        isPresented = false
                        onConfirm()
                    } label: {
                        Text("Confirm - I'm \(selectedBranch.rawValue)")
                            .font(AppTheme.Typography.button)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color(hex: selectedBranch.color))
                            .cornerRadius(AppTheme.Radius.lg)
                    }

                    Button {
                        isPresented = false
                    } label: {
                        Text("Go Back and Change Branch")
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
            }
            .padding(AppTheme.Spacing.xl)
            .background(AppTheme.Colors.backgroundCard)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.xxl)
                    .stroke(AppTheme.Colors.glassBorder, lineWidth: 1)
            )
            .cornerRadius(AppTheme.Radius.xxl)
            .padding(.horizontal, AppTheme.Spacing.md)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }
}

struct BranchLockedBanner: View {
    let branch: MilitaryBranch

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: branch.icon)
                .foregroundColor(Color(hex: branch.color))
                .frame(width: 36, height: 36)
                .background(Color(hex: branch.color).opacity(0.12))
                .cornerRadius(AppTheme.Radius.sm)

            VStack(alignment: .leading, spacing: 2) {
                Text(branch.rawValue)
                    .font(AppTheme.Typography.titleSmall)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Text("Branch locked - new account required to change")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }

            Spacer()

            Image(systemName: "lock.fill")
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.backgroundCard)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                .stroke(AppTheme.Colors.glassBorder, lineWidth: 1)
        )
        .cornerRadius(AppTheme.Radius.lg)
    }
}
