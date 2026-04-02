import Foundation
import SwiftUI

// ============================================================
//  PTModels.swift
//  All domain models for the SquaredAway PT / Fitness module.
//  Branch-specific PT standards are sourced from official
//  service regulations. Scores are for self-tracking only;
//  official results must be validated through proper channels.
// ============================================================

// MARK: - Fitness Profile
struct FitnessProfile: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var heightCm: Double
    var weightKg: Double
    var goalWeightKg: Double?
    var fitnessGoal: PTFitnessGoal
    var experienceLevel: ExperienceLevel
    var workoutSplit: WorkoutSplit
    var dailyCalorieTarget: Int?
    var weeklyWorkoutTarget: Int      // days per week
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id; case userId = "user_id"
        case heightCm = "height_cm"; case weightKg = "weight_kg"
        case goalWeightKg = "goal_weight_kg"; case fitnessGoal = "fitness_goal"
        case experienceLevel = "experience_level"; case workoutSplit = "workout_split"
        case dailyCalorieTarget = "daily_calorie_target"
        case weeklyWorkoutTarget = "weekly_workout_target"
        case createdAt = "created_at"; case updatedAt = "updated_at"
    }

    var bmi: Double {
        guard heightCm > 0 else { return 0 }
        let meters = heightCm / 100
        return weightKg / (meters * meters)
    }

    var bmiCategory: BMICategory { BMICategory.from(bmi: bmi) }

    var weightProgressPercent: Double {
        guard let goal = goalWeightKg else { return 0 }
        let distanceToGoal = abs(weightKg - goal)
        let baseline = max(weightKg, goal)
        guard baseline > 0 else { return 0 }
        if distanceToGoal == 0 { return 1 }
        return max(0, min(1, 1 - (distanceToGoal / baseline)))
    }

    var heightFeet: Int { Int(heightCm / 30.48) }
    var heightInches: Int { Int((heightCm / 2.54).truncatingRemainder(dividingBy: 12)) }
    var weightLbs: Double { weightKg * 2.20462 }
    var goalWeightLbs: Double? { goalWeightKg.map { $0 * 2.20462 } }

    static func empty(userId: UUID) -> FitnessProfile {
        FitnessProfile(
            id: UUID(), userId: userId,
            heightCm: 177.8, weightKg: 79.4,
            goalWeightKg: nil, fitnessGoal: .improvePTScore,
            experienceLevel: .intermediate, workoutSplit: .upperLower,
            dailyCalorieTarget: nil, weeklyWorkoutTarget: 4,
            createdAt: Date(), updatedAt: Date()
        )
    }
}

// MARK: - PT Fitness Goal
enum PTFitnessGoal: String, Codable, CaseIterable, Hashable {
    case loseFat      = "lose_fat"
    case buildMuscle  = "build_muscle"
    case maintain     = "maintain"
    case improvePTScore = "improve_pt_score"

    var label: String {
        switch self {
        case .loseFat:        return "Lose Fat"
        case .buildMuscle:    return "Build Muscle"
        case .maintain:       return "Maintain"
        case .improvePTScore: return "Improve PT Score"
        }
    }
    var icon: String {
        switch self {
        case .loseFat:        return "scalemass.fill"
        case .buildMuscle:    return "figure.strengthtraining.traditional"
        case .maintain:       return "arrow.trianglehead.2.clockwise"
        case .improvePTScore: return "chart.line.uptrend.xyaxis"
        }
    }
    var color: String {
        switch self {
        case .loseFat:        return "#FF6B6B"
        case .buildMuscle:    return "#45B7D1"
        case .maintain:       return "#96CEB4"
        case .improvePTScore: return "#A29BFE"
        }
    }
}

// MARK: - BMI Category
enum BMICategory {
    case underweight, normal, overweight, obese

    static func from(bmi: Double) -> BMICategory {
        switch bmi {
        case ..<18.5: return .underweight
        case 18.5..<25: return .normal
        case 25..<30: return .overweight
        default: return .obese
        }
    }

    var label: String {
        switch self {
        case .underweight: return "Underweight"
        case .normal:      return "Normal"
        case .overweight:  return "Overweight"
        case .obese:       return "High"
        }
    }
    var color: Color {
        switch self {
        case .underweight: return Color(hex: "#FFD700")
        case .normal:      return Color(hex: "#34C759")
        case .overweight:  return Color(hex: "#FF9F0A")
        case .obese:       return Color(hex: "#FF453A")
        }
    }
    var bgColor: Color { color.opacity(0.12) }
}

// MARK: - Experience Level
enum ExperienceLevel: String, Codable, CaseIterable, Hashable {
    case beginner, intermediate, advanced
    var label: String { rawValue.capitalized }
    var weeklyVolume: String {
        switch self {
        case .beginner:     return "3 days/week"
        case .intermediate: return "4 days/week"
        case .advanced:     return "5–6 days/week"
        }
    }
}

// MARK: - Workout Split
enum WorkoutSplit: String, Codable, CaseIterable, Hashable {
    case beginnerFoundation = "beginner_foundation"
    case pushPullLegs = "push_pull_legs"
    case upperLower   = "upper_lower"
    case fullBody     = "full_body"
    case broSplit     = "bro_split"
    case powerbuilding = "powerbuilding"
    case strengthConditioning = "strength_conditioning"
    case runFocusedHybrid = "run_focused_hybrid"
    case hybridPerformance = "hybrid_performance"
    case tacticalReadiness = "tactical_readiness"
    case custom       = "custom"

    var label: String {
        switch self {
        case .beginnerFoundation: return "Beginner Foundation"
        case .pushPullLegs: return "Push / Pull / Legs"
        case .upperLower:   return "Upper / Lower"
        case .fullBody:     return "Full Body"
        case .broSplit:     return "Bro Split"
        case .powerbuilding: return "Powerbuilding"
        case .strengthConditioning: return "Strength + Conditioning"
        case .runFocusedHybrid: return "Run-Focused Hybrid"
        case .hybridPerformance: return "Hybrid Performance"
        case .tacticalReadiness: return "Tactical Readiness"
        case .custom:       return "Custom"
        }
    }
    var abbreviation: String {
        switch self {
        case .beginnerFoundation: return "Base"
        case .pushPullLegs: return "PPL"
        case .upperLower:   return "U/L"
        case .fullBody:     return "FB"
        case .broSplit:     return "Bro"
        case .powerbuilding: return "P/B"
        case .strengthConditioning: return "S+C"
        case .runFocusedHybrid: return "Run"
        case .hybridPerformance: return "Hybrid"
        case .tacticalReadiness: return "Tac"
        case .custom:       return "Custom"
        }
    }

    var summary: String {
        switch self {
        case .beginnerFoundation:
            return "Simple 3-day strength base with recovery days between sessions."
        case .pushPullLegs:
            return "Balanced muscle-group rotation for frequent lifting."
        case .upperLower:
            return "Straightforward split for strength and hypertrophy across 4 days."
        case .fullBody:
            return "Three main lifting days with cardio and PT-friendly conditioning."
        case .broSplit:
            return "Dedicated body-part days with one cardio day built in."
        case .powerbuilding:
            return "Heavy compound lifts plus bodybuilding accessory volume."
        case .strengthConditioning:
            return "Alternates lifting sessions with conditioning and recovery."
        case .runFocusedHybrid:
            return "Built around run progress while keeping full-body strength work."
        case .hybridPerformance:
            return "Combines strength, speed, and endurance across the full week."
        case .tacticalReadiness:
            return "Preparedness-focused split for PT, carries, and work capacity."
        case .custom:
            return "Bring your own structure once custom planning is connected."
        }
    }

    var recommendedDaysText: String {
        let trainingDays = weeklySchedule.filter { !$0.isRestDay }.count
        guard trainingDays > 0 else { return "Flexible" }
        return "\(trainingDays) days/week"
    }

