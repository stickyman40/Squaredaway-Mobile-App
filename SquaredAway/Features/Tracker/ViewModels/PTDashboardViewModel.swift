import SwiftUI
import Combine

struct PlannerWeeklySnapshot: Identifiable {
    let startDate: Date
    let endDate: Date
    let focusDate: Date
    let completedDays: Int
    let totalDays: Int
    let completionPercent: Int

    var id: Date { startDate }
}

struct PlannerDayStatus: Identifiable {
    let date: Date
    let isTrainingDay: Bool
    let isCompleted: Bool

    var id: Date { date }
}

struct PlannerPrompt {
    enum Kind: Equatable {
        case today
        case missed
        case upcoming
    }

    let kind: Kind
    let date: Date
    let title: String
    let detail: String
    let actionTitle: String
    let icon: String
    let tintHex: String
}

// MARK: - PTDashboardViewModel
// Single source of truth for the entire PT module.
// Coordinates: FitnessProfile · HealthKit · PT Scores ·
//              AI Coach · Daily Missions · Nutrition bridge

@MainActor
final class PTDashboardViewModel: ObservableObject {

    // MARK: - Profile
    @Published var fitnessProfile: FitnessProfile? = nil
    @Published var ptConfig: BranchPTConfig? = nil

    // MARK: - PT Scores
    @Published var latestPTRecord: PTScoreRecord? = nil
    @Published var ptScoreHistory: [PTScoreRecord] = []

    // MARK: - Weight
    @Published var weightHistory: [WeightLog] = []
    @Published var workoutHistory: [WorkoutLog] = []

    // MARK: - Activity (HealthKit or manual)
    @Published var activityLog: ActivityLog? = nil
    @Published var netCalories: NetCalorieSummary = .init(caloriesIn: 0, caloriesOut: 0)

    // MARK: - AI Recommendations
    @Published var recommendations: [AIRecommendation] = []

    // MARK: - Daily Missions
    @Published var dailyMissions: [DailyMission] = []

    // MARK: - Streak
    @Published var currentStreak: Int = 0

    // MARK: - UI State
    @Published var isLoading: Bool = false
    @Published var showProfileSetup: Bool = false
    @Published var showWeightLog: Bool = false
    @Published var showWorkoutLog: Bool = false
    @Published var showPTEntry: Bool = false
    @Published var errorMessage: String? = nil

    // MARK: - Sheets for inline log
    @Published var logWeightKg: String = ""
    @Published var logWorkoutType: String = "Run"
    @Published var logDurationMin: Int = 30
    @Published var logCaloriesBurned: String = ""
    @Published var isLoggingWeight: Bool = false
    @Published var isLoggingWorkout: Bool = false

    // MARK: - Services
    private let service = PTService.shared
    private let reminderService = ReminderService.shared
    let healthKit = HealthKitManager.shared
    private var userId: UUID?
    private var branch: MilitaryBranch = .army
    private var plannerOverrides: [String: WorkoutPlannerOverride] = [:]
    private var plannerProgress: [String: WorkoutPlannerProgressRecord] = [:]

    // MARK: - Configure
    func configure(userId: UUID, branch: MilitaryBranch) {
        self.userId = userId
        self.branch = branch
        self.ptConfig = BranchPTConfig.config(for: branch)
        loadPlannerOverrides()
        loadPlannerProgress()
    }

