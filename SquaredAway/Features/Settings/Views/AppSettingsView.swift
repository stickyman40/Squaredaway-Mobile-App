import SwiftUI
import UIKit
import UserNotifications

struct AppSettingsView: View {
    @EnvironmentObject private var authVM: AuthViewModel

    @State private var draft = ProfileSettingsDraft()
    @State private var didPopulate = false
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var unreadInboxCount = 0
    @AppStorage(NotificationPreferences.milestonesEnabledKey) private var milestonesNotificationsEnabled = true
    @AppStorage(NotificationPreferences.readinessEnabledKey) private var readinessNotificationsEnabled = true
    @AppStorage(NotificationPreferences.activityEnabledKey) private var activityNotificationsEnabled = true
    @State private var pendingEmail = ""
    @State private var securityMessage: String?
    @State private var securityError: String?
    @State private var showDeleteSheet = false
    @State private var sensitiveActionToConfirm: AuthViewModel.SensitiveAccountAction?
    @State private var didLoadRemoteNotificationPreferences = false
    @State private var notificationPreferencesError: String?
    @State private var notificationPreferencesMessage: String?
    @State private var notificationDiagnostics: NotificationDiagnosticsSummary?
    @State private var isRunningNotificationDiagnostics = false
    @State private var isRunningNotificationProbe = false
    @State private var diagnosticsCopyMessage: String?
    @State private var accountSummaryCopyMessage: String?

    private let reminderService = ReminderService.shared
    private let notificationService = NotificationService.shared
    private let notificationPreferencesService = NotificationPreferencesService.shared
    private let privacyPolicyURL = URL(string: "https://getsquaredaway.app/privacy")!
    private let termsURL = URL(string: "https://getsquaredaway.app/terms")!
    private let supportURL = URL(string: "mailto:support@getsquaredaway.app")!

    var body: some View {
        ZStack {
            AppTheme.Colors.backgroundPrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    accountCard
                    profileCard
                    securityCard
                    notificationsCard
                    legalSupportCard
                    accountActionsCard
                    dangerZoneCard
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.lg)
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            populateDraftIfNeeded()
            Task {
                await loadUnreadCount()
                await loadRemoteNotificationPreferences()
            }
        }
        .onChange(of: authVM.currentProfile?.id) { _, _ in
            populateDraftIfNeeded(force: true)
        }
        .onChange(of: authVM.isSensitiveActionUnlocked) { _, isUnlocked in
            if isUnlocked {
                securityError = nil
                securityMessage = "Identity confirmed. Continue with your sensitive account update."
                sensitiveActionToConfirm = nil
            }
        }
        .onChange(of: draft.branch) { _, newBranch in
            if !newBranch.rankOptions.contains(draft.rank) {
                draft.rank = ""
            }
            draft.mos = ""
        }
        .onChange(of: milestonesNotificationsEnabled) { _, _ in
            Task { await persistNotificationPreferencesIfReady() }
        }
        .onChange(of: readinessNotificationsEnabled) { _, _ in
            Task { await persistNotificationPreferencesIfReady() }
        }
        .onChange(of: activityNotificationsEnabled) { _, _ in
            Task { await persistNotificationPreferencesIfReady() }
        }
        .task {
            notificationStatus = await reminderService.authorizationStatus()
            await loadUnreadCount()
            await loadRemoteNotificationPreferences()
        }
        .sheet(isPresented: $showDeleteSheet) {
            DeleteAccountSheet(isLoading: authVM.isLoading) {
                await requestAccountDeletionConfirmation()
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $sensitiveActionToConfirm) { action in
            SensitiveActionConfirmationSheet(
                action: action,
                currentEmail: authVM.currentUserEmail,
                isLoading: authVM.isLoading,
                isUnlocked: authVM.isSensitiveActionUnlocked,
                errorMessage: securityError
            ) {
                await beginSensitiveActionConfirmation(for: action)
            }
        }
    }

    private var accountCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Account")
                            .font(AppTheme.Typography.titleMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)

