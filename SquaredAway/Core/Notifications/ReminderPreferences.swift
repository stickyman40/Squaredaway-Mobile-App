import Foundation

enum ReminderPreferences {
    static let boardReminderEnabledKey = "reminder.board.enabled"
    static let workoutReminderEnabledKey = "reminder.workout.enabled"
    static let workoutReminderTimeKey = "reminder.workout.time"
    static let mealReminderEnabledKey = "reminder.meal.enabled"
    static let mealReminderTimeKey = "reminder.meal.time"

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            boardReminderEnabledKey: true,
            workoutReminderEnabledKey: false,
            workoutReminderTimeKey: defaultTime(hour: 19, minute: 0),
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
