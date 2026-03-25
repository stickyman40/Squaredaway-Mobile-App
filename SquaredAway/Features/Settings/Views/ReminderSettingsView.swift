import SwiftUI
import UIKit
import UserNotifications

struct ReminderSettingsView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @Environment(\.openURL) private var openURL

    @AppStorage(ReminderPreferences.boardReminderEnabledKey) private var boardReminderEnabled = true
    @AppStorage(ReminderPreferences.workoutReminderEnabledKey) private var workoutReminderEnabled = false
    @AppStorage(ReminderPreferences.workoutReminderTimeKey) private var workoutReminderTimeRaw = Date().timeIntervalSinceReferenceDate
    @AppStorage(ReminderPreferences.mealReminderEnabledKey) private var mealReminderEnabled = false
    @AppStorage(ReminderPreferences.mealReminderTimeKey) private var mealReminderTimeRaw = Date().timeIntervalSinceReferenceDate

    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let reminderService = ReminderService.shared
    private let promotionService = PromotionService.shared
    private let notificationService = NotificationService.shared

    var body: some View {
        ZStack {
            AppTheme.Colors.backgroundPrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    notificationStatusCard
                    boardReminderCard
                    workoutReminderCard
                    mealReminderCard
                    saveCard
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.lg)
            }
        }
        .navigationTitle("Reminder Settings")
        .task {
            authorizationStatus = await reminderService.authorizationStatus()
        }
    }

    private var notificationStatusCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("Notification Status")
                    .font(AppTheme.Typography.titleMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text(statusDescription)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)

                if authorizationStatus == .denied {
                    Button("Open iPhone Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            openURL(url)
                        }
                    }
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.accentSecondary)
                }
            }
        }
    }

    private var boardReminderCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Toggle("Board Date Reminders", isOn: $boardReminderEnabled)
                    .tint(AppTheme.Colors.accentPrimary)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text("When enabled, board dates in Promotions schedule reminders 7 days and 1 day ahead.")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }

    private var workoutReminderCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Toggle("Daily Workout Reminder", isOn: $workoutReminderEnabled)
                    .tint(AppTheme.Colors.accentPrimary)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                if workoutReminderEnabled {
                    DatePicker(
                        "Workout Time",
                        selection: workoutReminderTimeBinding,
                        displayedComponents: .hourAndMinute
                    )
                    .tint(AppTheme.Colors.accentSecondary)
                }

                Text("Used by the Fitness screen quick reminder controls.")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }

    private var mealReminderCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Toggle("Daily Meal Reminder", isOn: $mealReminderEnabled)
                    .tint(AppTheme.Colors.accentPrimary)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                if mealReminderEnabled {
                    DatePicker(
                        "Meal Reminder Time",
                        selection: mealReminderTimeBinding,
                        displayedComponents: .hourAndMinute
                    )
                    .tint(AppTheme.Colors.accentSecondary)
                }

                Text("Used by the Chow screen quick reminder controls.")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }

    private var saveCard: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            if let errorMessage {
                ReminderStatusBanner(message: errorMessage, color: AppTheme.Colors.error, icon: "exclamationmark.triangle.fill")
            }

            if let successMessage {
                ReminderStatusBanner(message: successMessage, color: AppTheme.Colors.success, icon: "checkmark.circle.fill")
            }

            PrimaryButton("Apply Reminder Settings", isLoading: isSaving) {
                Task { await applySettings() }
            }
        }
    }

    private var workoutReminderTimeBinding: Binding<Date> {
        Binding(
            get: { Date(timeIntervalSinceReferenceDate: workoutReminderTimeRaw) },
            set: { workoutReminderTimeRaw = $0.timeIntervalSinceReferenceDate }
        )
    }

    private var mealReminderTimeBinding: Binding<Date> {
        Binding(
            get: { Date(timeIntervalSinceReferenceDate: mealReminderTimeRaw) },
            set: { mealReminderTimeRaw = $0.timeIntervalSinceReferenceDate }
        )
    }

    private func applySettings() async {
        isSaving = true
        errorMessage = nil
        successMessage = nil
        defer { isSaving = false }

        do {
            let anyEnabled = boardReminderEnabled || workoutReminderEnabled || mealReminderEnabled
            if anyEnabled {
                let granted = try await reminderService.requestAuthorization()
                guard granted else {
                    errorMessage = "Notifications are disabled. Enable them in Settings."
                    return
                }
            }

            ReminderPreferences.setBoardReminderEnabled(boardReminderEnabled)
            ReminderPreferences.setWorkoutReminderEnabled(workoutReminderEnabled)
            ReminderPreferences.setWorkoutReminderTime(Date(timeIntervalSinceReferenceDate: workoutReminderTimeRaw))
            ReminderPreferences.setMealReminderEnabled(mealReminderEnabled)
            ReminderPreferences.setMealReminderTime(Date(timeIntervalSinceReferenceDate: mealReminderTimeRaw))

            if workoutReminderEnabled {
                try await reminderService.scheduleDailyWorkoutReminder(at: Date(timeIntervalSinceReferenceDate: workoutReminderTimeRaw))
            } else {
                reminderService.removeDailyWorkoutReminder()
            }

            if mealReminderEnabled {
                try await reminderService.scheduleDailyMealReminder(at: Date(timeIntervalSinceReferenceDate: mealReminderTimeRaw))
            } else {
                reminderService.removeDailyMealReminder()
            }

            if boardReminderEnabled,
               let userId = authVM.currentUserId,
               let promotion = try await promotionService.fetchPromotion(userId: userId),
               let boardDate = promotion.boardDate {
                try await reminderService.scheduleBoardDateReminders(
                    promotionID: promotion.id,
                    targetRank: promotion.targetRank,
                    boardDate: boardDate
                )
            } else {
                await reminderService.removeAllBoardDateReminders()
            }

            if let userId = authVM.currentUserId {
                let enabledReminders = [
                    boardReminderEnabled ? "board" : nil,
                    workoutReminderEnabled ? "workout" : nil,
                    mealReminderEnabled ? "meal" : nil
                ]
                .compactMap { $0 }

                let body = enabledReminders.isEmpty
                    ? "All reminder types are now turned off."
                    : "Enabled: \(enabledReminders.joined(separator: ", "))."

                try? await notificationService.createNotification(
                    userId: userId,
                    category: .readiness,
                    title: "Reminder settings updated",
                    body: body
                )
            }

            successMessage = "Reminder settings applied."
            authorizationStatus = await reminderService.authorizationStatus()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private var statusDescription: String {
        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return "Notifications are enabled for SquaredAway."
        case .denied:
            return "Notifications are disabled. Open iPhone Settings to allow reminders."
        case .notDetermined:
            return "Notification permission has not been requested yet."
        @unknown default:
            return "Notification status is unavailable."
        }
    }
}

private struct ReminderStatusBanner: View {
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
    NavigationStack {
        ReminderSettingsView()
            .environmentObject(AuthViewModel())
            .preferredColorScheme(.dark)
    }
}
