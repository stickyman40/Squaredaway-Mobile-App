import Foundation

enum PlannerReminderMode: String, CaseIterable, Identifiable {
    case adaptive
    case sameDayOnly = "same_day_only"
    case missedOnly = "missed_only"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .adaptive:
            return "Adaptive"
        case .sameDayOnly:
            return "Same Day Only"
        case .missedOnly:
            return "Missed Only"
        }
    }

    var summary: String {
        switch self {
        case .adaptive:
            return "Today first, then missed sessions, then the next upcoming workout."
        case .sameDayOnly:
            return "Only remind me about workouts that are due today."
        case .missedOnly:
            return "Only nudge me when I have an unfinished workout from a previous day."
        }
    }
}

enum PlannerReminderLeadTime: Int, CaseIterable, Identifiable {
    case atTime = 0
    case thirtyMinutes = 30
    case oneHour = 60
    case twoHours = 120

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .atTime:
            return "At workout time"
        case .thirtyMinutes:
            return "30 min before"
        case .oneHour:
            return "1 hour before"
        case .twoHours:
            return "2 hours before"
        }
    }
}

enum ReminderPreferences {
    static let boardReminderEnabledKey = "reminder.board.enabled"
    static let workoutReminderEnabledKey = "reminder.workout.enabled"
    static let workoutReminderTimeKey = "reminder.workout.time"
    static let plannerReminderModeKey = "reminder.planner.mode"
    static let plannerReminderLeadTimeKey = "reminder.planner.lead-time"
    static let mealReminderEnabledKey = "reminder.meal.enabled"
    static let mealReminderTimeKey = "reminder.meal.time"

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            boardReminderEnabledKey: true,
            workoutReminderEnabledKey: false,
            workoutReminderTimeKey: defaultTime(hour: 19, minute: 0),
            plannerReminderModeKey: PlannerReminderMode.adaptive.rawValue,
            plannerReminderLeadTimeKey: PlannerReminderLeadTime.atTime.rawValue,
            mealReminderEnabledKey: false,
            mealReminderTimeKey: defaultTime(hour: 12, minute: 0)
        ])
    }

    static func boardReminderEnabled() -> Bool {
        UserDefaults.standard.bool(forKey: boardReminderEnabledKey)
    }

    static func setBoardReminderEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: boardReminderEnabledKey)
    }

    static func workoutReminderEnabled() -> Bool {
        UserDefaults.standard.bool(forKey: workoutReminderEnabledKey)
    }

    static func setWorkoutReminderEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: workoutReminderEnabledKey)
    }

    static func workoutReminderTime() -> Date {
        Date(timeIntervalSinceReferenceDate: UserDefaults.standard.double(forKey: workoutReminderTimeKey))
    }

    static func setWorkoutReminderTime(_ date: Date) {
        UserDefaults.standard.set(date.timeIntervalSinceReferenceDate, forKey: workoutReminderTimeKey)
    }

    static func plannerReminderMode() -> PlannerReminderMode {
        PlannerReminderMode(rawValue: UserDefaults.standard.string(forKey: plannerReminderModeKey) ?? "") ?? .adaptive
    }

    static func setPlannerReminderMode(_ mode: PlannerReminderMode) {
        UserDefaults.standard.set(mode.rawValue, forKey: plannerReminderModeKey)
    }

    static func plannerReminderLeadTime() -> PlannerReminderLeadTime {
        PlannerReminderLeadTime(rawValue: UserDefaults.standard.integer(forKey: plannerReminderLeadTimeKey)) ?? .atTime
    }

    static func setPlannerReminderLeadTime(_ leadTime: PlannerReminderLeadTime) {
        UserDefaults.standard.set(leadTime.rawValue, forKey: plannerReminderLeadTimeKey)
    }

    static func mealReminderEnabled() -> Bool {
        UserDefaults.standard.bool(forKey: mealReminderEnabledKey)
    }

    static func setMealReminderEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: mealReminderEnabledKey)
    }

    static func mealReminderTime() -> Date {
        Date(timeIntervalSinceReferenceDate: UserDefaults.standard.double(forKey: mealReminderTimeKey))
    }

    static func setMealReminderTime(_ date: Date) {
        UserDefaults.standard.set(date.timeIntervalSinceReferenceDate, forKey: mealReminderTimeKey)
    }

    private static func defaultTime(hour: Int, minute: Int) -> TimeInterval {
        var components = DateComponents()
        components.calendar = Calendar.current
        components.year = 2001
        components.month = 1
        components.day = 1
        components.hour = hour
        components.minute = minute
        return (components.date ?? Date()).timeIntervalSinceReferenceDate
    }
}
