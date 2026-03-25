import Foundation

enum AppNotificationCategory: String, CaseIterable, Identifiable {
    case milestones
    case readiness
    case activity

    var id: String { rawValue }

    var title: String {
        switch self {
        case .milestones:
            return "Milestones"
        case .readiness:
            return "Readiness Updates"
        case .activity:
            return "Fitness & Chow Activity"
        }
    }

    var subtitle: String {
        switch self {
        case .milestones:
            return "Onboarding completion and major account progress."
        case .readiness:
            return "Promotions, pay, and reminder setting changes."
        case .activity:
            return "Workout and chow entry create, edit, and delete events."
        }
    }

    var defaultsKey: String {
        switch self {
        case .milestones:
            return NotificationPreferences.milestonesEnabledKey
        case .readiness:
            return NotificationPreferences.readinessEnabledKey
        case .activity:
            return NotificationPreferences.activityEnabledKey
        }
    }

    var shortTitle: String {
        switch self {
        case .milestones:
            return "Milestones"
        case .readiness:
            return "Readiness"
        case .activity:
            return "Activity"
        }
    }

    var icon: String {
        switch self {
        case .milestones:
            return "flag.fill"
        case .readiness:
            return "shield.checkered"
        case .activity:
            return "figure.run"
        }
    }

    static func from(type: String) -> AppNotificationCategory? {
        AppNotificationCategory(rawValue: type.lowercased())
    }
}

enum NotificationPreferences {
    static let milestonesEnabledKey = "notifications.milestones.enabled"
    static let readinessEnabledKey = "notifications.readiness.enabled"
    static let activityEnabledKey = "notifications.activity.enabled"

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            milestonesEnabledKey: true,
            readinessEnabledKey: true,
            activityEnabledKey: true
        ])
    }

    static func isEnabled(for category: AppNotificationCategory) -> Bool {
        UserDefaults.standard.bool(forKey: category.defaultsKey)
    }

    static func setEnabled(_ enabled: Bool, for category: AppNotificationCategory) {
        UserDefaults.standard.set(enabled, forKey: category.defaultsKey)
    }
}
