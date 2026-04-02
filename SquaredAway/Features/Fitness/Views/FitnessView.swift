import Charts
import SwiftUI

struct FitnessView: View {
    @EnvironmentObject private var authVM: AuthViewModel

    @State private var draft = FitnessLogDraft()
    @State private var logs: [FitnessLog] = []
    @State private var editingLog: FitnessLog?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var didLoad = false

    private let fitnessService = FitnessService.shared
    private let reminderService = ReminderService.shared
    private let exerciseTypes = ["AFT", "Run", "Ruck", "Strength", "Mobility", "Swim", "Circuit"]

    var body: some View {
        ZStack {
            AppTheme.Colors.backgroundPrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    headerCard
                    weeklyTrendCard
                    reminderCard
                    logWorkoutCard
                    recentLogsCard
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.lg)
            }
        }
        .navigationTitle("Fitness")
        .task {
            guard !didLoad else { return }
            didLoad = true
            await loadLogs()
        }
        .sheet(item: $editingLog) { log in
            FitnessLogEditorSheet(
                log: log,
                exerciseTypes: exerciseTypes
            ) { updatedLog in
                Task { await updateLog(updatedLog) }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var headerCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Fitness Log")
                            .font(AppTheme.Typography.titleMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        Text("Capture PT sessions, AFT events, and readiness training in one place.")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "figure.run")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.accentSecondary)
                }

                HStack(spacing: AppTheme.Spacing.md) {
                    FitnessMetric(title: "Workouts", value: "\(logs.count)")
                    FitnessMetric(title: "Minutes", value: "\(totalMinutes)")
                    FitnessMetric(title: "Best Score", value: bestScoreText)
                }
            }
        }
    }

    private var logWorkoutCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(spacing: AppTheme.Spacing.md) {
                MenuPickerField(title: "Workout Type", value: draft.exerciseType) {
                    Picker("Workout Type", selection: $draft.exerciseType) {
                        ForEach(exerciseTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                }

                HStack(spacing: AppTheme.Spacing.md) {
                    AuthTextField(
                        placeholder: "Duration min",
                        icon: "clock.fill",
                        text: $draft.duration,
                        keyboardType: .numberPad
                    )

                    AuthTextField(
                        placeholder: "Score optional",
                        icon: "number.square.fill",
                        text: $draft.score,
                        keyboardType: .decimalPad
                    )
                }

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("Notes")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textTertiary)

                    TextEditor(text: $draft.notes)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 120)
                        .padding(AppTheme.Spacing.sm)
                        .background(AppTheme.Colors.backgroundCard)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                                .stroke(AppTheme.Colors.glassBorder, lineWidth: 1)
                        )
                        .cornerRadius(AppTheme.Radius.md)
                }

                if let errorMessage {
                    FitnessStatusBanner(message: errorMessage, color: AppTheme.Colors.error, icon: "exclamationmark.triangle.fill")
                }

                if let successMessage {
                    FitnessStatusBanner(message: successMessage, color: AppTheme.Colors.success, icon: "checkmark.circle.fill")
                }

                PrimaryButton("Log Workout", isLoading: isLoading) {
                    Task { await saveWorkout() }
                }
            }
        }
    }

    private var weeklyTrendCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("Weekly Minutes")
                    .font(AppTheme.Typography.titleMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                if weeklyMinutes.isEmpty {
                    Text("Log a workout to start building your weekly trend.")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                } else {
                    Chart(weeklyMinutes) { point in
                        BarMark(
                            x: .value("Day", point.date, unit: .day),
                            y: .value("Minutes", point.value)
                        )
                        .foregroundStyle(AppTheme.Colors.accentSecondary.gradient)
                        .cornerRadius(4)
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { _ in
                            AxisValueLabel(format: .dateTime.weekday(.narrow))
                        }
                    }
                    .frame(height: 180)
                }
            }
        }
    }

    private var reminderCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("Workout Reminder")
                    .font(AppTheme.Typography.titleMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text("Set a daily reminder to log your PT session at \(formattedReminderTime(ReminderPreferences.workoutReminderTime())).")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)

                HStack(spacing: AppTheme.Spacing.md) {
                    PrimaryButton("Enable Reminder") {
                        Task { await enableWorkoutReminder() }
                    }

                    SecondaryButton(title: "Clear") {
                        ReminderPreferences.setWorkoutReminderEnabled(false)
                        reminderService.removeDailyWorkoutReminder()
                        successMessage = "Workout reminder cleared."
                        errorMessage = nil
                    }
                }
            }
        }
    }

    private var recentLogsCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack {
                    Text("Recent Sessions")
                        .font(AppTheme.Typography.titleMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    Spacer()
                    if isLoading {
                        ProgressView()
                            .tint(AppTheme.Colors.accentSecondary)
                    }
                }

                if logs.isEmpty {
                    Text("No workouts logged yet. Add your first session above.")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                } else {
                    ForEach(logs.prefix(8)) { log in
                        FitnessLogRow(
                            log: log,
                            onEdit: { editingLog = log },
                            onDelete: { Task { await deleteLog(log.id) } }
                        )
                    }
                }
            }
        }
    }

    private var totalMinutes: Int {
        logs.reduce(0) { $0 + max($1.duration / 60, 0) }
    }

    private var bestScoreText: String {
        guard let bestScore = logs.compactMap(\.score).max() else { return "--" }
        if bestScore.rounded() == bestScore {
            return "\(Int(bestScore))"
        }
        return String(format: "%.1f", bestScore)
    }

    private var weeklyMinutes: [FitnessDailyPoint] {
        let calendar = Calendar.current
        let dates = (0..<7).compactMap { offset in
            calendar.startOfDay(for: calendar.date(byAdding: .day, value: -6 + offset, to: Date()) ?? Date())
        }

        return dates.map { date in
            let total = logs.reduce(0.0) { partial, log in
                guard calendar.isDate(log.loggedAt, inSameDayAs: date) else {
                    return partial
                }
                return partial + Double(log.duration / 60)
            }
            return FitnessDailyPoint(date: date, value: total)
        }
    }

    private func loadLogs() async {
        guard let userId = authVM.currentUserId else { return }

        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer { isLoading = false }

        do {
            logs = try await fitnessService.fetchLogs(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func saveWorkout() async {
        guard validateDraft() else { return }
        guard let userId = authVM.currentUserId else {
            errorMessage = "Session unavailable. Please sign in again."
            return
        }

        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer { isLoading = false }

        let log = FitnessLog(
            id: UUID(),
            userId: userId,
            exerciseType: draft.exerciseType,
            duration: (Int(draft.duration) ?? 0) * 60,
            score: draft.score.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : Double(draft.score),
            notes: draft.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : draft.notes.trimmingCharacters(in: .whitespacesAndNewlines),
            loggedAt: Date()
        )

        do {
            try await fitnessService.createLog(log)
            successMessage = "Workout logged."
            draft.duration = ""
            draft.score = ""
            draft.notes = ""
            await loadLogs()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteLog(_ id: UUID) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer { isLoading = false }

        do {
            try await fitnessService.deleteLog(id: id)
            logs.removeAll { $0.id == id }
            successMessage = "Workout deleted."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func updateLog(_ log: FitnessLog) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer { isLoading = false }

        do {
            try await fitnessService.updateLog(log)
            if let index = logs.firstIndex(where: { $0.id == log.id }) {
                logs[index] = log
                logs.sort { $0.loggedAt > $1.loggedAt }
            }
            editingLog = nil
            successMessage = "Workout updated."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func enableWorkoutReminder() async {
        do {
            let granted = try await reminderService.requestAuthorization()
            guard granted else {
                errorMessage = "Notifications are disabled. Enable them in Settings."
                successMessage = nil
                return
            }

            ReminderPreferences.setWorkoutReminderEnabled(true)
            let reminderTime = ReminderPreferences.workoutReminderTime()
            try await reminderService.scheduleDailyWorkoutReminder(at: reminderTime)
            successMessage = "Daily workout reminder set for \(formattedReminderTime(reminderTime))."
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            successMessage = nil
        }
    }

    private func formattedReminderTime(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }

    private func validateDraft() -> Bool {
        guard let duration = Int(draft.duration), duration > 0 else {
            errorMessage = "Duration must be greater than zero minutes."
            return false
        }

        if !draft.score.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           Double(draft.score) == nil {
            errorMessage = "Score must be numeric."
            return false
        }

        return true
    }
}

private struct FitnessDailyPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

private struct FitnessMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.textTertiary)
            Text(value)
                .font(AppTheme.Typography.titleSmall)
                .foregroundColor(AppTheme.Colors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.sm)
        .background(AppTheme.Colors.backgroundElevated)
        .cornerRadius(AppTheme.Radius.md)
    }
}

private struct FitnessLogRow: View {
    let log: FitnessLog
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            HStack {
                Text(log.exerciseType)
                    .font(AppTheme.Typography.titleSmall)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Spacer()
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundColor(AppTheme.Colors.accentSecondary)
                }
                .buttonStyle(.plain)
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(AppTheme.Colors.error)
                }
                .buttonStyle(.plain)
                Text(log.loggedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }

            HStack(spacing: AppTheme.Spacing.md) {
                Label("\(max(log.duration / 60, 0)) min", systemImage: "clock")
                if let score = log.score {
                    Label(scoreText(score), systemImage: "number")
                }
            }
            .font(AppTheme.Typography.caption)
            .foregroundColor(AppTheme.Colors.accentSecondary)

            if let notes = log.notes, !notes.isEmpty {
                Text(notes)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, AppTheme.Spacing.xs)
    }

    private func scoreText(_ score: Double) -> String {
        if score.rounded() == score {
            return "\(Int(score))"
        }
        return String(format: "%.1f", score)
    }
}

private struct FitnessLogEditorSheet: View {
    @Environment(\.dismiss) private var dismiss

    let log: FitnessLog
    let exerciseTypes: [String]
    let onSave: (FitnessLog) -> Void

    @State private var draft: FitnessLogDraft
    @State private var errorMessage: String?

    init(log: FitnessLog, exerciseTypes: [String], onSave: @escaping (FitnessLog) -> Void) {
        self.log = log
        self.exerciseTypes = exerciseTypes
        self.onSave = onSave
        _draft = State(
            initialValue: FitnessLogDraft(
                exerciseType: log.exerciseType,
                duration: String(max(log.duration / 60, 0)),
                score: log.score.map {
                    $0.rounded() == $0 ? "\(Int($0))" : String(format: "%.1f", $0)
                } ?? "",
                notes: log.notes ?? ""
            )
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.backgroundPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppTheme.Spacing.md) {
                        MenuPickerField(title: "Workout Type", value: draft.exerciseType) {
                            Picker("Workout Type", selection: $draft.exerciseType) {
                                ForEach(exerciseTypes, id: \.self) { type in
                                    Text(type).tag(type)
                                }
                            }
                        }

                        HStack(spacing: AppTheme.Spacing.md) {
                            AuthTextField(
                                placeholder: "Duration min",
                                icon: "clock.fill",
                                text: $draft.duration,
                                keyboardType: .numberPad
                            )

                            AuthTextField(
                                placeholder: "Score optional",
                                icon: "number.square.fill",
                                text: $draft.score,
                                keyboardType: .decimalPad
                            )
                        }

                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                            Text("Notes")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.textTertiary)

                            TextEditor(text: $draft.notes)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 120)
                                .padding(AppTheme.Spacing.sm)
                                .background(AppTheme.Colors.backgroundCard)
                                .foregroundColor(AppTheme.Colors.textPrimary)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                                        .stroke(AppTheme.Colors.glassBorder, lineWidth: 1)
                                )
                                .cornerRadius(AppTheme.Radius.md)
                        }

                        if let errorMessage {
                            FitnessStatusBanner(message: errorMessage, color: AppTheme.Colors.error, icon: "exclamationmark.triangle.fill")
                        }
                    }
                    .padding(AppTheme.Spacing.md)
                }
            }
            .navigationTitle("Edit Workout")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        guard validate() else { return }
                        onSave(
                            FitnessLog(
                                id: log.id,
                                userId: log.userId,
                                exerciseType: draft.exerciseType,
                                duration: (Int(draft.duration) ?? 0) * 60,
                                score: draft.score.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : Double(draft.score),
                                notes: draft.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : draft.notes.trimmingCharacters(in: .whitespacesAndNewlines),
                                loggedAt: log.loggedAt
                            )
                        )
                    }
                    .foregroundColor(AppTheme.Colors.accentSecondary)
                }
            }
        }
    }

    private func validate() -> Bool {
        guard let duration = Int(draft.duration), duration > 0 else {
            errorMessage = "Duration must be greater than zero minutes."
            return false
        }

        if !draft.score.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           Double(draft.score) == nil {
            errorMessage = "Score must be numeric."
            return false
        }

        errorMessage = nil
        _ = duration
        return true
    }
}

private struct FitnessStatusBanner: View {
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
        FitnessView()
            .environmentObject(AuthViewModel())
            .preferredColorScheme(.dark)
    }
}