    var weeklySchedule: [WorkoutDay] {
        switch self {
        case .beginnerFoundation:
            return [
                WorkoutDay(dayNumber: 1, name: "Full Body A", focus: "Chest · Back · Legs", exercises: WorkoutLibrary.beginnerFullBodyA),
                WorkoutDay(dayNumber: 2, name: "Recovery", focus: "Walk · Mobility · Core", exercises: []),
                WorkoutDay(dayNumber: 3, name: "Full Body B", focus: "Shoulders · Posterior Chain · Core", exercises: WorkoutLibrary.beginnerFullBodyB),
                WorkoutDay(dayNumber: 4, name: "Recovery", focus: "Easy cardio or mobility", exercises: []),
                WorkoutDay(dayNumber: 5, name: "Full Body C", focus: "Push · Pull · Legs", exercises: WorkoutLibrary.beginnerFullBodyC),
                WorkoutDay(dayNumber: 6, name: "Cardio", focus: "Easy run · Bike · Ruck", exercises: WorkoutLibrary.cardioDay),
                WorkoutDay(dayNumber: 7, name: "Rest", focus: "Full recovery", exercises: []),
            ]
        case .pushPullLegs:
            return [
                WorkoutDay(dayNumber: 1, name: "Push",  focus: "Chest · Shoulders · Triceps", exercises: WorkoutLibrary.pushDay),
                WorkoutDay(dayNumber: 2, name: "Pull",  focus: "Back · Biceps · Rear Delts",   exercises: WorkoutLibrary.pullDay),
                WorkoutDay(dayNumber: 3, name: "Legs",  focus: "Quads · Hamstrings · Glutes",  exercises: WorkoutLibrary.legDay),
                WorkoutDay(dayNumber: 4, name: "Rest",  focus: "Active recovery / Cardio",      exercises: []),
                WorkoutDay(dayNumber: 5, name: "Push",  focus: "Chest · Shoulders · Triceps",  exercises: WorkoutLibrary.pushDay),
                WorkoutDay(dayNumber: 6, name: "Pull",  focus: "Back · Biceps · Rear Delts",   exercises: WorkoutLibrary.pullDay),
                WorkoutDay(dayNumber: 7, name: "Legs",  focus: "Quads · Hamstrings · Glutes",  exercises: WorkoutLibrary.legDay),
            ]
        case .upperLower:
            return [
                WorkoutDay(dayNumber: 1, name: "Upper A", focus: "Chest · Back · Shoulders",  exercises: WorkoutLibrary.upperDay),
                WorkoutDay(dayNumber: 2, name: "Lower A", focus: "Quads · Hamstrings · Core", exercises: WorkoutLibrary.lowerDay),
                WorkoutDay(dayNumber: 3, name: "Rest",    focus: "Recovery",                   exercises: []),
                WorkoutDay(dayNumber: 4, name: "Upper B", focus: "Chest · Back · Arms",       exercises: WorkoutLibrary.upperDay),
                WorkoutDay(dayNumber: 5, name: "Lower B", focus: "Glutes · Hamstrings · Core",exercises: WorkoutLibrary.lowerDay),
                WorkoutDay(dayNumber: 6, name: "Cardio",  focus: "Run / Ruck / Swim",          exercises: WorkoutLibrary.cardioDay),
                WorkoutDay(dayNumber: 7, name: "Rest",    focus: "Full recovery",               exercises: []),
            ]
        case .fullBody:
            return [
                WorkoutDay(dayNumber: 1, name: "Full Body A", focus: "Compound movements", exercises: WorkoutLibrary.fullBodyDay),
                WorkoutDay(dayNumber: 2, name: "Cardio",      focus: "Run / Ruck / HIIT",  exercises: WorkoutLibrary.cardioDay),
                WorkoutDay(dayNumber: 3, name: "Full Body B", focus: "Strength + Core",   exercises: WorkoutLibrary.fullBodyDay),
                WorkoutDay(dayNumber: 4, name: "Rest",        focus: "Recovery",           exercises: []),
                WorkoutDay(dayNumber: 5, name: "Full Body C", focus: "Military PT focus",  exercises: WorkoutLibrary.milPTDay),
                WorkoutDay(dayNumber: 6, name: "Cardio",      focus: "Long run / Ruck",   exercises: WorkoutLibrary.cardioDay),
                WorkoutDay(dayNumber: 7, name: "Rest",        focus: "Full recovery",      exercises: []),
            ]
        case .broSplit:
            return [
                WorkoutDay(dayNumber: 1, name: "Chest",     focus: "Pressing and pec volume",     exercises: WorkoutLibrary.pushDay),
                WorkoutDay(dayNumber: 2, name: "Back",      focus: "Rows, pull-ups, rear delts",  exercises: WorkoutLibrary.pullDay),
                WorkoutDay(dayNumber: 3, name: "Legs",      focus: "Strength and lower body work", exercises: WorkoutLibrary.legDay),
                WorkoutDay(dayNumber: 4, name: "Shoulders", focus: "Pressing, raises, stability",  exercises: WorkoutLibrary.shoulderDay),
                WorkoutDay(dayNumber: 5, name: "Arms",      focus: "Biceps, triceps, grip",        exercises: WorkoutLibrary.armDay),
                WorkoutDay(dayNumber: 6, name: "Cardio",    focus: "Conditioning and engine",      exercises: WorkoutLibrary.cardioDay),
                WorkoutDay(dayNumber: 7, name: "Rest",      focus: "Full recovery",                exercises: []),
            ]
        case .powerbuilding:
            return [
                WorkoutDay(dayNumber: 1, name: "Upper Power", focus: "Chest · Back · Shoulders", exercises: WorkoutLibrary.upperPowerDay),
                WorkoutDay(dayNumber: 2, name: "Lower Power", focus: "Quads · Glutes · Hamstrings", exercises: WorkoutLibrary.lowerPowerDay),
                WorkoutDay(dayNumber: 3, name: "Recovery", focus: "Mobility · Core · Easy walk", exercises: []),
                WorkoutDay(dayNumber: 4, name: "Push Hypertrophy", focus: "Chest · Shoulders · Triceps", exercises: WorkoutLibrary.pushHypertrophyDay),
                WorkoutDay(dayNumber: 5, name: "Pull Hypertrophy", focus: "Back · Biceps · Rear Delts", exercises: WorkoutLibrary.pullHypertrophyDay),
                WorkoutDay(dayNumber: 6, name: "Leg Hypertrophy", focus: "Quads · Glutes · Calves", exercises: WorkoutLibrary.legHypertrophyDay),
                WorkoutDay(dayNumber: 7, name: "Rest", focus: "Full recovery", exercises: []),
            ]
        case .strengthConditioning:
            return [
                WorkoutDay(dayNumber: 1, name: "Strength A", focus: "Squat · Bench · Row", exercises: WorkoutLibrary.strengthADay),
                WorkoutDay(dayNumber: 2, name: "Conditioning", focus: "Intervals · Sleds · Core", exercises: WorkoutLibrary.conditioningDay),
                WorkoutDay(dayNumber: 3, name: "Strength B", focus: "Deadlift · Press · Pull", exercises: WorkoutLibrary.strengthBDay),
                WorkoutDay(dayNumber: 4, name: "Recovery", focus: "Mobility · Zone 2", exercises: []),
                WorkoutDay(dayNumber: 5, name: "Strength C", focus: "Full Body · Carries · Core", exercises: WorkoutLibrary.strengthCDay),
                WorkoutDay(dayNumber: 6, name: "Engine", focus: "Tempo run · Bike · Ruck", exercises: WorkoutLibrary.enduranceDay),
                WorkoutDay(dayNumber: 7, name: "Rest", focus: "Full recovery", exercises: []),
            ]
        case .runFocusedHybrid:
            return [
                WorkoutDay(dayNumber: 1, name: "Speed Work", focus: "Run · Core · Mobility", exercises: WorkoutLibrary.speedDay),
                WorkoutDay(dayNumber: 2, name: "Lift A", focus: "Upper Body · Core", exercises: WorkoutLibrary.upperDay),
                WorkoutDay(dayNumber: 3, name: "Easy Run", focus: "Aerobic base · Recovery", exercises: WorkoutLibrary.easyRunDay),
                WorkoutDay(dayNumber: 4, name: "Lift B", focus: "Lower Body · Posterior Chain", exercises: WorkoutLibrary.lowerDay),
                WorkoutDay(dayNumber: 5, name: "Tempo", focus: "Threshold run · Core", exercises: WorkoutLibrary.tempoRunDay),
                WorkoutDay(dayNumber: 6, name: "Long Run", focus: "Endurance · Mental stamina", exercises: WorkoutLibrary.longRunDay),
                WorkoutDay(dayNumber: 7, name: "Rest", focus: "Mobility and reset", exercises: []),
            ]
        case .hybridPerformance:
            return [
                WorkoutDay(dayNumber: 1, name: "Upper Strength", focus: "Heavy push and pull",           exercises: WorkoutLibrary.upperDay),
                WorkoutDay(dayNumber: 2, name: "Intervals",      focus: "Speed, engine, work capacity",  exercises: WorkoutLibrary.speedDay),
                WorkoutDay(dayNumber: 3, name: "Lower Strength", focus: "Squat, hinge, core",            exercises: WorkoutLibrary.lowerDay),
                WorkoutDay(dayNumber: 4, name: "Tempo Run",      focus: "Aerobic threshold",             exercises: WorkoutLibrary.cardioDay),
                WorkoutDay(dayNumber: 5, name: "Full Body",      focus: "Power and total-body strength", exercises: WorkoutLibrary.fullBodyDay),
                WorkoutDay(dayNumber: 6, name: "Long Session",   focus: "Long run, ruck, or swim",       exercises: WorkoutLibrary.enduranceDay),
                WorkoutDay(dayNumber: 7, name: "Rest",           focus: "Mobility and reset",            exercises: []),
            ]
        case .tacticalReadiness:
            return [
                WorkoutDay(dayNumber: 1, name: "Strength Base",  focus: "Deadlift, press, pulls",        exercises: WorkoutLibrary.lowerDay),
                WorkoutDay(dayNumber: 2, name: "Work Capacity",  focus: "Sprint, drag, carry, core",     exercises: WorkoutLibrary.tacticalDay),
                WorkoutDay(dayNumber: 3, name: "Upper Volume",   focus: "Push, pull, shoulder durability", exercises: WorkoutLibrary.upperDay),
                WorkoutDay(dayNumber: 4, name: "Ruck / Carry",   focus: "Loaded movement and grip",       exercises: WorkoutLibrary.enduranceDay),
                WorkoutDay(dayNumber: 5, name: "PT Rehearsal",   focus: "Branch test practice",          exercises: WorkoutLibrary.milPTDay),
                WorkoutDay(dayNumber: 6, name: "Engine Day",     focus: "Long conditioning effort",       exercises: WorkoutLibrary.cardioDay),
                WorkoutDay(dayNumber: 7, name: "Rest",           focus: "Recovery and mobility",          exercises: []),
            ]
        case .custom:
            return []
        }
    }

