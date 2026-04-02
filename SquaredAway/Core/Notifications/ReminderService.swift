import Foundation
import UserNotifications

final class ReminderService {
    static let shared = ReminderService()

    private init() {}

    private let center = UNUserNotificationCenter.current()
    private let workoutReminderIdentifier = "daily-workout-reminder"
    private let plannerWorkoutReminderIdentifier = "planner-workout-reminder"
    private let mealReminderIdentifier = "daily-meal-reminder"

    func requestAuthorization() async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    func scheduleBoardDateReminders(promotionID: UUID, targetRank: String, boardDate: Date) async throws {
        try await removeBoardDateReminders(promotionID: promotionID)

        let offsets = [7, 1]
        for daysBefore in offsets {
            guard let reminderDate = Calendar.current.date(byAdding: .day, value: -daysBefore, to: boardDate),
                  reminderDate > Date() else {
                continue
            }

            let content = UNMutableNotificationContent()
            content.title = daysBefore == 1 ? "Promotion Board Tomorrow" : "Promotion Board Next Week"
            content.body = "Your \(targetRank) board date is coming up. Review your packet and points."
            content.sound = .default

            var components = Calendar.current.dateComponents([.year, .month, .day], from: reminderDate)
            components.hour = 9
            components.minute = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: boardReminderIdentifier(for: promotionID, daysBefore: daysBefore),
                content: content,
                trigger: trigger
            )
            try await center.add(request)
        }
    }

    func removeBoardDateReminders(promotionID: UUID) async throws {
        center.removePendingNotificationRequests(withIdentifiers: [
            boardReminderIdentifier(for: promotionID, daysBefore: 7),
            boardReminderIdentifier(for: promotionID, daysBefore: 1)
        ])
    }

    func scheduleDailyWorkoutReminder() async throws {
        try await scheduleDailyWorkoutReminder(at: ReminderPreferences.workoutReminderTime())
    }

    func scheduleDailyWorkoutReminder(at time: Date) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Workout Reminder"
        content.body = "Log your PT session and keep your readiness streak moving."
        content.sound = .default

        let components = Calendar.current.dateComponents([.hour, .minute], from: time)

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: workoutReminderIdentifier,
            content: content,
            trigger: trigger
        )
        try await center.add(request)
    }

    func removeDailyWorkoutReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [workoutReminderIdentifier])
    }

    func schedulePlannerWorkoutReminder(
        workoutName: String,
        scheduledDate: Date,
        preferredTime: Date,
        leadTime: PlannerReminderLeadTime = ReminderPreferences.plannerReminderLeadTime(),
        now: Date = Date()
    ) async throws {
        removePlannerWorkoutReminder()

        guard let fireDate = plannerWorkoutReminderDate(
            scheduledDate: scheduledDate,
            preferredTime: preferredTime,
            leadTime: leadTime,
            now: now
        ) else {
            return
        }

        let content = UNMutableNotificationContent()
        let isSameDay = Calendar.current.isDate(fireDate, inSameDayAs: now)
        content.title = isSameDay ? "Workout Reminder" : "Upcoming Workout"
        content.body = isSameDay
            ? "\(workoutName) is still on deck today. Open SquaredAway and knock it out."
            : "\(workoutName) is coming up. Review the plan and stay on schedule."
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: plannerWorkoutReminderIdentifier,
            content: content,
            trigger: trigger
        )
        try await center.add(request)
    }

    func removePlannerWorkoutReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [plannerWorkoutReminderIdentifier])
    }

    func scheduleDailyMealReminder() async throws {
        try await scheduleDailyMealReminder(at: ReminderPreferences.mealReminderTime())
    }

    func scheduleDailyMealReminder(at time: Date) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Meal Check-In"
        content.body = "Record your meal and macros to stay on top of recovery."
        content.sound = .default

        let components = Calendar.current.dateComponents([.hour, .minute], from: time)

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: mealReminderIdentifier,
            content: content,
            trigger: trigger
        )
        try await center.add(request)
    }

    func removeDailyMealReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [mealReminderIdentifier])
    }

    func removeAllBoardDateReminders() async {
        let requests = await pendingRequests()
        let identifiers = requests
            .map(\.identifier)
            .filter { $0.hasPrefix("promotion-") }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        let settings = await notificationSettings()
        return settings.authorizationStatus
    }

    func plannerWorkoutReminderDate(
        scheduledDate: Date,
        preferredTime: Date,
        leadTime: PlannerReminderLeadTime = ReminderPreferences.plannerReminderLeadTime(),
        now: Date = Date()
    ) -> Date? {
        let calendar = Calendar.current
        let normalizedNow = calendar.startOfDay(for: now)
        let normalizedScheduledDate = calendar.startOfDay(for: scheduledDate)
        let preferredTimeComponents = calendar.dateComponents([.hour, .minute], from: preferredTime)

        let baseDate = normalizedScheduledDate < normalizedNow ? normalizedNow : normalizedScheduledDate
        var components = calendar.dateComponents([.year, .month, .day], from: baseDate)
        components.hour = preferredTimeComponents.hour
        components.minute = preferredTimeComponents.minute

        guard let preferredDateTime = calendar.date(from: components) else { return nil }
        let leadAdjustedDate = calendar.date(byAdding: .minute, value: -leadTime.rawValue, to: preferredDateTime) ?? preferredDateTime

        if leadAdjustedDate > now {
            return leadAdjustedDate
        }

        if calendar.isDate(baseDate, inSameDayAs: now) {
            return calendar.date(byAdding: .minute, value: 15, to: now)
        }

        return nil
    }

    private func boardReminderIdentifier(for promotionID: UUID, daysBefore: Int) -> String {
        "promotion-\(promotionID.uuidString)-\(daysBefore)"
    }

    private func pendingRequests() async -> [UNNotificationRequest] {
        await withCheckedContinuation { continuation in
            center.getPendingNotificationRequests { requests in
                continuation.resume(returning: requests)
            }
        }
    }

    private func notificationSettings() async -> UNNotificationSettings {
        await withCheckedContinuation { continuation in
            center.getNotificationSettings { settings in
                continuation.resume(returning: settings)
            }
        }
    }
}
