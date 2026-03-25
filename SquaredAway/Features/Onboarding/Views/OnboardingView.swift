import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var authVM: AuthViewModel

    @State private var draft = OnboardingProfileDraft()
    @State private var currentStep = 0
    @State private var didPopulate = false

    private let totalSteps = 4

    var body: some View {
        ZStack {
            AppTheme.Colors.backgroundPrimary.ignoresSafeArea()

            VStack {
                Circle()
                    .fill(AppTheme.Colors.accentPrimary.opacity(0.14))
                    .frame(width: 360, height: 360)
                    .blur(radius: 90)
                    .offset(x: 110, y: -120)
                Spacer()
            }

            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.lg) {
                    header
                    progressHeader
                    stepContent
                    footer
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.xl)
            }
        }
        .task {
            if authVM.currentProfile == nil {
                await authVM.refreshProfile()
            }
        }
        .onAppear {
            populateDraftIfNeeded()
        }
        .onChange(of: authVM.currentProfile?.id) { _, _ in
            populateDraftIfNeeded(force: true)
        }
        .onChange(of: draft.branch) { _, newBranch in
            if !newBranch.rankOptions.contains(draft.rank) {
                draft.rank = ""
            }
            draft.mos = ""
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Complete Your Profile")
                .font(AppTheme.Typography.displayMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)

            Text("A few mission details unlock your dashboard, tailor the app to your service branch, and help you understand where growth is coming from.")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)

            GlassCard {
                HStack(spacing: AppTheme.Spacing.md) {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(AppTheme.Colors.accentSecondary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Signed in as")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textTertiary)
                        Text(authVM.currentUserEmail.isEmpty ? authVM.email : authVM.currentUserEmail)
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                    }

                    Spacer()
                }
            }
        }
    }

    private var progressHeader: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.sm) {
                ForEach(0..<totalSteps, id: \.self) { index in
                    Capsule()
                        .fill(index <= currentStep ? AppTheme.Colors.accentPrimary : AppTheme.Colors.glassBorder)
                        .frame(height: 6)
                }
            }

            HStack {
                Text(stepTitle)
                    .font(AppTheme.Typography.titleMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Spacer()
                Text("Step \(currentStep + 1) of \(totalSteps)")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case 0:
            identityStep
        case 1:
            serviceStep
        case 2:
            discoveryStep
        default:
            fitnessStep
        }
    }

    private var identityStep: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(spacing: AppTheme.Spacing.md) {
                AuthTextField(
                    placeholder: "First name",
                    icon: "person.fill",
                    text: $draft.firstName,
                    textContentType: .givenName,
                    autocapitalization: .words,
                    autocorrectionDisabled: false
                )

                AuthTextField(
                    placeholder: "Last name",
                    icon: "person.2.fill",
                    text: $draft.lastName,
                    textContentType: .familyName,
                    autocapitalization: .words,
                    autocorrectionDisabled: false
                )
            }
        }
    }

    private var serviceStep: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(spacing: AppTheme.Spacing.md) {
                MenuPickerField(
                    title: "Branch",
                    value: draft.branch.rawValue
                ) {
                    Picker("Branch", selection: $draft.branch) {
                        ForEach(MilitaryBranch.allCases, id: \.self) { branch in
                            Text(branch.rawValue).tag(branch)
                        }
                    }
                }

                MenuPickerField(
                    title: "Rank",
                    value: selectedRankLabel
                ) {
                    Picker("Rank", selection: $draft.rank) {
                        Text("Select rank").tag("")
                        ForEach(draft.branch.rankOptions, id: \.self) { rank in
                            Text(rank).tag(rank)
                        }
                    }
                }

                SearchableSelectionField(
                    title: "Common \(draft.branch.mosLabel) Options",
                    value: selectedSpecialtyLabel,
                    placeholder: "Search \(draft.branch.mosLabel)",
                    options: availableSpecialtyOptions,
                    selectedID: availableSpecialtyOptions.first(where: { $0.code == draft.mos })?.id,
                    optionTitle: { $0.displayName },
                    optionKeywords: { "\($0.code) \($0.title)" },
                    onClear: draft.mos.isEmpty ? nil : { draft.mos = "" }
                ) { specialty in
                    draft.mos = specialty.code
                }

                AuthTextField(
                    placeholder: "Or enter \(draft.branch.mosLabel) manually",
                    icon: draft.branch.icon,
                    text: $draft.mos,
                    autocapitalization: .characters
                )
            }
        }
    }

    private var fitnessStep: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(spacing: AppTheme.Spacing.md) {
                HStack(spacing: AppTheme.Spacing.md) {
                    AuthTextField(
                        placeholder: "Height cm",
                        icon: "ruler",
                        text: $draft.heightCm,
                        keyboardType: .decimalPad
                    )

                    AuthTextField(
                        placeholder: "Weight kg",
                        icon: "scalemass.fill",
                        text: $draft.weightKg,
                        keyboardType: .decimalPad
                    )
                }

                MenuPickerField(
                    title: "Fitness goal",
                    value: draft.fitnessGoal.rawValue
                ) {
                    Picker("Fitness Goal", selection: $draft.fitnessGoal) {
                        ForEach(FitnessGoal.allCases, id: \.self) { goal in
                            Text(goal.rawValue).tag(goal)
                        }
                    }
                }

                HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(AppTheme.Colors.success)
                    Text("You can refine these details later. Completing onboarding unlocks your dashboard immediately.")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    Spacer()
                }
                .padding(.top, AppTheme.Spacing.xs)
            }
        }
    }

    private var discoveryStep: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(spacing: AppTheme.Spacing.md) {
                MenuPickerField(
                    title: "How did you hear about SquaredAway?",
                    value: draft.discoverySource.rawValue
                ) {
                    Picker("Discovery Source", selection: $draft.discoverySource) {
                        ForEach(DiscoverySource.allCases, id: \.self) { source in
                            Text(source.rawValue).tag(source)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("Anything helpful to know?")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textTertiary)

                    TextEditor(text: $draft.discoveryNotes)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 140)
                        .padding(AppTheme.Spacing.sm)
                        .background(AppTheme.Colors.backgroundCard)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                                .stroke(AppTheme.Colors.glassBorder, lineWidth: 1)
                        )
                        .cornerRadius(AppTheme.Radius.md)
                }

                HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(AppTheme.Colors.accentSecondary)
                    Text("This is optional but useful if you want to see which communities, referrals, or channels are driving signups.")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    Spacer()
                }
                .padding(.top, AppTheme.Spacing.xs)
            }
        }
    }

    private var footer: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            if let generalError = authVM.generalError {
                InlineErrorBanner(message: generalError)
            }

            PrimaryButton(primaryButtonTitle, isLoading: authVM.isLoading) {
                if currentStep < totalSteps - 1 {
                    withAnimation(AppTheme.Animation.spring) {
                        currentStep += 1
                    }
                } else {
                    Task { await authVM.completeOnboarding(with: draft) }
                }
            }

            HStack(spacing: AppTheme.Spacing.md) {
                if currentStep > 0 {
                    SecondaryButton(title: "Back") {
                        withAnimation(AppTheme.Animation.standard) {
                            currentStep -= 1
                        }
                    }
                }

                Button("Sign Out") {
                    Task { await authVM.signOut() }
                }
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Colors.textTertiary)
                .frame(maxWidth: .infinity, alignment: currentStep > 0 ? .trailing : .center)
            }
        }
    }

    private var stepTitle: String {
        switch currentStep {
        case 0:
            return "Identity"
        case 1:
            return "Service Details"
        case 2:
            return "Discovery"
        default:
            return "Fitness Baseline"
        }
    }

    private var primaryButtonTitle: String {
        currentStep == totalSteps - 1 ? "Finish Onboarding" : "Continue"
    }

    private var selectedRankLabel: String {
        draft.rank.isEmpty ? "Select rank" : draft.rank
    }

    private var selectedSpecialtyLabel: String {
        guard !draft.mos.isEmpty else { return "Select \(draft.branch.mosLabel)" }
        if let specialty = availableSpecialtyOptions.first(where: { $0.code == draft.mos }) {
            return specialty.displayName
        }
        return draft.mos
    }

    private var availableSpecialtyOptions: [MilitarySpecialty] {
        let options = draft.branch.specialtyOptions
        guard !draft.mos.isEmpty, !options.contains(where: { $0.code == draft.mos }) else {
            return options
        }

        return [MilitarySpecialty(code: draft.mos, title: "Current selection")] + options
    }

    private func populateDraftIfNeeded(force: Bool = false) {
        guard !didPopulate || force else { return }
        didPopulate = true
        if let profile = authVM.currentProfile {
            draft.firstName = profile.firstName
            draft.lastName = profile.lastName
            draft.branch = profile.branch ?? .army
            draft.rank = profile.rank ?? ""
            draft.mos = profile.mos ?? ""
            draft.discoverySource = profile.discoverySource ?? .appStore
            draft.discoveryNotes = profile.discoveryNotes ?? ""
            draft.heightCm = profile.heightCm.map { String(Int($0)) } ?? ""
            draft.weightKg = profile.weightKg.map { String(Int($0)) } ?? ""
            draft.fitnessGoal = profile.fitnessGoal ?? .improveScore
        }
    }
}

private struct InlineErrorBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(AppTheme.Colors.error)
            Text(message)
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Colors.error)
            Spacer()
        }
        .padding(AppTheme.Spacing.sm)
        .background(AppTheme.Colors.error.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                .stroke(AppTheme.Colors.error.opacity(0.24), lineWidth: 1)
        )
        .cornerRadius(AppTheme.Radius.sm)
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AuthViewModel())
        .preferredColorScheme(.dark)
}