    var todayWorkout: WorkoutDay? {
        let dayIndex = Calendar.current.component(.weekday, from: Date()) - 1
        let schedule = weeklySchedule
        guard !schedule.isEmpty else { return nil }
        return schedule[dayIndex % schedule.count]
    }

    func workout(on date: Date, calendar: Calendar = .current) -> WorkoutDay? {
        let schedule = weeklySchedule
        guard !schedule.isEmpty else { return nil }
        let dayIndex = calendar.component(.weekday, from: date) - 1
        return schedule[dayIndex % schedule.count]
    }

    func plannedWorkouts(startingAt startDate: Date, days: Int, calendar: Calendar = .current) -> [PlannedWorkout] {
        guard days > 0 else { return [] }
        return (0..<days).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: startDate),
                  let workout = workout(on: date, calendar: calendar) else {
                return nil
            }
            return PlannedWorkout(
                date: calendar.startOfDay(for: date),
                workout: workout,
                durationMinutes: workout.defaultDurationMinutes
            )
        }
    }
}

// MARK: - Workout Day
struct WorkoutDay: Identifiable {
    let id = UUID()
    let dayNumber: Int
    let name: String
    let focus: String
    let exercises: [ExerciseEntry]
    var isRestDay: Bool { exercises.isEmpty }

    var muscleGroups: [String] {
        guard !isRestDay else { return ["Recovery"] }
        return focus
            .replacingOccurrences(of: " / ", with: " · ")
            .replacingOccurrences(of: ",", with: " · ")
            .components(separatedBy: "·")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var defaultDurationMinutes: Int {
        if isRestDay { return 20 }
        if exercises.allSatisfy(\.isCardio) { return max(30, exercises.count * 20) }
        return max(40, min(90, exercises.count * 10))
    }
}

struct PlannedWorkout: Identifiable {
    let id = UUID()
    let date: Date
    let workout: WorkoutDay
    let durationMinutes: Int
    var notes: String? = nil
    var isCustom: Bool = false

    var isRestDay: Bool { workout.isRestDay }
    var muscleGroups: [String] { workout.muscleGroups }
    var summary: String {
        if let notes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return notes
        }
        return workout.focus
    }
}

struct WorkoutPlannerProgressRecord: Codable {
    var dateKey: String
    var completedExerciseKeys: Set<String>
    var isWorkoutCompleted: Bool

    init(
        dateKey: String,
        completedExerciseKeys: Set<String> = [],
        isWorkoutCompleted: Bool = false
    ) {
        self.dateKey = dateKey
        self.completedExerciseKeys = completedExerciseKeys
        self.isWorkoutCompleted = isWorkoutCompleted
    }

    static func exerciseKey(for exercise: ExerciseEntry, index: Int) -> String {
        "\(index)::\(exercise.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())"
    }

    func completionFraction(totalExercises: Int) -> Double {
        guard totalExercises > 0 else { return isWorkoutCompleted ? 1 : 0 }
        return min(1, Double(completedExerciseKeys.count) / Double(totalExercises))
    }

    mutating func setExerciseCompleted(_ isCompleted: Bool, key: String, totalExerciseKeys: [String]) {
        if isCompleted {
            completedExerciseKeys.insert(key)
        } else {
            completedExerciseKeys.remove(key)
        }
        let totalUniqueKeys = Set(totalExerciseKeys)
        isWorkoutCompleted = !totalUniqueKeys.isEmpty && completedExerciseKeys.isSuperset(of: totalUniqueKeys)
    }

    mutating func setWorkoutCompleted(_ isCompleted: Bool, allExerciseKeys: [String]) {
        self.isWorkoutCompleted = isCompleted
        completedExerciseKeys = isCompleted ? Set(allExerciseKeys) : []
    }
}

struct WorkoutPlannerExercise: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var sets: Int
    var reps: String
    var notes: String?
    var isCardio: Bool

    init(
        id: UUID = UUID(),
        name: String,
        sets: Int = 3,
        reps: String = "Custom",
        notes: String? = nil,
        isCardio: Bool = false
    ) {
        self.id = id
        self.name = name
        self.sets = sets
        self.reps = reps
        self.notes = notes
        self.isCardio = isCardio
    }

    var exerciseEntry: ExerciseEntry {
        ExerciseEntry(
            name: name,
            sets: sets,
            reps: reps,
            notes: notes,
            isCardio: isCardio
        )
    }
}

struct WorkoutPlannerOverride: Codable, Identifiable {
    let id: UUID
    let dateKey: String
    var title: String
    var focus: String
    var muscleGroups: [String]
    var durationMinutes: Int
    var notes: String?
    var isRestDay: Bool
    var exercises: [WorkoutPlannerExercise]

    init(
        id: UUID = UUID(),
        dateKey: String,
        title: String,
        focus: String,
        muscleGroups: [String],
        durationMinutes: Int,
        notes: String? = nil,
        isRestDay: Bool,
        exercises: [WorkoutPlannerExercise]
    ) {
        self.id = id
        self.dateKey = dateKey
        self.title = title
        self.focus = focus
        self.muscleGroups = muscleGroups
        self.durationMinutes = durationMinutes
        self.notes = notes
        self.isRestDay = isRestDay
        self.exercises = exercises
    }

    func plannedWorkout(on date: Date) -> PlannedWorkout {
        let resolvedFocus = normalizedFocus
        return PlannedWorkout(
            date: date,
            workout: WorkoutDay(
                dayNumber: 0,
                name: title,
                focus: resolvedFocus,
                exercises: isRestDay ? [] : exercises.map(\.exerciseEntry)
            ),
            durationMinutes: max(10, durationMinutes),
            notes: notes,
            isCustom: true
        )
    }

    private var normalizedFocus: String {
        let trimmedFocus = focus.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedFocus.isEmpty {
            return trimmedFocus
        }
        if !muscleGroups.isEmpty {
            return muscleGroups.joined(separator: " · ")
        }
        return isRestDay ? "Recovery" : "Custom session"
    }
}

