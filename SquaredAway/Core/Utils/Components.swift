import SwiftUI

struct PrimaryButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void

    init(_ title: String, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .scaleEffect(0.9)
                } else {
                    Text(title)
                        .font(AppTheme.Typography.button)
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(AppTheme.Gradients.primaryButton)
            .cornerRadius(AppTheme.Radius.lg)
            .shadow(color: AppTheme.Colors.accentPrimary.opacity(0.4), radius: 12, x: 0, y: 6)
        }
        .disabled(isLoading)
        .scaleEffect(isLoading ? 0.98 : 1.0)
        .animation(AppTheme.Animation.spring, value: isLoading)
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTheme.Typography.button)
                .foregroundColor(AppTheme.Colors.accentSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(AppTheme.Colors.glassBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                        .stroke(AppTheme.Colors.accentPrimary.opacity(0.3), lineWidth: 1)
                )
                .cornerRadius(AppTheme.Radius.lg)
        }
    }
}

struct AuthTextField: View {
    let placeholder: String
    let icon: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var errorMessage: String? = nil
    var autocapitalization: TextInputAutocapitalization? = .never
    var autocorrectionDisabled = true

    @State private var showPassword = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: icon)
                    .foregroundColor(isFocused ? AppTheme.Colors.accentSecondary : AppTheme.Colors.textTertiary)
                    .frame(width: 20)
                    .animation(AppTheme.Animation.standard, value: isFocused)

                Group {
                    if isSecure && !showPassword {
                        SecureField(placeholder, text: $text)
                            .textContentType(textContentType)
                    } else {
                        TextField(placeholder, text: $text)
                            .keyboardType(keyboardType)
                            .textContentType(textContentType)
                    }
                }
                .font(AppTheme.Typography.bodyLarge)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .focused($isFocused)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled(autocorrectionDisabled)
                .tint(AppTheme.Colors.accentSecondary)
                .placeholder(when: text.isEmpty) {
                    Text(placeholder)
                        .foregroundColor(AppTheme.Colors.textPlaceholder)
                        .font(AppTheme.Typography.bodyLarge)
                }

                if isSecure {
                    Button {
                        showPassword.toggle()
                    } label: {
                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(AppTheme.Colors.textTertiary)
                            .frame(width: 24)
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .frame(height: 52)
            .background(AppTheme.Colors.backgroundCard)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                    .stroke(
                        isFocused
                            ? AppTheme.Colors.accentPrimary.opacity(0.6)
                            : (errorMessage != nil ? AppTheme.Colors.error.opacity(0.6) : AppTheme.Colors.glassBorder),
                        lineWidth: 1
                    )
            )
            .cornerRadius(AppTheme.Radius.md)

            if let errorMessage {
                Text(errorMessage)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.error)
                    .padding(.horizontal, AppTheme.Spacing.xs)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(AppTheme.Animation.standard, value: errorMessage)
    }
}

struct GlassCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = AppTheme.Spacing.md

    init(padding: CGFloat = AppTheme.Spacing.md, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.padding = padding
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                        .fill(AppTheme.Colors.backgroundCard)
                    RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                        .fill(AppTheme.Colors.glassTint)
                    RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                        .stroke(AppTheme.Colors.glassBorder, lineWidth: 1)
                }
            )
            .shadow(
                color: AppTheme.Colors.accentPrimary.opacity(0.08),
                radius: AppTheme.Shadows.cardRadius,
                x: 0,
                y: AppTheme.Shadows.cardY
            )
    }
}

struct CheckboxRow: View {
    let label: String
    @Binding var isChecked: Bool

    var body: some View {
        Button {
            isChecked.toggle()
        } label: {
            HStack(spacing: AppTheme.Spacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(
                            isChecked ? AppTheme.Colors.accentPrimary : AppTheme.Colors.glassBorder,
                            lineWidth: 1.5
                        )
                        .frame(width: 20, height: 20)

                    if isChecked {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppTheme.Colors.accentPrimary)
                            .frame(width: 20, height: 20)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .animation(AppTheme.Animation.spring, value: isChecked)

                Text(label)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)

                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}

struct BranchBadge: View {
    let branch: String
    let rank: String

    var body: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: branchIcon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(AppTheme.Colors.accentSecondary)

            Text("\(rank) · \(branch)")
                .font(AppTheme.Typography.label)
                .foregroundColor(AppTheme.Colors.accentSecondary)
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(AppTheme.Colors.accentPrimary.opacity(0.15))
        .cornerRadius(AppTheme.Radius.full)
        .overlay(
            Capsule()
                .stroke(AppTheme.Colors.accentPrimary.opacity(0.3), lineWidth: 1)
        )
    }

    private var branchIcon: String {
        switch branch.lowercased() {
        case "army":
            return "shield.fill"
        case "navy":
            return "anchor"
        case "air force":
            return "airplane"
        case "marines":
            return "star.fill"
        case "space force":
            return "sparkles"
        default:
            return "shield.fill"
        }
    }
}

struct LabelDivider: View {
    let label: String

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Rectangle()
                .fill(AppTheme.Colors.glassBorder)
                .frame(height: 1)

            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.textTertiary)
                .fixedSize()

            Rectangle()
                .fill(AppTheme.Colors.glassBorder)
                .frame(height: 1)
        }
    }
}

struct MenuPickerField<PickerContent: View>: View {
    let title: String
    let value: String
    @ViewBuilder let picker: () -> PickerContent

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textTertiary)
                Text(value)
                    .font(AppTheme.Typography.bodyLarge)
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }

            Spacer()

            picker()
                .labelsHidden()
                .tint(AppTheme.Colors.accentSecondary)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .frame(height: 56)
        .background(AppTheme.Colors.backgroundCard)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                .stroke(AppTheme.Colors.glassBorder, lineWidth: 1)
        )
        .cornerRadius(AppTheme.Radius.md)
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: .leading) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }

    func squaredBackground() -> some View {
        background(AppTheme.Colors.backgroundPrimary.ignoresSafeArea())
    }

    func cardStyle() -> some View {
        background(AppTheme.Colors.backgroundCard)
            .cornerRadius(AppTheme.Radius.xl)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                    .stroke(AppTheme.Colors.glassBorder, lineWidth: 1)
            )
    }
}