    // MARK: - Full Load
    func loadAll(caloriesIn: Int = 0) async {
        guard let userId else { return }
        isLoading = true
        defer { isLoading = false }

        // Parallel fetch
        async let profileResult = service.fetchProfile(userId: userId)
        async let weightResult = service.fetchWeightLogs(userId: userId)
        async let workoutResult = service.fetchWorkoutLogs(userId: userId)
        async let ptResult = service.fetchPTScores(userId: userId)
        async let activityResult = service.fetchActivityLog(userId: userId, date: PTService.today)

        do {
            fitnessProfile = try await profileResult
            weightHistory  = try await weightResult
            workoutHistory = try await workoutResult
            ptScoreHistory = try await ptResult
            latestPTRecord = ptScoreHistory.first
            activityLog    = try await activityResult
            showProfileSetup = fitnessProfile == nil
        } catch {
            errorMessage = "Failed to load fitness data."
        }

        // Sync HealthKit if available
        await syncHealthKit()

        // Net calories bridge
        let caloriesOut = Int(healthKit.activeCaloriesToday) + (workoutHistory.first?.caloriesBurned ?? 0)
        netCalories = NetCalorieSummary(caloriesIn: caloriesIn, caloriesOut: caloriesOut)

        // Generate AI recommendations
        refreshRecommendations(caloriesIn: caloriesIn)

        // Build daily missions
        buildDailyMissions()

        // Calculate streak
        calculateStreak()

        await syncPlannerReminder()
    }

    // MARK: - HealthKit Sync
    func syncHealthKit() async {
        guard healthKit.permissionGranted else { return }
        await healthKit.fetchTodayData()

        // Update activity log with HealthKit data
        guard let userId else { return }
        let hkLog = ActivityLog(
            id: UUID(), userId: userId,
            steps: healthKit.stepsToday,
            activeCalories: healthKit.activeCaloriesToday,
            activeMinutes: healthKit.activeMinutesToday,
            heartRateAvg: healthKit.heartRateAvg,
            source: .healthKit,
            logDate: PTService.today,
            createdAt: Date()
        )
        activityLog = hkLog
        try? await service.upsertActivityLog(hkLog)
    }

    // MARK: - AI Recommendations
    func refreshRecommendations(caloriesIn: Int) {
        guard let profile = fitnessProfile else { return }
        recommendations = AICoachEngine.recommendations(
            profile: profile,
            ptRecord: latestPTRecord,
            ptConfig: ptConfig,
            activityLog: activityLog,
            caloriesIn: caloriesIn,
            weightHistory: weightHistory,
            branch: branch
        )
    }

    // MARK: - Daily Missions
    func buildDailyMissions() {
        var missions: [DailyMission] = []

        // Workout mission
        let todayPlannedWorkout = plannedWorkout(on: Date())
        let isRecoveryDay = todayPlannedWorkout?.isRestDay == true
        let didWorkout = isRecoveryDay ? true : isPlannedWorkoutCompleted(on: Date())
        missions.append(DailyMission(
            title: isRecoveryDay ? "Recover today" : "Complete today's workout",
            detail: isRecoveryDay
                ? "Mobility, walking, and recovery still count."
                : "Stay on your \(fitnessProfile?.workoutSplit.abbreviation ?? "training") schedule",
            icon: "figure.run",
            color: "#45B7D1",
            completed: didWorkout,
            missionType: .logWorkout
        ))

        // Calorie mission
        let hitCalories = netCalories.caloriesIn > 0
        missions.append(DailyMission(
            title: "Log your meals",
            detail: "Track calories in Chow Log",
            icon: "fork.knife",
            color: "#96CEB4",
            completed: hitCalories,
            missionType: .hitCalorieGoal
        ))

        // Weight log (once a week)
        let loggedWeightThisWeek = weightHistory.first.map {
            Calendar.current.isDate($0.loggedAt, equalTo: Date(), toGranularity: .weekOfYear)
        } ?? false
        missions.append(DailyMission(
            title: "Log your weight",
            detail: "Weekly weigh-in",
            icon: "scalemass.fill",
            color: "#FF9F0A",
            completed: loggedWeightThisWeek,
            missionType: .logWeight
        ))

        dailyMissions = missions
    }