struct WorkoutPlannerDraft: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    var title: String
    var focus: String
    var muscleGroupsText: String
    var durationMinutes: Double
    var notes: String
    var isRestDay: Bool
    var exerciseLines: String

    init(date: Date, plannedWorkout: PlannedWorkout) {
        self.date = date
        self.title = plannedWorkout.workout.name
        self.focus = plannedWorkout.workout.focus
        self.muscleGroupsText = plannedWorkout.muscleGroups.joined(separator: ", ")
        self.durationMinutes = Double(plannedWorkout.durationMinutes)
        self.notes = plannedWorkout.notes ?? ""
        self.isRestDay = plannedWorkout.isRestDay
        self.exerciseLines = plannedWorkout.workout.exercises
            .map(Self.line(for:))
            .joined(separator: "\n")
    }

    mutating func applyTemplate(_ template: WorkoutPlannerTemplatePreset) {
        title = template.title
        focus = template.focus
        muscleGroupsText = template.muscleGroups.joined(separator: ", ")
        durationMinutes = Double(template.durationMinutes)
        notes = template.notes ?? ""
        isRestDay = template.isRestDay
        exerciseLines = template.exercises
            .map(Self.line(for:))
            .joined(separator: "\n")
    }

    mutating func appendExercise(_ exercise: WorkoutPlannerExercise) {
        let line = Self.line(for: exercise)
        if exerciseLines.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            exerciseLines = line
        } else {
            exerciseLines += "\n\(line)"
        }
        isRestDay = false
    }

    mutating func addEmptyExercise() {
        appendExercise(
            WorkoutPlannerExercise(
                name: "New Exercise",
                sets: 3,
                reps: "8-10",
                notes: nil,
                isCardio: false
            )
        )
    }

    var exerciseDrafts: [WorkoutPlannerExerciseDraft] {
        if isRestDay { return [] }
        return parsedExercises.map(WorkoutPlannerExerciseDraft.init(exercise:))
    }

    mutating func replaceExercises(with exercises: [WorkoutPlannerExerciseDraft]) {
        let normalized = exercises
            .map(\.normalized)
            .filter { !$0.name.isEmpty }

        exerciseLines = normalized
            .map { draft in
                Self.line(
                    for: WorkoutPlannerExercise(
                        name: draft.name,
                        sets: draft.sets,
                        reps: draft.reps,
                        notes: draft.notes.isEmpty ? nil : draft.notes,
                        isCardio: draft.isCardio
                    )
                )
            }
            .joined(separator: "\n")

        if normalized.isEmpty, !isRestDay {
            addEmptyExercise()
        }
    }

    func makeOverride(dateKey: String) -> WorkoutPlannerOverride {
        WorkoutPlannerOverride(
            dateKey: dateKey,
            title: trimmedTitle,
            focus: trimmedFocus,
            muscleGroups: parsedMuscleGroups,
            durationMinutes: max(10, Int(durationMinutes.rounded())),
            notes: trimmedNotes,
            isRestDay: isRestDay,
            exercises: isRestDay ? [] : parsedExercises
        )
    }

    private var trimmedTitle: String {
        let value = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? "Custom Workout" : value
    }

    private var trimmedFocus: String {
        let value = focus.trimmingCharacters(in: .whitespacesAndNewlines)
        if !value.isEmpty { return value }
        if !parsedMuscleGroups.isEmpty { return parsedMuscleGroups.joined(separator: " · ") }
        return isRestDay ? "Recovery" : "Custom session"
    }

    private var trimmedNotes: String? {
        let value = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    private var parsedMuscleGroups: [String] {
        let normalized = muscleGroupsText
            .replacingOccurrences(of: "\n", with: ",")
            .replacingOccurrences(of: "·", with: ",")
        return normalized
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private var parsedExercises: [WorkoutPlannerExercise] {
        let lines = exerciseLines
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if lines.isEmpty {
            return [
                WorkoutPlannerExercise(
                    name: trimmedTitle,
                    sets: 1,
                    reps: "Planned",
                    notes: trimmedNotes,
                    isCardio: false
                )
            ]
        }

        return lines.map(Self.parseExerciseLine(_:))
    }

    private static func parseExerciseLine(_ line: String) -> WorkoutPlannerExercise {
        let parts = line.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        let name = parts.first.flatMap { $0.isEmpty ? nil : $0 } ?? "Exercise"
        let volume = parts.count > 1 ? parts[1] : "3xCustom"
        let notes = parts.count > 2 ? parts[2] : nil
        let (sets, reps) = parseVolume(volume)
        let lowercased = "\(name) \(notes ?? "")".lowercased()
        let isCardio = ["run", "cardio", "bike", "row", "swim", "ruck", "interval"].contains { lowercased.contains($0) }
        return WorkoutPlannerExercise(name: name, sets: sets, reps: reps, notes: notes, isCardio: isCardio)
    }

    private static func parseVolume(_ volume: String) -> (Int, String) {
        let normalized = volume.lowercased().replacingOccurrences(of: " ", with: "")
        let pieces = normalized.components(separatedBy: "x")
        if pieces.count == 2, let sets = Int(pieces[0]), !pieces[1].isEmpty {
            return (max(1, sets), pieces[1].uppercased())
        }
        return (3, volume.isEmpty ? "Custom" : volume)
    }

    private static func line(for exercise: ExerciseEntry) -> String {
        var line = "\(exercise.name) | \(exercise.sets)x\(exercise.reps)"
        if let notes = exercise.notes, !notes.isEmpty {
            line += " | \(notes)"
        }
        return line
    }

    private static func line(for exercise: WorkoutPlannerExercise) -> String {
        var line = "\(exercise.name) | \(exercise.sets)x\(exercise.reps)"
        if let notes = exercise.notes, !notes.isEmpty {
            line += " | \(notes)"
        }
        return line
    }
}

struct WorkoutPlannerExerciseDraft: Identifiable, Hashable {
    let id: UUID
    var name: String
    var sets: Int
    var reps: String
    var notes: String
    var isCardio: Bool

    init(
        id: UUID = UUID(),
        name: String,
        sets: Int = 3,
        reps: String = "8-10",
        notes: String = "",
        isCardio: Bool = false
    ) {
        self.id = id
        self.name = name
        self.sets = sets
        self.reps = reps
        self.notes = notes
        self.isCardio = isCardio
    }

    init(exercise: WorkoutPlannerExercise) {
        self.init(
            name: exercise.name,
            sets: exercise.sets,
            reps: exercise.reps,
            notes: exercise.notes ?? "",
            isCardio: exercise.isCardio
        )
    }

    var normalized: WorkoutPlannerExerciseDraft {
        WorkoutPlannerExerciseDraft(
            id: id,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            sets: max(1, sets),
            reps: reps.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Custom" : reps.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            isCardio: isCardio
        )
    }
}

enum WorkoutPlannerTemplatePreset: String, CaseIterable, Hashable, Identifiable {
    case pushDay = "Push Day"
    case pullDay = "Pull Day"
    case legDay = "Leg Day"
    case fullBody = "Full Body"
    case longRun = "Long Run"
    case recovery = "Recovery"

    var id: String { rawValue }

    var title: String { rawValue }

    var focus: String {
        switch self {
        case .pushDay:
            return "Chest · Shoulders · Triceps"
        case .pullDay:
            return "Back · Biceps · Rear Delts"
        case .legDay:
            return "Quads · Glutes · Hamstrings"
        case .fullBody:
            return "Full-body strength"
        case .longRun:
            return "Endurance · Aerobic base"
        case .recovery:
            return "Recovery · Mobility · Reset"
        }
    }

    var muscleGroups: [String] {
        switch self {
        case .pushDay:
            return ["Chest", "Shoulders", "Triceps"]
        case .pullDay:
            return ["Back", "Biceps", "Rear Delts"]
        case .legDay:
            return ["Quads", "Glutes", "Hamstrings"]
        case .fullBody:
            return ["Chest", "Back", "Legs", "Core"]
        case .longRun:
            return ["Endurance", "Cardio"]
        case .recovery:
            return ["Recovery", "Mobility"]
        }
    }

    var durationMinutes: Int {
        switch self {
        case .pushDay, .pullDay, .legDay, .fullBody:
            return 60
        case .longRun:
            return 75
        case .recovery:
            return 30
        }
    }

    var notes: String? {
        switch self {
        case .pushDay:
            return "Start with your main press, then add shoulder and triceps volume."
        case .pullDay:
            return "Focus on strong pulling mechanics and finish with arm work."
        case .legDay:
            return "Open with your main lower-body lift and finish with accessories."
        case .fullBody:
            return "Keep intensity balanced across the whole session."
        case .longRun:
            return "Stay controlled early and finish strong."
        case .recovery:
            return "Use this day to restore, not to chase fatigue."
        }
    }

    var isRestDay: Bool {
        self == .recovery
    }

    var exercises: [WorkoutPlannerExercise] {
        switch self {
        case .pushDay:
            return [
                WorkoutPlannerExercise(name: "Bench Press", sets: 4, reps: "6-8", notes: "Main lift"),
                WorkoutPlannerExercise(name: "Incline Dumbbell Press", sets: 3, reps: "8-10"),
                WorkoutPlannerExercise(name: "Overhead Press", sets: 3, reps: "8-10"),
                WorkoutPlannerExercise(name: "Lateral Raise", sets: 3, reps: "12-15"),
                WorkoutPlannerExercise(name: "Rope Pushdown", sets: 3, reps: "12-15"),
            ]
        case .pullDay:
            return [
                WorkoutPlannerExercise(name: "Pull-Ups", sets: 4, reps: "AMRAP", notes: "Add weight if needed"),
                WorkoutPlannerExercise(name: "Barbell Row", sets: 4, reps: "6-8"),
                WorkoutPlannerExercise(name: "Lat Pulldown", sets: 3, reps: "10-12"),
                WorkoutPlannerExercise(name: "Face Pull", sets: 3, reps: "15"),
                WorkoutPlannerExercise(name: "EZ-Bar Curl", sets: 3, reps: "10-12"),
            ]
        case .legDay:
            return [
                WorkoutPlannerExercise(name: "Back Squat", sets: 4, reps: "5-8", notes: "Main lift"),
                WorkoutPlannerExercise(name: "Romanian Deadlift", sets: 3, reps: "8-10"),
                WorkoutPlannerExercise(name: "Walking Lunge", sets: 3, reps: "10/side"),
                WorkoutPlannerExercise(name: "Leg Curl", sets: 3, reps: "12"),
                WorkoutPlannerExercise(name: "Calf Raise", sets: 4, reps: "15-20"),
            ]
        case .fullBody:
            return [
                WorkoutPlannerExercise(name: "Squat", sets: 3, reps: "5-8"),
                WorkoutPlannerExercise(name: "Bench Press", sets: 3, reps: "6-8"),
                WorkoutPlannerExercise(name: "Pull-Ups", sets: 3, reps: "AMRAP"),
                WorkoutPlannerExercise(name: "Deadlift", sets: 3, reps: "3-5"),
                WorkoutPlannerExercise(name: "Plank", sets: 3, reps: "60 sec"),
            ]
        case .longRun:
            return [
                WorkoutPlannerExercise(name: "Easy Warm-Up", sets: 1, reps: "10 min", notes: "Build gradually", isCardio: true),
                WorkoutPlannerExercise(name: "Long Run", sets: 1, reps: "45-60 min", notes: "Steady pace", isCardio: true),
                WorkoutPlannerExercise(name: "Walk Cooldown", sets: 1, reps: "10 min", isCardio: true),
            ]
        case .recovery:
            return []
        }
    }
}

enum ExerciseLibraryCategory: String, CaseIterable, Hashable, Identifiable {
    case upper = "Upper"
    case lower = "Lower"
    case cardio = "Cardio"
    case recovery = "Recovery"

    var id: String { rawValue }
}

struct ExerciseLibraryItem: Identifiable, Hashable {
    let id = UUID()
    let category: ExerciseLibraryCategory
    let exercise: WorkoutPlannerExercise
}

enum ExerciseLibraryCatalog {
    static let items: [ExerciseLibraryItem] = [
        ExerciseLibraryItem(category: .upper, exercise: WorkoutPlannerExercise(name: "Bench Press", sets: 4, reps: "6-8", notes: "Main press")),
        ExerciseLibraryItem(category: .upper, exercise: WorkoutPlannerExercise(name: "Overhead Press", sets: 3, reps: "8-10")),
        ExerciseLibraryItem(category: .upper, exercise: WorkoutPlannerExercise(name: "Pull-Ups", sets: 4, reps: "AMRAP", notes: "Add weight if needed")),
        ExerciseLibraryItem(category: .upper, exercise: WorkoutPlannerExercise(name: "Barbell Row", sets: 4, reps: "6-8")),
        ExerciseLibraryItem(category: .upper, exercise: WorkoutPlannerExercise(name: "Lateral Raise", sets: 3, reps: "12-15")),
        ExerciseLibraryItem(category: .lower, exercise: WorkoutPlannerExercise(name: "Back Squat", sets: 4, reps: "5-8", notes: "Main lift")),
        ExerciseLibraryItem(category: .lower, exercise: WorkoutPlannerExercise(name: "Romanian Deadlift", sets: 3, reps: "8-10")),
        ExerciseLibraryItem(category: .lower, exercise: WorkoutPlannerExercise(name: "Walking Lunge", sets: 3, reps: "10/side")),
        ExerciseLibraryItem(category: .lower, exercise: WorkoutPlannerExercise(name: "Leg Curl", sets: 3, reps: "12")),
        ExerciseLibraryItem(category: .lower, exercise: WorkoutPlannerExercise(name: "Calf Raise", sets: 4, reps: "15-20")),
        ExerciseLibraryItem(category: .cardio, exercise: WorkoutPlannerExercise(name: "Long Run", sets: 1, reps: "45-60 min", notes: "Steady pace", isCardio: true)),
        ExerciseLibraryItem(category: .cardio, exercise: WorkoutPlannerExercise(name: "Tempo Run", sets: 1, reps: "20-30 min", notes: "Threshold effort", isCardio: true)),
        ExerciseLibraryItem(category: .cardio, exercise: WorkoutPlannerExercise(name: "Bike Intervals", sets: 8, reps: "1 min", notes: "Hard/easy alternation", isCardio: true)),
        ExerciseLibraryItem(category: .cardio, exercise: WorkoutPlannerExercise(name: "Ruck March", sets: 1, reps: "45 min", notes: "Loaded movement", isCardio: true)),
        ExerciseLibraryItem(category: .recovery, exercise: WorkoutPlannerExercise(name: "Mobility Flow", sets: 1, reps: "15 min", notes: "Hips, shoulders, ankles")),
        ExerciseLibraryItem(category: .recovery, exercise: WorkoutPlannerExercise(name: "Walk", sets: 1, reps: "20 min", notes: "Easy pace", isCardio: true)),
        ExerciseLibraryItem(category: .recovery, exercise: WorkoutPlannerExercise(name: "Plank", sets: 3, reps: "60 sec", notes: "Core stability")),
    ]
}

// MARK: - Exercise Entry
struct ExerciseEntry: Identifiable {
    let id = UUID()
    let name: String
    let sets: Int
    let reps: String      // "8-12" or "Max" or "60 sec"
    let notes: String?
    let isCardio: Bool
}

// MARK: - Workout Library (static data)
enum WorkoutLibrary {
    static let beginnerFullBodyA: [ExerciseEntry] = [
        ExerciseEntry(name: "Goblet Squat", sets: 3, reps: "8-10", notes: "Learn depth and bracing", isCardio: false),
        ExerciseEntry(name: "Push-Ups", sets: 3, reps: "AMRAP", notes: "Use incline if needed", isCardio: false),
        ExerciseEntry(name: "Supported Row", sets: 3, reps: "10-12", notes: nil, isCardio: false),
        ExerciseEntry(name: "Split Squat", sets: 2, reps: "8/side", notes: nil, isCardio: false),
        ExerciseEntry(name: "Dead Bug", sets: 3, reps: "10/side", notes: "Core control", isCardio: false),
    ]
    static let beginnerFullBodyB: [ExerciseEntry] = [
        ExerciseEntry(name: "Romanian Deadlift", sets: 3, reps: "8-10", notes: "Posterior chain", isCardio: false),
        ExerciseEntry(name: "Dumbbell Bench Press", sets: 3, reps: "8-10", notes: nil, isCardio: false),
        ExerciseEntry(name: "Lat Pulldown", sets: 3, reps: "10-12", notes: nil, isCardio: false),
        ExerciseEntry(name: "Step-Up", sets: 2, reps: "10/side", notes: nil, isCardio: false),
        ExerciseEntry(name: "Plank", sets: 3, reps: "30-45 sec", notes: nil, isCardio: false),
    ]
    static let beginnerFullBodyC: [ExerciseEntry] = [
        ExerciseEntry(name: "Trap Bar Deadlift", sets: 3, reps: "5-6", notes: "Technique first", isCardio: false),
        ExerciseEntry(name: "Overhead Press", sets: 3, reps: "8-10", notes: nil, isCardio: false),
        ExerciseEntry(name: "Seated Cable Row", sets: 3, reps: "10-12", notes: nil, isCardio: false),
        ExerciseEntry(name: "Walking Lunge", sets: 2, reps: "10/side", notes: nil, isCardio: false),
        ExerciseEntry(name: "Farmer Carry", sets: 3, reps: "30 m", notes: "Grip and trunk", isCardio: false),
    ]
    static let pushDay: [ExerciseEntry] = [
        ExerciseEntry(name: "Bench Press",          sets: 4, reps: "8-10",    notes: "Compound push",           isCardio: false),
        ExerciseEntry(name: "Overhead Press",        sets: 3, reps: "8-10",    notes: nil,                       isCardio: false),
        ExerciseEntry(name: "Incline Dumbbell Press",sets: 3, reps: "10-12",   notes: nil,                       isCardio: false),
        ExerciseEntry(name: "Lateral Raises",        sets: 3, reps: "12-15",   notes: nil,                       isCardio: false),
        ExerciseEntry(name: "Tricep Pushdown",       sets: 3, reps: "12-15",   notes: nil,                       isCardio: false),
        ExerciseEntry(name: "Push-Ups",              sets: 3, reps: "Max",     notes: "PT prep",                 isCardio: false),
    ]
    static let pullDay: [ExerciseEntry] = [
        ExerciseEntry(name: "Pull-Ups / Lat Pulldown", sets: 4, reps: "6-10",  notes: "PT prep",                isCardio: false),
        ExerciseEntry(name: "Barbell Row",             sets: 4, reps: "8-10",   notes: nil,                      isCardio: false),
        ExerciseEntry(name: "Dumbbell Row",            sets: 3, reps: "10-12",  notes: nil,                      isCardio: false),
        ExerciseEntry(name: "Face Pulls",              sets: 3, reps: "15-20",  notes: "Shoulder health",        isCardio: false),
        ExerciseEntry(name: "Bicep Curls",             sets: 3, reps: "12-15",  notes: nil,                      isCardio: false),
    ]
    static let legDay: [ExerciseEntry] = [
        ExerciseEntry(name: "Squat",                  sets: 4, reps: "6-8",    notes: "Primary mover",          isCardio: false),
        ExerciseEntry(name: "Romanian Deadlift",       sets: 3, reps: "8-10",   notes: nil,                      isCardio: false),
        ExerciseEntry(name: "Leg Press",               sets: 3, reps: "10-12",  notes: nil,                      isCardio: false),
        ExerciseEntry(name: "Walking Lunges",          sets: 3, reps: "20 steps",notes: nil,                     isCardio: false),
        ExerciseEntry(name: "Plank",                   sets: 3, reps: "60 sec", notes: "PT prep — hold strong", isCardio: false),
    ]
    static let upperDay: [ExerciseEntry] = [
        ExerciseEntry(name: "Bench Press",         sets: 4, reps: "6-8",    notes: nil,              isCardio: false),
        ExerciseEntry(name: "Pull-Ups",            sets: 4, reps: "Max",    notes: "PT prep",        isCardio: false),
        ExerciseEntry(name: "Overhead Press",      sets: 3, reps: "8-10",   notes: nil,              isCardio: false),
        ExerciseEntry(name: "Dumbbell Row",        sets: 3, reps: "10-12",  notes: nil,              isCardio: false),
        ExerciseEntry(name: "Push-Ups",            sets: 3, reps: "Max",    notes: "PT prep",        isCardio: false),
        ExerciseEntry(name: "Bicep + Tricep SS",   sets: 3, reps: "12",     notes: "Superset",       isCardio: false),
    ]
    static let upperPowerDay: [ExerciseEntry] = [
        ExerciseEntry(name: "Bench Press", sets: 5, reps: "3-5", notes: "Heavy top sets", isCardio: false),
        ExerciseEntry(name: "Weighted Pull-Up", sets: 4, reps: "4-6", notes: nil, isCardio: false),
        ExerciseEntry(name: "Barbell Row", sets: 4, reps: "5-6", notes: nil, isCardio: false),
        ExerciseEntry(name: "Overhead Press", sets: 3, reps: "5-6", notes: nil, isCardio: false),
        ExerciseEntry(name: "Chest-Supported Row", sets: 3, reps: "8-10", notes: nil, isCardio: false),
    ]
    static let lowerDay: [ExerciseEntry] = [
        ExerciseEntry(name: "Squat",               sets: 4, reps: "8-10",   notes: nil,              isCardio: false),
        ExerciseEntry(name: "Deadlift",            sets: 3, reps: "5-6",    notes: "AFT prep",       isCardio: false),
        ExerciseEntry(name: "Leg Curl",            sets: 3, reps: "10-12",  notes: nil,              isCardio: false),
        ExerciseEntry(name: "Calf Raises",         sets: 4, reps: "15-20",  notes: nil,              isCardio: false),
        ExerciseEntry(name: "Plank Holds",         sets: 3, reps: "60 sec", notes: "PT prep",        isCardio: false),
    ]
    static let lowerPowerDay: [ExerciseEntry] = [
        ExerciseEntry(name: "Back Squat", sets: 5, reps: "3-5", notes: "Heavy sets", isCardio: false),
        ExerciseEntry(name: "Deadlift", sets: 4, reps: "3-5", notes: "Strength focus", isCardio: false),
        ExerciseEntry(name: "Bulgarian Split Squat", sets: 3, reps: "8/side", notes: nil, isCardio: false),
        ExerciseEntry(name: "Leg Curl", sets: 3, reps: "10-12", notes: nil, isCardio: false),
        ExerciseEntry(name: "Hanging Knee Raise", sets: 3, reps: "12-15", notes: nil, isCardio: false),
    ]
    static let fullBodyDay: [ExerciseEntry] = [
        ExerciseEntry(name: "Squat",               sets: 3, reps: "8",      notes: nil,              isCardio: false),
        ExerciseEntry(name: "Bench Press",         sets: 3, reps: "8",      notes: nil,              isCardio: false),
        ExerciseEntry(name: "Deadlift",            sets: 3, reps: "5",      notes: nil,              isCardio: false),
        ExerciseEntry(name: "Pull-Ups",            sets: 3, reps: "Max",    notes: "PT prep",        isCardio: false),
        ExerciseEntry(name: "Overhead Press",      sets: 3, reps: "8",      notes: nil,              isCardio: false),
        ExerciseEntry(name: "Plank",               sets: 3, reps: "60 sec", notes: "PT prep",        isCardio: false),
    ]
    static let cardioDay: [ExerciseEntry] = [
        ExerciseEntry(name: "2-Mile Run",          sets: 1, reps: "Timed",  notes: "Track your pace", isCardio: true),
        ExerciseEntry(name: "Ruck (optional)",     sets: 1, reps: "45 min", notes: "12 mi pace",     isCardio: true),
    ]
    static let easyRunDay: [ExerciseEntry] = [
        ExerciseEntry(name: "Easy Run", sets: 1, reps: "25-40 min", notes: "Conversational pace", isCardio: true),
        ExerciseEntry(name: "Mobility Cooldown", sets: 1, reps: "10 min", notes: "Hips and calves", isCardio: false),
    ]
    static let tempoRunDay: [ExerciseEntry] = [
        ExerciseEntry(name: "Tempo Run", sets: 1, reps: "20-30 min", notes: "Threshold effort", isCardio: true),
        ExerciseEntry(name: "Strides", sets: 6, reps: "20 sec", notes: "Fast relaxed finishers", isCardio: true),
        ExerciseEntry(name: "Side Plank", sets: 3, reps: "30 sec/side", notes: "Core stability", isCardio: false),
    ]
    static let longRunDay: [ExerciseEntry] = [
        ExerciseEntry(name: "Long Run", sets: 1, reps: "45-75 min", notes: "Steady aerobic effort", isCardio: true),
        ExerciseEntry(name: "Walk Cooldown", sets: 1, reps: "10 min", notes: nil, isCardio: true),
    ]
    static let shoulderDay: [ExerciseEntry] = [
        ExerciseEntry(name: "Overhead Press",      sets: 4, reps: "6-8",    notes: "Primary press",      isCardio: false),
        ExerciseEntry(name: "Arnold Press",        sets: 3, reps: "8-10",   notes: nil,                  isCardio: false),
        ExerciseEntry(name: "Lateral Raises",      sets: 4, reps: "12-15",  notes: nil,                  isCardio: false),
        ExerciseEntry(name: "Rear Delt Fly",       sets: 3, reps: "12-15",  notes: nil,                  isCardio: false),
        ExerciseEntry(name: "Face Pulls",          sets: 3, reps: "15-20",  notes: "Shoulder health",    isCardio: false),
    ]
    static let armDay: [ExerciseEntry] = [
        ExerciseEntry(name: "Close-Grip Bench",    sets: 3, reps: "8-10",   notes: "Triceps focus",      isCardio: false),
        ExerciseEntry(name: "Barbell Curl",        sets: 4, reps: "10-12",  notes: nil,                  isCardio: false),
        ExerciseEntry(name: "Hammer Curl",         sets: 3, reps: "10-12",  notes: nil,                  isCardio: false),
        ExerciseEntry(name: "Skull Crushers",      sets: 3, reps: "10-12",  notes: nil,                  isCardio: false),
        ExerciseEntry(name: "Farmer Carry",        sets: 4, reps: "40 m",   notes: "Grip and trunk",     isCardio: false),
    ]
    static let speedDay: [ExerciseEntry] = [
        ExerciseEntry(name: "400m Repeats",        sets: 6, reps: "400 m",  notes: "Fast with equal rest", isCardio: true),
        ExerciseEntry(name: "Sled Push / Drag",    sets: 5, reps: "20 m",   notes: "Power and conditioning", isCardio: false),
        ExerciseEntry(name: "Burpee Intervals",    sets: 5, reps: "45 sec", notes: "Hard effort",        isCardio: true),
    ]
    static let enduranceDay: [ExerciseEntry] = [
        ExerciseEntry(name: "Long Run",            sets: 1, reps: "40-60 min", notes: "Zone 2 effort",  isCardio: true),
        ExerciseEntry(name: "Ruck March",          sets: 1, reps: "30-60 min", notes: "Loaded movement", isCardio: true),
        ExerciseEntry(name: "Mobility Cooldown",   sets: 1, reps: "10 min",    notes: "Hips and ankles", isCardio: false),
    ]
    static let pushHypertrophyDay: [ExerciseEntry] = [
        ExerciseEntry(name: "Incline Dumbbell Press", sets: 4, reps: "8-12", notes: nil, isCardio: false),
        ExerciseEntry(name: "Machine Chest Press", sets: 3, reps: "10-12", notes: nil, isCardio: false),
        ExerciseEntry(name: "Seated Shoulder Press", sets: 3, reps: "8-10", notes: nil, isCardio: false),
        ExerciseEntry(name: "Cable Fly", sets: 3, reps: "12-15", notes: nil, isCardio: false),
        ExerciseEntry(name: "Rope Pushdown", sets: 3, reps: "12-15", notes: nil, isCardio: false),
    ]
    static let pullHypertrophyDay: [ExerciseEntry] = [
        ExerciseEntry(name: "Lat Pulldown", sets: 4, reps: "8-12", notes: nil, isCardio: false),
        ExerciseEntry(name: "Chest-Supported Row", sets: 3, reps: "10-12", notes: nil, isCardio: false),
        ExerciseEntry(name: "Cable Row", sets: 3, reps: "10-12", notes: nil, isCardio: false),
        ExerciseEntry(name: "Rear Delt Fly", sets: 3, reps: "12-15", notes: nil, isCardio: false),
        ExerciseEntry(name: "EZ-Bar Curl", sets: 3, reps: "10-12", notes: nil, isCardio: false),
    ]
    static let legHypertrophyDay: [ExerciseEntry] = [
        ExerciseEntry(name: "Hack Squat", sets: 4, reps: "8-12", notes: nil, isCardio: false),
        ExerciseEntry(name: "Romanian Deadlift", sets: 3, reps: "8-10", notes: nil, isCardio: false),
        ExerciseEntry(name: "Leg Extension", sets: 3, reps: "12-15", notes: nil, isCardio: false),
        ExerciseEntry(name: "Leg Curl", sets: 3, reps: "12-15", notes: nil, isCardio: false),
        ExerciseEntry(name: "Standing Calf Raise", sets: 4, reps: "15-20", notes: nil, isCardio: false),
    ]
    static let strengthADay: [ExerciseEntry] = [
        ExerciseEntry(name: "Back Squat", sets: 5, reps: "5", notes: nil, isCardio: false),
        ExerciseEntry(name: "Bench Press", sets: 5, reps: "5", notes: nil, isCardio: false),
        ExerciseEntry(name: "Barbell Row", sets: 4, reps: "6-8", notes: nil, isCardio: false),
        ExerciseEntry(name: "Plank", sets: 3, reps: "60 sec", notes: nil, isCardio: false),
    ]
    static let strengthBDay: [ExerciseEntry] = [
        ExerciseEntry(name: "Deadlift", sets: 5, reps: "3", notes: nil, isCardio: false),
        ExerciseEntry(name: "Overhead Press", sets: 4, reps: "5", notes: nil, isCardio: false),
        ExerciseEntry(name: "Pull-Ups", sets: 4, reps: "AMRAP", notes: "Add load if strong", isCardio: false),
        ExerciseEntry(name: "Walking Lunge", sets: 3, reps: "10/side", notes: nil, isCardio: false),
    ]
    static let strengthCDay: [ExerciseEntry] = [
        ExerciseEntry(name: "Front Squat", sets: 4, reps: "6", notes: nil, isCardio: false),
        ExerciseEntry(name: "Incline Bench Press", sets: 4, reps: "6-8", notes: nil, isCardio: false),
        ExerciseEntry(name: "Farmer Carry", sets: 4, reps: "40 m", notes: "Grip and trunk", isCardio: false),
        ExerciseEntry(name: "Hanging Knee Raise", sets: 3, reps: "12-15", notes: nil, isCardio: false),
    ]
    static let conditioningDay: [ExerciseEntry] = [
        ExerciseEntry(name: "Bike or Row Intervals", sets: 8, reps: "1 min", notes: "Hard / easy alternation", isCardio: true),
        ExerciseEntry(name: "Sled Push", sets: 6, reps: "20 m", notes: nil, isCardio: false),
        ExerciseEntry(name: "Battle Ropes", sets: 6, reps: "30 sec", notes: nil, isCardio: true),
        ExerciseEntry(name: "Carry Complex", sets: 4, reps: "40 m", notes: nil, isCardio: false),
    ]
    static let tacticalDay: [ExerciseEntry] = [
        ExerciseEntry(name: "Sprint-Drag-Carry",   sets: 4, reps: "Practice", notes: "AFT skill work",   isCardio: true),
        ExerciseEntry(name: "Push-Ups",            sets: 4, reps: "Max",      notes: "Short rest",       isCardio: false),
        ExerciseEntry(name: "Plank",               sets: 4, reps: "60 sec",   notes: "Core endurance",   isCardio: false),
        ExerciseEntry(name: "Shuttle Runs",        sets: 6, reps: "20 m",     notes: "Change of direction", isCardio: true),
    ]
    static let milPTDay: [ExerciseEntry] = [
        ExerciseEntry(name: "Push-Ups",            sets: 5, reps: "Max",    notes: "1-min sets",     isCardio: false),
        ExerciseEntry(name: "Sit-Ups / Plank",     sets: 5, reps: "Max",    notes: "PT standard",   isCardio: false),
        ExerciseEntry(name: "Pull-Ups",            sets: 4, reps: "Max",    notes: nil,              isCardio: false),
        ExerciseEntry(name: "1.5-Mile Time Trial", sets: 1, reps: "Timed",  notes: nil,              isCardio: true),
    ]
}

// MARK: ─────────────────────────────────────────────────────
//  BRANCH PT STANDARDS
//  Each branch has its own test events, scoring, and tiers.
// ─────────────────────────────────────────────────────────

// MARK: - PT Test Branch Router
struct BranchPTConfig {
    let branch: MilitaryBranch
    let testName: String
    let events: [PTEvent]
    let maxScore: Int
    let passingScore: Int
    let tiers: [PTTier]
    let officialRef: String

    static func config(for branch: MilitaryBranch) -> BranchPTConfig {
        switch branch {
        case .army:       return .army
        case .airForce:   return .airForce
        case .navy:       return .navy
        case .marines:    return .marines
        case .spaceForce: return .spaceForce
        case .coastGuard: return .coastGuard
        }
    }
}

// MARK: - PT Event
struct PTEvent: Identifiable {
    let id = UUID()
    let name: String
    let unit: String             // "reps", "secs", "mm:ss", "lbs", "meters"
    let icon: String
    let minValue: Double
    let maxValue: Double
    let higherIsBetter: Bool     // false for timed events
    let pointsMax: Int           // max contribution to total
    let description: String

    func score(for rawValue: Double) -> Int {
        // Linear interpolation — branches have lookup tables in reality.
        // This is a simplified linear approximation for self-tracking.
        guard rawValue >= minValue else { return 0 }
        let clamped = min(rawValue, maxValue)
        let progress: Double
        if higherIsBetter {
            progress = (clamped - minValue) / (maxValue - minValue)
        } else {
            // Lower is better (timed events): invert
            progress = (maxValue - clamped) / (maxValue - minValue)
        }
        return Int((progress * Double(pointsMax)).rounded())
    }
}

// MARK: - PT Tier
struct PTTier: Identifiable {
    let id = UUID()
    let name: String
    let minScore: Int
    let color: String
    let badge: String

    static func tier(for score: Int, tiers: [PTTier]) -> PTTier? {
        tiers.filter { score >= $0.minScore }.max(by: { $0.minScore < $1.minScore })
    }
}

// MARK: - PT Score Record
struct PTScoreRecord: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let branch: String
    let testName: String
    var eventScores: [String: Double]   // event name → raw value
    var totalScore: Int
    var passed: Bool
    var tierName: String?
    var notes: String?
    let recordedAt: Date

    enum CodingKeys: String, CodingKey {
        case id; case userId = "user_id"; case branch
        case testName = "test_name"
        case eventScores = "event_scores"
        case totalScore = "total_score"; case passed
        case tierName = "tier_name"; case notes
        case recordedAt = "recorded_at"
    }
}