                        Text(accountDisplayName)
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .font(.system(size: 26))
                        .foregroundColor(AppTheme.Colors.accentSecondary)
                }

                Text("Signed in as \(authVM.currentUserEmail.isEmpty ? "unknown" : authVM.currentUserEmail)")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textTertiary)

                if let profile = authVM.currentProfile,
                   let branch = profile.branch?.rawValue,
                   let rank = profile.rank,
                   !rank.isEmpty {
                    BranchBadge(branch: branch, rank: rank)
                }

                HStack(spacing: AppTheme.Spacing.md) {
                    accountMetric(title: "Member Since", value: memberSinceText)
                    accountMetric(title: "Inbox", value: unreadInboxCount == 0 ? "Clear" : "\(unreadInboxCount) unread")
                }
            }
        }
    }

    private var quickAccessCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("Quick Access")
                    .font(AppTheme.Typography.titleMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                NavigationLink {
                    TrackerView()
                        .environmentObject(authVM)
                } label: {
                    SettingsRow(
                        title: "Tracker",
                        subtitle: "Jump into assignment details and milestone tracking."
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    PCSView()
                        .environmentObject(authVM)
                } label: {
                    SettingsRow(
                        title: "PCS",
                        subtitle: "Open move planning and logistics checkpoints."
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    BenefitsView()
                        .environmentObject(authVM)
                } label: {
                    SettingsRow(
                        title: "Benefits",
                        subtitle: "Review benefits readiness and follow-ups."
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    NotificationsView()
                        .environmentObject(authVM)
                } label: {
                    SettingsRow(
                        title: "Notifications Inbox",
                        subtitle: unreadInboxCount == 0 ? "Review recent app alerts." : "\(unreadInboxCount) unread items waiting."
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var profileCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("Edit Profile")
                    .font(AppTheme.Typography.titleMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text("Update the basics the app uses for personalization and branch-specific recommendations.")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)

                HStack(spacing: AppTheme.Spacing.md) {
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

                if authVM.currentProfile?.branchLocked == true || authVM.currentProfile?.onboardingComplete == true {
                    BranchLockedBanner(branch: authVM.currentProfile?.branch ?? draft.branch)
                } else {
                    MenuPickerField(title: "Branch", value: draft.branch.rawValue) {
                        Picker("Branch", selection: $draft.branch) {
                            ForEach(MilitaryBranch.allCases, id: \.self) { branch in
                                Text(branch.rawValue).tag(branch)
                            }
                        }
                    }
                }

                MenuPickerField(title: "Rank", value: selectedRankLabel) {
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

                MenuPickerField(title: "Fitness Goal", value: draft.fitnessGoal.rawValue) {
                    Picker("Fitness Goal", selection: $draft.fitnessGoal) {
                        ForEach(FitnessGoal.allCases, id: \.self) { goal in
                            Text(goal.rawValue).tag(goal)
                        }
                    }
                }

                if let generalError = authVM.generalError {
                    SettingsBanner(message: generalError, color: AppTheme.Colors.error, icon: "exclamationmark.triangle.fill")
                }

                PrimaryButton("Save Profile", isLoading: authVM.isLoading) {
                    Task { await authVM.updateProfileSettings(with: draft) }
                }
            }
        }
    }

    private var preferencesCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("Preferences")
                    .font(AppTheme.Typography.titleMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                NavigationLink {
                    ReminderSettingsView()
                        .environmentObject(authVM)
                } label: {
                    SettingsRow(
                        title: "Reminder Settings",
                        subtitle: "Adjust notification preferences and schedules."
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    NotificationsView()
                        .environmentObject(authVM)
                } label: {
                    SettingsRow(
                        title: unreadInboxCount == 0 ? "Notifications Inbox" : "Notifications Inbox (\(unreadInboxCount))",
                        subtitle: "Review in-app alerts from your account."
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var securityCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("Security")
                    .font(AppTheme.Typography.titleMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                if authVM.isSensitiveActionUnlocked {
                    SettingsBanner(
                        message: "Identity confirmed. Sensitive account actions are unlocked for the next few minutes.",
                        color: AppTheme.Colors.success,
                        icon: "checkmark.shield.fill"
                    )
                }

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("Current email")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textTertiary)

                    Text(authVM.currentUserEmail.isEmpty ? "No email on file" : authVM.currentUserEmail)
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }

                AuthTextField(
                    placeholder: "New email",
                    icon: "envelope.fill",
                    text: $pendingEmail,
                    keyboardType: .emailAddress,
                    textContentType: .emailAddress
                )

                PrimaryButton(authVM.isSensitiveActionUnlocked ? "Send Email Change Confirmation" : "Confirm Identity to Change Email", isLoading: authVM.isLoading) {
                    Task { await handleEmailChangeTap() }
                }

                Text("We’ll send a verification email so the address change can be approved before it takes effect.")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textTertiary)

                LabelDivider(label: "Password")

                Text("For security, password changes are handled through a reset link sent to your email.")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)

                PrimaryButton(authVM.isSensitiveActionUnlocked ? "Send Password Reset Email" : "Confirm Identity to Change Password", isLoading: authVM.isLoading) {
                    Task { await handlePasswordChangeTap() }
                }

                if let securityError {
                    SettingsBanner(message: securityError, color: AppTheme.Colors.error, icon: "exclamationmark.triangle.fill")
                }

                if let securityMessage {
                    SettingsBanner(message: securityMessage, color: AppTheme.Colors.success, icon: "checkmark.circle.fill")
                }
            }
        }
    }

    private var notificationsCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("Notifications")
                    .font(AppTheme.Typography.titleMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text(notificationStatusLabel)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)

                if unreadInboxCount > 0 {
                    Text("\(unreadInboxCount) unread inbox item\(unreadInboxCount == 1 ? "" : "s").")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.accentSecondary)
                }

                if let notificationPreferencesError {
                    SettingsBanner(message: notificationPreferencesError, color: AppTheme.Colors.error, icon: "exclamationmark.triangle.fill")
                }

                if let notificationPreferencesMessage {
                    SettingsBanner(message: notificationPreferencesMessage, color: AppTheme.Colors.success, icon: "checkmark.circle.fill")
                }

                LabelDivider(label: "Inbox Event Types")

                notificationToggle(
                    title: AppNotificationCategory.milestones.title,
                    subtitle: AppNotificationCategory.milestones.subtitle,
                    isOn: $milestonesNotificationsEnabled
                )

                notificationToggle(
                    title: AppNotificationCategory.readiness.title,
                    subtitle: AppNotificationCategory.readiness.subtitle,
                    isOn: $readinessNotificationsEnabled
                )

                notificationToggle(
                    title: AppNotificationCategory.activity.title,
                    subtitle: AppNotificationCategory.activity.subtitle,
                    isOn: $activityNotificationsEnabled
                )

                NavigationLink {
                    ReminderSettingsView()
                        .environmentObject(authVM)
                } label: {
                    SettingsRow(
                        title: "Reminder Settings",
                        subtitle: "Adjust reminder schedules and notification preferences."
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    NotificationsView()
                        .environmentObject(authVM)
                } label: {
                    SettingsRow(
                        title: unreadInboxCount == 0 ? "Notifications Inbox" : "Notifications Inbox (\(unreadInboxCount))",
                        subtitle: "Review recent app alerts."
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var accountActionsCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("App & Account")
                    .font(AppTheme.Typography.titleMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                SettingsRow(
                    title: "Version",
                    subtitle: "SquaredAway \(appVersionText)"
                )

                SecondaryButton(title: "Sign Out") {
                    Task { await authVM.signOut() }
                }
            }
        }
    }

    private var legalSupportCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("Legal & Support")
                    .font(AppTheme.Typography.titleMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Link(destination: privacyPolicyURL) {
                    SettingsRow(
                        title: "Privacy Policy",
                        subtitle: "See how your account and readiness data are handled."
                    )
                }
                .buttonStyle(.plain)

                Link(destination: termsURL) {
                    SettingsRow(
                        title: "Terms of Use",
                        subtitle: "Review the app terms and account expectations."
                    )
                }
                .buttonStyle(.plain)

                Link(destination: supportURL) {
                    SettingsRow(
                        title: "Contact Support",
                        subtitle: "Email support if you need help with your account."
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var notificationDiagnosticsCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack {
                    Text("Notification Diagnostics")
                        .font(AppTheme.Typography.titleMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)

                    Spacer()

                    if isRunningNotificationDiagnostics {
                        ProgressView()
                            .tint(AppTheme.Colors.accentSecondary)
                    }
                }

                if let notificationDiagnostics {
                    DiagnosticsRow(title: "Device Permission", status: notificationDiagnostics.permission)
                    DiagnosticsRow(title: "Inbox Table Access", status: notificationDiagnostics.inbox)
                    DiagnosticsRow(title: "Remote Preferences Row", status: notificationDiagnostics.preferences)
                    DiagnosticsRow(title: "Schema / Trigger Readiness", status: notificationDiagnostics.pipeline)

                    Text("Last checked \(notificationDiagnostics.checkedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                } else {
                    Text("Run diagnostics to verify the database-backed inbox pipeline.")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }

                if let diagnosticsCopyMessage {
                    SettingsBanner(message: diagnosticsCopyMessage, color: AppTheme.Colors.success, icon: "doc.on.doc.fill")
                }

                SecondaryButton(title: "Run Diagnostics") {
                    Task { await runNotificationDiagnostics() }
                }
                .disabled(isRunningNotificationDiagnostics)
                .opacity(isRunningNotificationDiagnostics ? 0.5 : 1)

                SecondaryButton(title: isRunningNotificationProbe ? "Running Probe..." : "Run End-to-End Probe") {
                    Task { await runNotificationProbe() }
                }
                .disabled(isRunningNotificationProbe)
                .opacity(isRunningNotificationProbe ? 0.5 : 1)

                SecondaryButton(title: "Copy Diagnostics Summary") {
                    copyDiagnosticsSummary()
                }
                .disabled(notificationDiagnostics == nil)
                .opacity(notificationDiagnostics == nil ? 0.5 : 1)
            }
        }
    }

    private var dangerZoneCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("Danger Zone")
                    .font(AppTheme.Typography.titleMedium)
                    .foregroundColor(AppTheme.Colors.error)

                Text("Delete your account, profile, and linked readiness data from Supabase.")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)

                Button {
                    Task { await handleDeleteAccountTap() }
                } label: {
                    Text(authVM.isSensitiveActionUnlocked ? "Delete Account" : "Confirm Identity to Delete Account")
                        .font(AppTheme.Typography.button)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(AppTheme.Colors.error)
                        .cornerRadius(AppTheme.Radius.lg)
                }
            }
        }
    }

    private func populateDraftIfNeeded(force: Bool = false) {
        guard !didPopulate || force else { return }
        didPopulate = true

        if let profile = authVM.currentProfile {
            draft = ProfileSettingsDraft(
                firstName: profile.firstName,
                lastName: profile.lastName,
                branch: profile.branch ?? .army,
                rank: profile.rank ?? "",
                mos: profile.mos ?? "",
                discoverySource: profile.discoverySource ?? .appStore,
                discoveryNotes: profile.discoveryNotes ?? "",
                heightCm: profile.heightCm.map { $0.rounded() == $0 ? "\(Int($0))" : String(format: "%.1f", $0) } ?? "",
                weightKg: profile.weightKg.map { $0.rounded() == $0 ? "\(Int($0))" : String(format: "%.1f", $0) } ?? "",
                fitnessGoal: profile.fitnessGoal ?? .improveScore
            )
        }
    }

    private var notificationStatusLabel: String {
        switch notificationStatus {
        case .authorized, .provisional, .ephemeral:
            return "Allowed. Daily workout, meal, and board reminders are available."
        case .denied:
            return "Blocked in iPhone Settings. Reminder changes will not deliver notifications."
        case .notDetermined:
            return "Not requested yet. Permission will be requested when reminders are enabled."
        @unknown default:
            return "Notification status unavailable."
        }
    }

    private var accountDisplayName: String {
        let firstName = draft.firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let lastName = draft.lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let fullName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
        return fullName.isEmpty ? "SquaredAway member" : fullName
    }

    private var memberSinceText: String {
        guard let createdAt = authVM.currentProfile?.createdAt else { return "Recently" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: createdAt)
    }

    private var appVersionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
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

    private func requestEmailChange() async {
        securityError = nil
        securityMessage = nil

        do {
            try await authVM.requestEmailChange(to: pendingEmail)
            securityMessage = "Email change requested. Check your inbox to confirm it."
            pendingEmail = ""
            authVM.clearSensitiveActionConfirmation()
        } catch {
            securityError = authVM.generalError ?? error.localizedDescription
        }
    }

    private func sendPasswordReset() async {
        securityError = nil
        securityMessage = nil

        do {
            try await authVM.sendPasswordResetToCurrentEmail()
            securityMessage = "Password reset email sent. Open it on this device to create a new password."
            authVM.clearSensitiveActionConfirmation()
        } catch {
            securityError = authVM.generalError ?? error.localizedDescription
        }
    }

    private func beginSensitiveActionConfirmation(for action: AuthViewModel.SensitiveAccountAction) async {
        securityError = nil
        securityMessage = nil

        do {
            try await authVM.beginSensitiveActionConfirmation(for: action)
            securityMessage = "Check \(authVM.currentUserEmail) for the secure confirmation link, then open it on this device to continue."
            sensitiveActionToConfirm = nil
        } catch {
            securityError = authVM.generalError ?? error.localizedDescription
        }
    }

    private func handleEmailChangeTap() async {
        if authVM.isSensitiveActionUnlocked {
            await requestEmailChange()
        } else {
            securityError = nil
            securityMessage = nil
            sensitiveActionToConfirm = .emailChange
        }
    }

    private func handlePasswordChangeTap() async {
        if authVM.isSensitiveActionUnlocked {
            await sendPasswordReset()
        } else {
            securityError = nil
            securityMessage = nil
            sensitiveActionToConfirm = .passwordChange
        }
    }

    private func handleDeleteAccountTap() async {
        if authVM.isSensitiveActionUnlocked {
            showDeleteSheet = true
        } else {
            securityError = nil
            securityMessage = nil
            sensitiveActionToConfirm = .deleteAccount
        }
    }

    private func requestAccountDeletionConfirmation() async {
        securityError = nil
        securityMessage = nil

        do {
            try await authVM.requestAccountDeletionConfirmation()
            showDeleteSheet = false
            authVM.clearSensitiveActionConfirmation()
            securityMessage = "Delete confirmation email sent. Open that link on this device to permanently remove the account."
        } catch {
            securityError = authVM.generalError ?? error.localizedDescription
        }
    }

    private func loadUnreadCount() async {
        guard let userId = authVM.currentUserId else { return }

        unreadInboxCount = (try? await notificationService.unreadCount(userId: userId)) ?? 0
    }

    private func loadRemoteNotificationPreferences() async {
        guard let userId = authVM.currentUserId else { return }

        notificationPreferencesError = nil
        didLoadRemoteNotificationPreferences = false

        do {
            if let preferences = try await notificationPreferencesService.fetchPreferences(userId: userId) {
                milestonesNotificationsEnabled = preferences.milestonesEnabled
                readinessNotificationsEnabled = preferences.readinessEnabled
                activityNotificationsEnabled = preferences.activityEnabled
            }
            didLoadRemoteNotificationPreferences = true
        } catch {
            notificationPreferencesError = "Couldn't load notification preferences."
        }
    }

    private func persistNotificationPreferencesIfReady() async {
        guard didLoadRemoteNotificationPreferences else { return }
        guard let userId = authVM.currentUserId else { return }

        notificationPreferencesError = nil
        notificationPreferencesMessage = nil

        let record = NotificationPreferenceRecord(
            userId: userId,
            milestonesEnabled: milestonesNotificationsEnabled,
            readinessEnabled: readinessNotificationsEnabled,
            activityEnabled: activityNotificationsEnabled,
            createdAt: Date(),
            updatedAt: Date()
        )

        do {
            try await notificationPreferencesService.updatePreferences(record)
            notificationPreferencesMessage = "Inbox preferences synced."
        } catch {
            notificationPreferencesError = "Couldn't save notification preferences."
        }
    }

    private func runNotificationDiagnostics() async {
        guard let userId = authVM.currentUserId else { return }

        isRunningNotificationDiagnostics = true
        diagnosticsCopyMessage = nil
        defer { isRunningNotificationDiagnostics = false }

        let latestPermissionStatus = await reminderService.authorizationStatus()
        notificationStatus = latestPermissionStatus

        let permissionResult: NotificationDiagnosticStatus
        switch latestPermissionStatus {
        case .authorized, .provisional, .ephemeral:
            permissionResult = .success("Notifications allowed on this device.")
        case .notDetermined:
            permissionResult = .warning("Permission not requested yet.")
        case .denied:
            permissionResult = .warning("Notifications blocked in iPhone Settings.")
        @unknown default:
            permissionResult = .warning("Permission state unavailable.")
        }

        let inboxResult: NotificationDiagnosticStatus
        do {
            _ = try await notificationService.fetchNotifications(userId: userId)
            inboxResult = .success("Notifications table is reachable.")
        } catch {
            inboxResult = .error("Couldn't read the notifications table.")
        }

        let preferencesResult: NotificationDiagnosticStatus
        let pipelineResult: NotificationDiagnosticStatus
        do {
            if try await notificationPreferencesService.fetchPreferences(userId: userId) != nil {
                preferencesResult = .success("Remote notification preferences row exists.")
                pipelineResult = .success("Updated schema looks applied for this account.")
            } else {
                preferencesResult = .warning("Preferences row missing for this account.")
                pipelineResult = .warning("Re-run the updated `supabase_schema.sql` to backfill notification preferences.")
            }
        } catch {
            preferencesResult = .error("Couldn't read remote notification preferences.")
            pipelineResult = .error("Database-backed notification pipeline could not be verified.")
        }

        notificationDiagnostics = NotificationDiagnosticsSummary(
            checkedAt: Date(),
            permission: permissionResult,
            inbox: inboxResult,
            preferences: preferencesResult,
            pipeline: pipelineResult
        )
    }

    private func runNotificationProbe() async {
        isRunningNotificationProbe = true
        diagnosticsCopyMessage = nil
        defer { isRunningNotificationProbe = false }

        do {
            let result = try await notificationService.runPipelineProbe()
            await loadUnreadCount()

            let pipelineStatus: NotificationDiagnosticStatus
            switch result.status {
            case "created":
                pipelineStatus = .success(result.message)
            case "skipped":
                pipelineStatus = .warning(result.message)
            default:
                pipelineStatus = .warning("Probe returned an unexpected status.")
            }

            if let existing = notificationDiagnostics {
                notificationDiagnostics = NotificationDiagnosticsSummary(
                    checkedAt: Date(),
                    permission: existing.permission,
                    inbox: existing.inbox,
                    preferences: existing.preferences,
                    pipeline: pipelineStatus
                )
            } else {
                notificationDiagnostics = NotificationDiagnosticsSummary(
                    checkedAt: Date(),
                    permission: .warning("Run diagnostics first."),
                    inbox: .warning("Run diagnostics first."),
                    preferences: .warning("Run diagnostics first."),
                    pipeline: pipelineStatus
                )
            }
        } catch {
            let pipelineStatus = NotificationDiagnosticStatus.error("Probe failed. Apply the updated schema and try again.")
            if let existing = notificationDiagnostics {
                notificationDiagnostics = NotificationDiagnosticsSummary(
                    checkedAt: Date(),
                    permission: existing.permission,
                    inbox: existing.inbox,
                    preferences: existing.preferences,
                    pipeline: pipelineStatus
                )
            } else {
                notificationDiagnostics = NotificationDiagnosticsSummary(
                    checkedAt: Date(),
                    permission: .warning("Run diagnostics first."),
                    inbox: .warning("Run diagnostics first."),
                    preferences: .warning("Run diagnostics first."),
                    pipeline: pipelineStatus
                )
            }
        }
    }

    private func copyDiagnosticsSummary() {
        guard let notificationDiagnostics else { return }

        UIPasteboard.general.string = """
        Notification Diagnostics
        Checked: \(notificationDiagnostics.checkedAt.formatted(date: .abbreviated, time: .shortened))
        Device Permission: \(notificationDiagnostics.permission.summaryText)
        Inbox Table Access: \(notificationDiagnostics.inbox.summaryText)
        Remote Preferences Row: \(notificationDiagnostics.preferences.summaryText)
        Schema / Trigger Readiness: \(notificationDiagnostics.pipeline.summaryText)
        """
        diagnosticsCopyMessage = "Diagnostics summary copied."
    }

    private func copyAccountSummary() {
        UIPasteboard.general.string = """
        Account Summary
        Name: \(accountDisplayName)
        Email: \(authVM.currentUserEmail.isEmpty ? "Unknown" : authVM.currentUserEmail)
        Member Since: \(memberSinceText)
        Discovery Source: \(draft.discoverySource.rawValue)
        Acquisition Notes: \(draft.discoveryNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "None" : draft.discoveryNotes.trimmingCharacters(in: .whitespacesAndNewlines))
        Fitness Goal: \(draft.fitnessGoal.rawValue)
        Inbox: \(unreadInboxCount == 0 ? "Clear" : "\(unreadInboxCount) unread")
        Onboarding: \(authVM.currentProfile?.onboardingComplete == true ? "Complete" : "Pending")
        """
        accountSummaryCopyMessage = "Account summary copied."
    }

    private func notificationToggle(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Text(subtitle)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
        }
        .tint(AppTheme.Colors.accentPrimary)
    }
}

