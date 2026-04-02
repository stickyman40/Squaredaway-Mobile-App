import Foundation
import Supabase

// ============================================================
//  PTService.swift
//  Supabase data layer for the PT / Fitness module.
//  Handles: fitness_profiles, weight_logs, workout_logs,
//           pt_scores, activity_logs, ai_recommendations_cache
// ============================================================

final class PTService {
    static let shared = PTService()
    private init() {}

    private var client: SupabaseClient { SupabaseManager.shared.client }
    private let profileTable = SupabaseManager.Tables.fitnessProfiles
    private let weightTable = SupabaseManager.Tables.weightLogs
    private let workoutTable = SupabaseManager.Tables.workoutLogs
    private let ptScoresTable = SupabaseManager.Tables.ptScores
    private let activityTable = SupabaseManager.Tables.activityLogs

    // MARK: - Fitness Profile
    func fetchProfile(userId: UUID) async throws -> FitnessProfile? {
        let response: [FitnessProfile] = try await client
            .from(profileTable)
            .select()
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        return response.first
    }

    @discardableResult
    func upsertProfile(_ profile: FitnessProfile) async throws -> FitnessProfile {
        let payload = FitnessProfileUpsert(
            userId: profile.userId,
            heightCm: profile.heightCm,
            weightKg: profile.weightKg,
            goalWeightKg: profile.goalWeightKg,
            fitnessGoal: profile.fitnessGoal,
            experienceLevel: profile.experienceLevel,
            workoutSplit: profile.workoutSplit,
            dailyCalorieTarget: profile.dailyCalorieTarget,
            weeklyWorkoutTarget: profile.weeklyWorkoutTarget,
            updatedAt: Date()
        )

        if let existing = try await fetchProfile(userId: profile.userId) {
            try await client
                .from(profileTable)
                .update(payload)
                .eq("id", value: existing.id.uuidString)
                .execute()
        } else {
            try await client
                .from(profileTable)
                .insert(payload)
                .execute()
        }

        return try await fetchProfile(userId: profile.userId) ?? profile
    }

    // MARK: - Weight Logs
    func fetchWeightLogs(userId: UUID, limit: Int = 30) async throws -> [WeightLog] {
        try await client
            .from(weightTable)
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("logged_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    func logWeight(_ log: WeightLog) async throws {
        try await client
            .from(weightTable)
            .insert(log)
            .execute()
    }

    // MARK: - Workout Logs
    func fetchWorkoutLogs(userId: UUID, limit: Int = 20) async throws -> [WorkoutLog] {
        try await client
            .from(workoutTable)
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("logged_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    func logWorkout(_ log: WorkoutLog) async throws {
        try await client
            .from(workoutTable)
            .insert(log)
            .execute()
    }

    // MARK: - PT Scores
    func fetchPTScores(userId: UUID, limit: Int = 10) async throws -> [PTScoreRecord] {
        try await client
            .from(ptScoresTable)
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("recorded_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    func savePTScore(_ record: PTScoreRecord) async throws {
        try await client
            .from(ptScoresTable)
            .insert(record)
            .execute()
    }

    // MARK: - Activity Logs
    func fetchActivityLog(userId: UUID, date: String) async throws -> ActivityLog? {
        let logs: [ActivityLog] = try await client
            .from(activityTable)
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("log_date", value: date)
            .limit(1)
            .execute()
            .value

        return logs.first
    }

    func upsertActivityLog(_ log: ActivityLog) async throws {
        let payload = ActivityLogUpsert(
            userId: log.userId,
            steps: log.steps,
            activeCalories: log.activeCalories,
            activeMinutes: log.activeMinutes,
            heartRateAvg: log.heartRateAvg,
            source: log.source,
            logDate: log.logDate
        )

        if let existing = try await fetchActivityLog(userId: log.userId, date: log.logDate) {
            try await client
                .from(activityTable)
                .update(payload)
                .eq("id", value: existing.id.uuidString)
                .execute()
        } else {
            try await client
                .from(activityTable)
                .insert(payload)
                .execute()
        }
    }

    // MARK: - Today string
    static var today: String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
}

private struct FitnessProfileUpsert: Encodable {
    let userId: UUID
    let heightCm: Double
    let weightKg: Double
    let goalWeightKg: Double?
    let fitnessGoal: PTFitnessGoal
    let experienceLevel: ExperienceLevel
    let workoutSplit: WorkoutSplit
    let dailyCalorieTarget: Int?
    let weeklyWorkoutTarget: Int
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case heightCm = "height_cm"
        case weightKg = "weight_kg"
        case goalWeightKg = "goal_weight_kg"
        case fitnessGoal = "fitness_goal"
        case experienceLevel = "experience_level"
        case workoutSplit = "workout_split"
        case dailyCalorieTarget = "daily_calorie_target"
        case weeklyWorkoutTarget = "weekly_workout_target"
        case updatedAt = "updated_at"
    }
}

private struct ActivityLogUpsert: Encodable {
    let userId: UUID
    let steps: Int
    let activeCalories: Double
    let activeMinutes: Int
    let heartRateAvg: Double?
    let source: ActivitySource
    let logDate: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case steps
        case activeCalories = "active_calories"
        case activeMinutes = "active_minutes"
        case heartRateAvg = "heart_rate_avg"
        case source
        case logDate = "log_date"
    }
}