// MARK: ─ Army AFT Config ─────────────────────────────────────
extension BranchPTConfig {
    static let army = BranchPTConfig(
        branch: .army,
        testName: "Army Fitness Test (AFT)",
        events: [
            PTEvent(name: "Deadlift",               unit: "lbs",  icon: "arrow.up.circle.fill",    minValue: 80,   maxValue: 340,  higherIsBetter: true,  pointsMax: 100, description: "Trap bar deadlift. Tests lower body strength."),
            PTEvent(name: "Hand-Release Push-Up",   unit: "reps", icon: "figure.push.ups",          minValue: 10,   maxValue: 60,   higherIsBetter: true,  pointsMax: 100, description: "Push-up with full hand release at bottom. Tests muscular endurance."),
            PTEvent(name: "Sprint-Drag-Carry",      unit: "secs", icon: "figure.run",               minValue: 98,   maxValue: 210,  higherIsBetter: false, pointsMax: 100, description: "25m sprint, drag, lateral, carry, sprint. Tests combat readiness."),
            PTEvent(name: "Plank",                  unit: "secs", icon: "figure.core.training",     minValue: 60,   maxValue: 270,  higherIsBetter: true,  pointsMax: 100, description: "Forearm plank hold. Tests core endurance."),
            PTEvent(name: "2-Mile Run",             unit: "secs", icon: "timer",                    minValue: 780,  maxValue: 1620, higherIsBetter: false, pointsMax: 100, description: "2-mile aerobic run. Tests cardiovascular endurance."),
        ],
        maxScore: 500,
        passingScore: 300,
        tiers: [
            PTTier(name: "Gold",           minScore: 450, color: "#FFD700", badge: "medal.fill"),
            PTTier(name: "Silver",         minScore: 400, color: "#C0C0C0", badge: "medal.fill"),
            PTTier(name: "Passed",         minScore: 300, color: "#34C759", badge: "checkmark.circle.fill"),
            PTTier(name: "Not Qualified",  minScore: 0,   color: "#FF453A", badge: "xmark.circle.fill"),
        ],
        officialRef: "AR 670-1 / TRADOC Pam 350-4"
    )
}