private extension AppSettingsView {
    func accountMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.textTertiary)
            Text(value)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.sm)
        .background(AppTheme.Colors.backgroundElevated)
        .cornerRadius(AppTheme.Radius.md)
    }
}

private struct NotificationDiagnosticsSummary {
    let checkedAt: Date
    let permission: NotificationDiagnosticStatus
    let inbox: NotificationDiagnosticStatus
    let preferences: NotificationDiagnosticStatus
    let pipeline: NotificationDiagnosticStatus
}

private enum NotificationDiagnosticStatus {
    case success(String)
    case warning(String)
    case error(String)

    var message: String {
        switch self {
        case .success(let message), .warning(let message), .error(let message):
            return message
        }
    }

    var color: Color {
        switch self {
        case .success:
            return AppTheme.Colors.success
        case .warning:
            return AppTheme.Colors.warning
        case .error:
            return AppTheme.Colors.error
        }
    }

    var icon: String {
        switch self {
        case .success:
            return "checkmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .error:
            return "xmark.octagon.fill"
        }
    }

    var summaryText: String {
        switch self {
        case .success(let message):
            return "OK - \(message)"
        case .warning(let message):
            return "Warning - \(message)"
        case .error(let message):
            return "Error - \(message)"
        }
    }
}

private struct DiagnosticsRow: View {
    let title: String
    let status: NotificationDiagnosticStatus

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
            Image(systemName: status.icon)
                .foregroundColor(status.color)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Text(status.message)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }

            Spacer()
        }
    }
}