    // MARK: - Streak Calculation
    func calculateStreak() {
        // Count consecutive completed training days. Rest days do not break the streak.
        var streak = 0
        var checkDate = Calendar.current.startOfDay(for: Date())

        for _ in 0..<60 {
            if let plannedWorkout = plannedWorkout(on: checkDate), plannedWorkout.isRestDay {
                checkDate = Calendar.current.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
                continue
            }

            if isPlannedWorkoutCompleted(on: checkDate) {
                streak += 1
                checkDate = Calendar.current.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else {
                break
            }
        }
        currentStreak = streak
    }

    // MARK: - Log Weight
    func logWeight() async {
        guard let userId, let lbs = Double(logWeightKg) else { return }
        isLoggingWeight = true
        defer { isLoggingWeight = false }

        let kg = lbs * 0.453592
        let log = WeightLog(id: UUID(), userId: userId, weightKg: kg, notes: nil, loggedAt: Date())
        do {
            try await service.logWeight(log)
            weightHistory.insert(log, at: 0)
            // Update profile current weight
            if var profile = fitnessProfile {
                profile.weightKg = kg
                if let savedProfile = try? await service.upsertProfile(profile) {
                    fitnessProfile = savedProfile
                } else {
                    fitnessProfile = profile
                }
            }
            logWeightKg = ""
            showWeightLog = false
        } catch {
            errorMessage = "Couldn't save weight."
        }
    }

    // MARK: - Log Workout
    func logWorkout() async {
        guard let userId else { return }
        isLoggingWorkout = true
        defer { isLoggingWorkout = false }

        let log = WorkoutLog(
            id: UUID(), userId: userId,
            workoutType: logWorkoutType,
            splitDay: fitnessProfile?.workoutSplit.todayWorkout?.name,
            durationSeconds: logDurationMin * 60,
            caloriesBurned: Int(logCaloriesBurned) ?? nil,
            notes: nil,
            loggedAt: Date()
        )
        do {
            try await service.logWorkout(log)
            workoutHistory.insert(log, at: 0)
            showWorkoutLog = false
            buildDailyMissions()
            calculateStreak()
            await syncPlannerReminder()
        } catch {
            errorMessage = "Couldn't save workout."
        }
    }

    func prepareWorkoutLog(for plannedWorkout: PlannedWorkout) {
        logWorkoutType = plannedWorkout.workout.name
        logDurationMin = plannedWorkout.durationMinutes
        if plannedWorkout.workout.exercises.allSatisfy(\.isCardio) {
            logCaloriesBurned = logCaloriesBurned.isEmpty ? "300" : logCaloriesBurned
        }
    }

    func workoutPlannerDraft(for date: Date) -> WorkoutPlannerDraft? {
        guard let plannedWorkout = plannedWorkout(on: date) else { return nil }
        return WorkoutPlannerDraft(
            date: Calendar.current.startOfDay(for: date),
            plannedWorkout: plannedWorkout
        )
    }

    func plannerHasOverride(for date: Date) -> Bool {
        plannerOverrides[plannerDateKey(for: date)] != nil
    }

    func saveWorkoutPlannerOverride(_ draft: WorkoutPlannerDraft) {
        objectWillChange.send()
        let dateKey = plannerDateKey(for: draft.date)
        plannerOverrides[dateKey] = draft.makeOverride(dateKey: dateKey)
        persistPlannerOverrides()
        refreshPlannerDerivedState()
    }

    func saveWorkoutPlannerOverride(_ draft: WorkoutPlannerDraft, for dates: [Date]) {
        objectWillChange.send()
        let normalizedDates = dates.map { Calendar.current.startOfDay(for: $0) }
        for date in normalizedDates {
            let dateKey = plannerDateKey(for: date)
            plannerOverrides[dateKey] = draft.makeOverride(dateKey: dateKey)
        }
        persistPlannerOverrides()
        refreshPlannerDerivedState()
    }

    func removeWorkoutPlannerOverride(for date: Date) {
        objectWillChange.send()
        plannerOverrides.removeValue(forKey: plannerDateKey(for: date))
        persistPlannerOverrides()
        refreshPlannerDerivedState()
    }

    func workoutProgress(for date: Date) -> WorkoutPlannerProgressRecord {
        plannerProgress[plannerDateKey(for: date)] ?? WorkoutPlannerProgressRecord(dateKey: plannerDateKey(for: date))
    }

    func isWorkoutCompleted(_ plannedWorkout: PlannedWorkout) -> Bool {
        let progress = workoutProgress(for: plannedWorkout.date)
        return progress.isWorkoutCompleted
    }

    func completionFraction(for plannedWorkout: PlannedWorkout) -> Double {
        let progress = workoutProgress(for: plannedWorkout.date)
        return progress.completionFraction(totalExercises: plannedWorkout.workout.exercises.count)
    }

    func isExerciseCompleted(_ exercise: ExerciseEntry, at index: Int, in plannedWorkout: PlannedWorkout) -> Bool {
        let progress = workoutProgress(for: plannedWorkout.date)
        let key = WorkoutPlannerProgressRecord.exerciseKey(for: exercise, index: index)
        return progress.completedExerciseKeys.contains(key)
    }

    func toggleExerciseCompletion(at index: Int, in plannedWorkout: PlannedWorkout) {
        guard plannedWorkout.workout.exercises.indices.contains(index) else { return }
        objectWillChange.send()
        let exercise = plannedWorkout.workout.exercises[index]
        let exerciseKeys = plannedWorkout.workout.exercises.enumerated().map {
            WorkoutPlannerProgressRecord.exerciseKey(for: $0.element, index: $0.offset)
        }
        let key = WorkoutPlannerProgressRecord.exerciseKey(for: exercise, index: index)
        var progress = workoutProgress(for: plannedWorkout.date)
        let shouldComplete = !progress.completedExerciseKeys.contains(key)
        progress.setExerciseCompleted(shouldComplete, key: key, totalExerciseKeys: exerciseKeys)
        plannerProgress[plannerDateKey(for: plannedWorkout.date)] = progress
        persistPlannerProgress()
        refreshPlannerDerivedState()
    }

    func toggleWorkoutCompletion(for plannedWorkout: PlannedWorkout) {
        objectWillChange.send()
        let exerciseKeys = plannedWorkout.workout.exercises.enumerated().map {
            WorkoutPlannerProgressRecord.exerciseKey(for: $0.element, index: $0.offset)
        }
        var progress = workoutProgress(for: plannedWorkout.date)
        progress.setWorkoutCompleted(!progress.isWorkoutCompleted, allExerciseKeys: exerciseKeys)
        plannerProgress[plannerDateKey(for: plannedWorkout.date)] = progress
        persistPlannerProgress()
        refreshPlannerDerivedState()
    }

    func completedPlannerDates(in dates: [Date]) -> Set<Date> {
        let calendar = Calendar.current
        return Set(
            dates.filter { date in
                let normalizedDate = calendar.startOfDay(for: date)
                return isPlannedWorkoutCompleted(on: normalizedDate)
            }
        )
    }

    func plannerWeekDates(containing date: Date) -> [Date] {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: date) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: interval.start) }
    }

    func plannerMonthDates(containing date: Date) -> [Date] {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .month, for: date) else { return [] }
        let dayCount = calendar.dateComponents([.day], from: interval.start, to: interval.end).day ?? 0
        return (0..<dayCount).compactMap { calendar.date(byAdding: .day, value: $0, to: interval.start) }
    }

    // MARK: - Complete Mission
    func completeMission(_ mission: DailyMission) {
        if let idx = dailyMissions.firstIndex(where: { $0.id == mission.id }) {
            withAnimation(AppTheme.Animation.spring) {
                dailyMissions[idx].completed = true
            }
        }
    }

    // MARK: - Computed Helpers
    var todayWorkout: WorkoutDay? { fitnessProfile?.workoutSplit.todayWorkout }
    func plannedWorkout(on date: Date) -> PlannedWorkout? {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        let dateKey = plannerDateKey(for: normalizedDate)
        if let override = plannerOverrides[dateKey] {
            return override.plannedWorkout(on: normalizedDate)
        }
        guard let workout = fitnessProfile?.workoutSplit.workout(on: normalizedDate) else { return nil }
        return PlannedWorkout(
            date: normalizedDate,
            workout: workout,
            durationMinutes: workout.defaultDurationMinutes
        )
    }

    func plannedWorkouts(startingAt startDate: Date, days: Int) -> [PlannedWorkout] {
        guard days > 0 else { return [] }
        let calendar = Calendar.current
        return (0..<days).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: startDate) else { return nil }
            return plannedWorkout(on: date)
        }
    }

    var bmi: Double { fitnessProfile?.bmi ?? 0 }
    var bmiCategory: BMICategory { fitnessProfile?.bmiCategory ?? .normal }

    var completedMissions: Int { dailyMissions.filter { $0.completed }.count }
    var missionProgress: Double {
        guard !dailyMissions.isEmpty else { return 0 }
        return Double(completedMissions) / Double(dailyMissions.count)
    }

    var weightProgressPercent: Double { fitnessProfile?.weightProgressPercent ?? 0 }
    var currentWeightLbs: Double { (fitnessProfile?.weightLbs ?? 0) }
    var goalWeightLbs: Double? { fitnessProfile?.goalWeightLbs }
    var weeklyPlannerCompletionPercent: Int {
        Int((weeklyPlannerCompletionRate * 100).rounded())
    }
    var monthlyPlannerCompletionPercent: Int {
        Int((monthlyPlannerCompletionRate * 100).rounded())
    }
    var completedTrainingDaysThisWeek: Int {
        completedTrainingDays(in: currentWeekTrainingDays)
    }
    var totalTrainingDaysThisWeek: Int {
        currentWeekTrainingDays.count
    }
    var currentWeekLabel: String {
        totalTrainingDaysThisWeek == 0 ? "No sessions yet" : "\(completedTrainingDaysThisWeek)/\(totalTrainingDaysThisWeek) done"
    }
    var currentMonthLabel: String {
        totalTrainingDaysThisMonth == 0 ? "No sessions yet" : "\(completedTrainingDaysThisMonth)/\(totalTrainingDaysThisMonth) done"
    }
    var plannerMomentumLabel: String {
        if currentStreak >= 5 { return "Locked in" }
        if currentStreak >= 2 { return "Building momentum" }
        if completedTrainingDaysThisWeek > 0 { return "Good start" }
        return "Start today"
    }
    var completedTrainingDaysThisMonth: Int {
        completedTrainingDays(in: currentMonthTrainingDays)
    }
    var missedTrainingDaysThisWeek: Int {
        max(0, totalTrainingDaysThisWeek - completedTrainingDaysThisWeek)
    }
    var trailingSevenDayCompletionPercent: Int {
        plannerCompletionPercent(for: trailingDates(days: 7))
    }
    var trailingThirtyDayCompletionPercent: Int {
        plannerCompletionPercent(for: trailingDates(days: 30))
    }
    var bestPlannerStreak: Int {
        bestPlannerStreak(in: trailingDates(days: 180))
    }
    var plannerTrendSummary: String {
        let delta = trailingSevenDayCompletionPercent - trailingThirtyDayCompletionPercent
        if totalTrainingDaysThisWeek == 0 {
            return "No scheduled sessions have come up yet this week."
        }
        if delta >= 10 {
            return "Up \(delta)% versus your 30-day average."
        }
        if delta <= -10 {
            return "Down \(abs(delta))% versus your 30-day average."
        }
        return "Steady versus your 30-day average."
    }
    var recentPlannerDailyStatuses: [PlannerDayStatus] {
        trailingPlannerDailyStatuses(days: 14)
    }
    var recentPlannerWeeklySnapshots: [PlannerWeeklySnapshot] {
        weeklyPlannerSnapshots(weeks: 4)
    }
    var activePlannerPrompt: PlannerPrompt? {
        plannerPrompt(mode: ReminderPreferences.plannerReminderMode())
    }

    var ptScore: Int { latestPTRecord?.totalScore ?? 0 }
    var ptPassed: Bool { latestPTRecord?.passed ?? false }
    var ptTier: PTTier? {
        guard let config = ptConfig, let record = latestPTRecord else { return nil }
        return PTTier.tier(for: record.totalScore, tiers: config.tiers)
    }

    var ptProgressPercent: Double {
        guard let config = ptConfig else { return 0 }
        return min(1.0, Double(ptScore) / Double(config.maxScore))
    }

    // Promotion points integration
    var promotionPTBonus: String? {
        guard branch == .army, let record = latestPTRecord else { return nil }
        switch record.totalScore {
        case 450...: return "+60 promotion points (Top Tier)"
        case 400..<450: return "+55 promotion points (Strong)"
        case 300..<400: return "+50 promotion points (Passed)"
        default: return nil
        }
    }

    private func plannerDateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Calendar.current.startOfDay(for: date))
    }

    private func plannerStorageKey(for userId: UUID) -> String {
        "pt.workout-planner-overrides.\(userId.uuidString)"
    }

    private func plannerProgressStorageKey(for userId: UUID) -> String {
        "pt.workout-planner-progress.\(userId.uuidString)"
    }

    private func loadPlannerOverrides() {
        guard let userId else { return }
        let defaults = UserDefaults.standard
        let key = plannerStorageKey(for: userId)
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([String: WorkoutPlannerOverride].self, from: data) else {
            plannerOverrides = [:]
            return
        }
        plannerOverrides = decoded
    }

    private func persistPlannerOverrides() {
        guard let userId,
              let data = try? JSONEncoder().encode(plannerOverrides) else { return }
        UserDefaults.standard.set(data, forKey: plannerStorageKey(for: userId))
    }

    private func loadPlannerProgress() {
        guard let userId else { return }
        let defaults = UserDefaults.standard
        let key = plannerProgressStorageKey(for: userId)
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([String: WorkoutPlannerProgressRecord].self, from: data) else {
            plannerProgress = [:]
            return
        }
        plannerProgress = decoded
    }

    private func persistPlannerProgress() {
        guard let userId,
              let data = try? JSONEncoder().encode(plannerProgress) else { return }
        UserDefaults.standard.set(data, forKey: plannerProgressStorageKey(for: userId))
    }

    private func refreshPlannerDerivedState() {
        buildDailyMissions()
        calculateStreak()
        Task { await syncPlannerReminder() }
    }

    private func syncPlannerReminder() async {
        guard ReminderPreferences.workoutReminderEnabled(),
              NotificationPreferences.isEnabled(for: .activity) else {
            reminderService.removePlannerWorkoutReminder()
            return
        }

        let status = await reminderService.authorizationStatus()
        switch status {
        case .authorized, .provisional, .ephemeral:
            break
        default:
            reminderService.removePlannerWorkoutReminder()
            return
        }

        guard let prompt = plannerPrompt(mode: ReminderPreferences.plannerReminderMode()),
              let workout = plannedWorkout(on: prompt.date),
              !workout.isRestDay else {
            reminderService.removePlannerWorkoutReminder()
            return
        }

        do {
            try await reminderService.schedulePlannerWorkoutReminder(
                workoutName: workout.workout.name,
                scheduledDate: prompt.date,
                preferredTime: ReminderPreferences.workoutReminderTime(),
                leadTime: ReminderPreferences.plannerReminderLeadTime()
            )
        } catch {
            reminderService.removePlannerWorkoutReminder()
        }
    }

    private func hasLoggedWorkout(on date: Date) -> Bool {
        workoutHistory.contains { Calendar.current.isDate($0.loggedAt, inSameDayAs: date) }
    }

    private func isPlannedWorkoutCompleted(on date: Date) -> Bool {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        return plannerProgress[plannerDateKey(for: normalizedDate)]?.isWorkoutCompleted == true || hasLoggedWorkout(on: normalizedDate)
    }

    private var currentWeekTrainingDays: [Date] {
        trainingDays(in: plannerWeekDates(containing: Date()), upTo: Date())
    }

    private var currentMonthTrainingDays: [Date] {
        trainingDays(in: plannerMonthDates(containing: Date()), upTo: Date())
    }

    private var totalTrainingDaysThisMonth: Int {
        currentMonthTrainingDays.count
    }

    private var weeklyPlannerCompletionRate: Double {
        plannerCompletionRate(for: currentWeekTrainingDays)
    }

    private var monthlyPlannerCompletionRate: Double {
        plannerCompletionRate(for: currentMonthTrainingDays)
    }

    func completedTrainingDays(in dates: [Date], upTo cutoff: Date? = nil) -> Int {
        let relevantDates = trainingDays(in: dates, upTo: cutoff)
        return relevantDates.filter { isPlannedWorkoutCompleted(on: $0) }.count
    }

    func plannerCompletionPercent(for dates: [Date], upTo cutoff: Date? = nil) -> Int {
        Int((plannerCompletionRate(for: dates, upTo: cutoff) * 100).rounded())
    }

    func bestPlannerStreak(in dates: [Date]) -> Int {
        let orderedDates = trainingDays(in: dates).sorted()
        var bestStreak = 0
        var activeStreak = 0

        for date in orderedDates {
            if isPlannedWorkoutCompleted(on: date) {
                activeStreak += 1
                bestStreak = max(bestStreak, activeStreak)
            } else {
                activeStreak = 0
            }
        }

        return bestStreak
    }

    func trailingPlannerDailyStatuses(days: Int, endingAt endDate: Date = Date()) -> [PlannerDayStatus] {
        let calendar = Calendar.current
        return trailingDates(days: days, endingAt: endDate)
            .sorted()
            .map { date in
                let normalizedDate = calendar.startOfDay(for: date)
                let isTrainingDay = plannedWorkout(on: normalizedDate)?.isRestDay == false
                return PlannerDayStatus(
                    date: normalizedDate,
                    isTrainingDay: isTrainingDay,
                    isCompleted: isTrainingDay && isPlannedWorkoutCompleted(on: normalizedDate)
                )
            }
    }

    func weeklyPlannerSnapshots(weeks: Int, endingAt endDate: Date = Date()) -> [PlannerWeeklySnapshot] {
        guard weeks > 0 else { return [] }
        let calendar = Calendar.current
        let normalizedEndDate = calendar.startOfDay(for: endDate)
        guard let currentWeekInterval = calendar.dateInterval(of: .weekOfYear, for: normalizedEndDate) else { return [] }

        return Array((0..<weeks).compactMap { offset in
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -offset, to: currentWeekInterval.start) else {
                return nil
            }
            let weekDates = plannerWeekDates(containing: weekStart)
            let effectiveCutoff = offset == 0 ? normalizedEndDate : nil
            let trainingDays = self.trainingDays(in: weekDates, upTo: effectiveCutoff)
            let completedDays = completedTrainingDays(in: weekDates, upTo: effectiveCutoff)
            let completionPercent = plannerCompletionPercent(for: weekDates, upTo: effectiveCutoff)
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
            let focusDate = trainingDays.first(where: { !isPlannedWorkoutCompleted(on: $0) }) ?? trainingDays.last ?? weekStart
            return PlannerWeeklySnapshot(
                startDate: weekStart,
                endDate: weekEnd,
                focusDate: focusDate,
                completedDays: completedDays,
                totalDays: trainingDays.count,
                completionPercent: completionPercent
            )
        }
        .reversed())
    }

    func plannerPrompt(
        mode: PlannerReminderMode = ReminderPreferences.plannerReminderMode(),
        endingAt referenceDate: Date = Date()
    ) -> PlannerPrompt? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: referenceDate)

        if mode != .missedOnly,
           let todayWorkout = plannedWorkout(on: today),
           !todayWorkout.isRestDay,
           !isPlannedWorkoutCompleted(on: today) {
            let missedCount = missedTrainingDates(lookbackDays: 7, endingAt: today).count
            let detail: String
            if missedCount > 0 {
                detail = "\(todayWorkout.workout.name) is still open today, and you have \(missedCount) missed session\(missedCount == 1 ? "" : "s") from earlier this week."
            } else {
                detail = "\(todayWorkout.workout.name) is lined up for today. \(todayWorkout.durationMinutes) minutes gets it done."
            }
            return PlannerPrompt(
                kind: .today,
                date: today,
                title: "Today's workout is ready",
                detail: detail,
                actionTitle: "Open today's plan",
                icon: "bell.badge.fill",
                tintHex: "#45B7D1"
            )
        }

        if let missedDate = missedTrainingDates(lookbackDays: 14, endingAt: today).last,
           let missedWorkout = plannedWorkout(on: missedDate) {
            return PlannerPrompt(
                kind: .missed,
                date: missedDate,
                title: "You have a missed session to catch up",
                detail: "\(missedWorkout.workout.name) from \(missedDate.formatted(.dateTime.weekday(.wide))) is still open. Rework it, move it, or mark it off.",
                actionTitle: "Review missed day",
                icon: "exclamationmark.circle.fill",
                tintHex: "#FF9F0A"
            )
        }

        if mode == .adaptive,
           let nextDate = upcomingTrainingDates(lookaheadDays: 7, startingAt: today).first,
           let nextWorkout = plannedWorkout(on: nextDate) {
            return PlannerPrompt(
                kind: .upcoming,
                date: nextDate,
                title: "Next session is coming up",
                detail: "\(nextWorkout.workout.name) is scheduled for \(nextDate.formatted(.dateTime.weekday(.wide))).",
                actionTitle: "Preview next workout",
                icon: "calendar.badge.clock",
                tintHex: "#96CEB4"
            )
        }

        return nil
    }

    private func plannerCompletionRate(for dates: [Date], upTo cutoff: Date? = nil) -> Double {
        let relevantDates = trainingDays(in: dates, upTo: cutoff)
        guard !relevantDates.isEmpty else { return 0 }
        let completedCount = relevantDates.filter { isPlannedWorkoutCompleted(on: $0) }.count
        return Double(completedCount) / Double(relevantDates.count)
    }

    private func trainingDays(in dates: [Date], upTo cutoff: Date? = nil) -> [Date] {
        let calendar = Calendar.current
        let normalizedCutoff = cutoff.map { calendar.startOfDay(for: $0) }

        return dates
            .map { calendar.startOfDay(for: $0) }
            .filter { date in
                guard plannedWorkout(on: date)?.isRestDay == false else { return false }
                guard let normalizedCutoff else { return true }
                return date <= normalizedCutoff
            }
    }

    private func trailingDates(days: Int, endingAt endDate: Date = Date()) -> [Date] {
        guard days > 0 else { return [] }
        let calendar = Calendar.current
        let normalizedEndDate = calendar.startOfDay(for: endDate)
        return (0..<days).compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: normalizedEndDate)
        }
    }

    private func missedTrainingDates(lookbackDays: Int, endingAt endDate: Date) -> [Date] {
        let calendar = Calendar.current
        let normalizedEndDate = calendar.startOfDay(for: endDate)
        return trainingDays(in: trailingDates(days: lookbackDays, endingAt: normalizedEndDate), upTo: normalizedEndDate)
            .filter { $0 < normalizedEndDate && !isPlannedWorkoutCompleted(on: $0) }
            .sorted()
    }

    private func upcomingTrainingDates(lookaheadDays: Int, startingAt startDate: Date) -> [Date] {
        guard lookaheadDays > 0 else { return [] }
        let calendar = Calendar.current
        let normalizedStartDate = calendar.startOfDay(for: startDate)
        return (1...lookaheadDays).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: normalizedStartDate)
        }
        .map { calendar.startOfDay(for: $0) }
        .filter { plannedWorkout(on: $0)?.isRestDay == false }
    }
}