// MARK: ─ Air Force PFA Config ────────────────────────────────
extension BranchPTConfig {
    static let airForce = BranchPTConfig(
        branch: .airForce,
        testName: "Air Force Physical Fitness Assessment (PFA)",
        events: [
            PTEvent(name: "Push-Ups (1 min)",   unit: "reps", icon: "figure.push.ups",  minValue: 27,  maxValue: 77,  higherIsBetter: true,  pointsMax: 20, description: "1-minute push-up test. Tests muscular endurance. Min 27 for males."),
            PTEvent(name: "Sit-Ups (1 min)",    unit: "reps", icon: "figure.core.training", minValue: 42, maxValue: 62, higherIsBetter: true, pointsMax: 20, description: "1-minute sit-up test. Tests core endurance."),
            PTEvent(name: "1.5-Mile Run",       unit: "secs", icon: "timer",             minValue: 780, maxValue: 1680, higherIsBetter: false, pointsMax: 60, description: "1.5-mile run. 60% of composite score. Critical for passing."),
        ],
        maxScore: 100,
        passingScore: 75,
        tiers: [
            PTTier(name: "Excellent",   minScore: 90, color: "#FFD700", badge: "star.fill"),
            PTTier(name: "Satisfactory",minScore: 75, color: "#34C759", badge: "checkmark.circle.fill"),
            PTTier(name: "Unsatisfactory", minScore: 0, color: "#FF453A", badge: "xmark.circle.fill"),
        ],
        officialRef: "AFI 36-2905"
    )
}