private struct SettingsRow: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTheme.Typography.titleSmall)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Text(subtitle)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
        .padding(.vertical, AppTheme.Spacing.xs)
    }
}

private struct SettingsBanner: View {
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

private struct DeleteAccountSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var confirmationText = ""

    let isLoading: Bool
    let onDelete: () async -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.backgroundPrimary.ignoresSafeArea()

                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    Text("This sends a final delete link to your verified email. Your account will only be removed after that link is opened.")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)

                    AuthTextField(
                        placeholder: "Type DELETE to confirm",
                        icon: "trash.fill",
                        text: $confirmationText
                    )

                    PrimaryButton("Send Delete Confirmation", isLoading: isLoading) {
                        Task { await onDelete() }
                    }
                    .disabled(!canDelete)
                    .opacity(canDelete ? 1 : 0.5)

                    SecondaryButton(title: "Cancel") {
                        dismiss()
                    }
                }
                .padding(AppTheme.Spacing.lg)
            }
            .navigationTitle("Confirm Delete")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var canDelete: Bool {
        confirmationText.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() == "DELETE"
    }
}

private struct SensitiveActionConfirmationSheet: View {
    @Environment(\.dismiss) private var dismiss

    let action: AuthViewModel.SensitiveAccountAction
    let currentEmail: String
    let isLoading: Bool
    let isUnlocked: Bool
    let errorMessage: String?
    let onSend: () async -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.backgroundPrimary.ignoresSafeArea()

                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    Text(action.detail)
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)

                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text("Verification email")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textTertiary)

                        Text(currentEmail.isEmpty ? "No email available" : currentEmail)
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                    }

                    if isUnlocked {
                        SettingsBanner(
                            message: "Identity confirmed. You can close this sheet and continue.",
                            color: AppTheme.Colors.success,
                            icon: "checkmark.shield.fill"
                        )
                    } else if let errorMessage {
                        SettingsBanner(
                            message: errorMessage,
                            color: AppTheme.Colors.error,
                            icon: "exclamationmark.triangle.fill"
                        )
                    }

                    PrimaryButton(isUnlocked ? "Done" : "Send Confirmation Link", isLoading: isLoading) {
                        Task {
                            if isUnlocked {
                                dismiss()
                            } else {
                                await onSend()
                            }
                        }
                    }

                    Text("Open the secure link on this device after it arrives. SquaredAway will unlock \(action.title.lowercased()) when the callback returns to the app.")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textTertiary)

                    SecondaryButton(title: "Cancel") {
                        dismiss()
                    }
                }
                .padding(AppTheme.Spacing.lg)
            }
            .navigationTitle("Confirm Your Identity")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    NavigationStack {
        AppSettingsView()
            .environmentObject(AuthViewModel())
            .preferredColorScheme(.dark)
    }
}
