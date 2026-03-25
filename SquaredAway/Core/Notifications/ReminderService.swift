import Foundation
import UserNotifications

final class ReminderService {
    static let shared = ReminderService()

    private init() {}

    private let center = UNUserNotificationCenter.current()
    private let workoutReminderIdentifier = "daily-workout-reminder"
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