// MARK: ─ Navy PRT Config ─────────────────────────────────────
extension BranchPTConfig {
    static let navy = BranchPTConfig(
        branch: .navy,
        testName: "Navy Physical Readiness Test (PRT)",
        events: [
            PTEvent(name: "Push-Ups (2 min)",   unit: "reps", icon: "figure.push.ups",      minValue: 42,   maxValue: 100, higherIsBetter: true,  pointsMax: 33, description: "2-minute push-up test. Min 42 reps for males 20–24."),
            PTEvent(name: "Plank Hold",          unit: "secs", icon: "figure.core.training",  minValue: 60,   maxValue: 300, higherIsBetter: true,  pointsMax: 34, description: "Forearm plank hold. Alternative to curl-ups."),
            PTEvent(name: "1.5-Mile Run",        unit: "secs", icon: "timer",                 minValue: 522,  maxValue: 1380, higherIsBetter: false, pointsMax: 33, description: "1.5-mile timed run. 8:42 outstanding for males."),
        ],
        maxScore: 100,
        passingScore: 60,
        tiers: [
            PTTier(name: "Outstanding",  minScore: 90, color: "#FFD700", badge: "star.fill"),
            PTTier(name: "Excellent",    minScore: 80, color: "#A29BFE", badge: "medal.fill"),
            PTTier(name: "Good",         minScore: 70, color: "#45B7D1", badge: "hand.thumbsup.fill"),
            PTTier(name: "Satisfactory", minScore: 60, color: "#34C759", badge: "checkmark.circle.fill"),
            PTTier(name: "Probationary", minScore: 0,  color: "#FF453A", badge: "exclamationmark.circle.fill"),
        ],
        officialRef: "OPNAVINST 6110.1J"
    )
}

// MARK: ─ Marines PFT Config ──────────────────────────────────
extension BranchPTConfig {
    static let marines = BranchPTConfig(
        branch: .marines,
        testName: "Marine Corps Physical Fitness Test (PFT)",
        events: [
            PTEvent(name: "Pull-Ups",     unit: "reps", icon: "figure.strengthtraining.traditional", minValue: 3,   maxValue: 23,  higherIsBetter: true,  pointsMax: 100, description: "Dead-hang pull-ups. No kipping. Max 23 for males."),
            PTEvent(name: "Plank",        unit: "secs", icon: "figure.core.training",                minValue: 65,  maxValue: 240, higherIsBetter: true,  pointsMax: 100, description: "Forearm plank. Replaced crunches. Max 4 min = 100 pts."),
            PTEvent(name: "3-Mile Run",   unit: "secs", icon: "timer",                               minValue: 1080, maxValue: 2700,higherIsBetter: false, pointsMax: 100, description: "3-mile run. 18:00 max for males. Key performance indicator."),
        ],
        maxScore: 300,
        passingScore: 150,
        tiers: [
            PTTier(name: "First Class",   minScore: 235, color: "#FFD700", badge: "star.fill"),
            PTTier(name: "Second Class",  minScore: 200, color: "#A29BFE", badge: "medal.fill"),
            PTTier(name: "Third Class",   minScore: 150, color: "#34C759", badge: "checkmark.circle.fill"),
            PTTier(name: "Below Standard",minScore: 0,   color: "#FF453A", badge: "xmark.circle.fill"),
        ],
        officialRef: "MCO 6100.13A"
    )
}

// MARK: ─ Space Force PFA Config ─────────────────────────────
extension BranchPTConfig {
    static let spaceForce = BranchPTConfig(
        branch: .spaceForce,
        testName: "Space Force Physical Fitness Assessment (PFA)",
        events: [
            PTEvent(name: "Push-Ups (1 min)",   unit: "reps", icon: "figure.push.ups",      minValue: 27,  maxValue: 77,  higherIsBetter: true,  pointsMax: 20, description: "1-minute push-up test. Same standard as Air Force."),
            PTEvent(name: "Sit-Ups (1 min)",    unit: "reps", icon: "figure.core.training",  minValue: 42,  maxValue: 62,  higherIsBetter: true,  pointsMax: 20, description: "1-minute sit-up test."),
            PTEvent(name: "1.5-Mile Run",       unit: "secs", icon: "timer",                 minValue: 780, maxValue: 1680, higherIsBetter: false, pointsMax: 60, description: "1.5-mile run. Currently mirrors Air Force standard."),
        ],
        maxScore: 100,
        passingScore: 75,
        tiers: [
            PTTier(name: "Excellent",   minScore: 90, color: "#FFD700", badge: "star.fill"),
            PTTier(name: "Satisfactory",minScore: 75, color: "#34C759", badge: "checkmark.circle.fill"),
            PTTier(name: "Unsatisfactory", minScore: 0, color: "#FF453A", badge: "xmark.circle.fill"),
        ],
        officialRef: "DAFI 36-2905"
    )
}

// MARK: ─ Coast Guard PFA Config ─────────────────────────────
extension BranchPTConfig {
    static let coastGuard = BranchPTConfig(
        branch: .coastGuard,
        testName: "Coast Guard Physical Fitness Assessment",
        events: [
            PTEvent(name: "Push-Ups (1 min)", unit: "reps", icon: "figure.push.ups",   minValue: 29,  maxValue: 60,  higherIsBetter: true,  pointsMax: 30, description: "1-minute push-ups. 29 minimum for males."),
            PTEvent(name: "Sit-Ups (1 min)",  unit: "reps", icon: "figure.core.training",minValue: 38, maxValue: 60,  higherIsBetter: true,  pointsMax: 30, description: "1-minute sit-ups."),
            PTEvent(name: "1.5-Mile Run",     unit: "secs", icon: "timer",              minValue: 780, maxValue: 1680, higherIsBetter: false, pointsMax: 40, description: "1.5-mile timed run. 13:00 minimum for males."),
        ],
        maxScore: 100,
        passingScore: 70,
        tiers: [
            PTTier(name: "Excellent",   minScore: 90, color: "#FFD700", badge: "star.fill"),
            PTTier(name: "Good",        minScore: 80, color: "#45B7D1", badge: "hand.thumbsup.fill"),
            PTTier(name: "Satisfactory",minScore: 70, color: "#34C759", badge: "checkmark.circle.fill"),
            PTTier(name: "Unsatisfactory", minScore: 0, color: "#FF453A", badge: "xmark.circle.fill"),
        ],
        officialRef: "COMDTINST M6410.3"
    )
}

// MARK: - Weight Log
struct WeightLog: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var weightKg: Double
    var notes: String?
    let loggedAt: Date

    enum CodingKeys: String, CodingKey {
        case id; case userId = "user_id"; case weightKg = "weight_kg"
        case notes; case loggedAt = "logged_at"
    }
    var weightLbs: Double { weightKg * 2.20462 }
}

// MARK: - Workout Log
struct WorkoutLog: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var workoutType: String
    var splitDay: String?
    var durationSeconds: Int
    var caloriesBurned: Int?
    var notes: String?
    let loggedAt: Date

    enum CodingKeys: String, CodingKey {
        case id; case userId = "user_id"
        case workoutType = "workout_type"; case splitDay = "split_day"
        case durationSeconds = "duration_seconds"
        case caloriesBurned = "calories_burned"
        case notes; case loggedAt = "logged_at"
    }
}

// MARK: - Activity Log (HealthKit or manual)
struct ActivityLog: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var steps: Int
    var activeCalories: Double
    var activeMinutes: Int
    var heartRateAvg: Double?
    var source: ActivitySource
    let logDate: String      // "yyyy-MM-dd"
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id; case userId = "user_id"; case steps
        case activeCalories = "active_calories"; case activeMinutes = "active_minutes"
        case heartRateAvg = "heart_rate_avg"; case source
        case logDate = "log_date"; case createdAt = "created_at"
    }
}

enum ActivitySource: String, Codable { case healthKit = "healthkit", manual }

// MARK: - AI Recommendation
struct AIRecommendation: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let headline: String
    let detail: String
    let category: RecommendationCategory
    let priority: RecommendationPriority
    let actionLabel: String?
    let generatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id; case userId = "user_id"
        case headline; case detail; case category; case priority
        case actionLabel = "action_label"; case generatedAt = "generated_at"
    }

    init(headline: String, detail: String, category: RecommendationCategory, priority: RecommendationPriority, actionLabel: String? = nil) {
        self.id = UUID(); self.userId = UUID()
        self.headline = headline; self.detail = detail
        self.category = category; self.priority = priority
        self.actionLabel = actionLabel; self.generatedAt = Date()
    }
}

enum RecommendationCategory: String, Codable {
    case cardio, strength, nutrition, ptScore, recovery, weight
    var icon: String {
        switch self {
        case .cardio:    return "figure.run"
        case .strength:  return "figure.strengthtraining.traditional"
        case .nutrition: return "fork.knife"
        case .ptScore:   return "chart.line.uptrend.xyaxis"
        case .recovery:  return "moon.zzz.fill"
        case .weight:    return "scalemass.fill"
        }
    }
    var color: String {
        switch self {
        case .cardio:    return "#FF6B6B"
        case .strength:  return "#45B7D1"
        case .nutrition: return "#96CEB4"
        case .ptScore:   return "#A29BFE"
        case .recovery:  return "#FFD700"
        case .weight:    return "#FF9F0A"
        }
    }
}

enum RecommendationPriority: String, Codable {
    case high, medium, low
    var label: String { rawValue.capitalized }
}

// MARK: - Daily Mission
struct DailyMission: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let icon: String
    let color: String
    var completed: Bool
    let missionType: MissionType

    enum MissionType: String, CaseIterable {
        case logWorkout, hitCalorieGoal, checkPromotion, logWeight, runCardio
    }
}

// MARK: - Net Calorie Summary (Fitness ↔ Nutrition integration)
struct NetCalorieSummary {
    let caloriesIn: Int        // from Chow Log
    let caloriesOut: Int       // from workouts + HealthKit activity
    var net: Int { caloriesIn - caloriesOut }
    var netLabel: String {
        if net > 0 { return "+\(net) surplus" }
        if net < 0 { return "\(net) deficit" }
        return "balanced"
    }
    var netColor: Color {
        if net > 500 { return Color(hex: "#FF453A") }
        if net > 0   { return Color(hex: "#FF9F0A") }
        if net > -500 { return Color(hex: "#34C759") }
        return Color(hex: "#45B7D1")
    }
}
