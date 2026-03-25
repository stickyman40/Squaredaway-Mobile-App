import Charts
import SwiftUI

struct NutritionView: View {
    @EnvironmentObject private var authVM: AuthViewModel

    @State private var draft = NutritionLogDraft()
    @State private var logs: [NutritionLog] = []
    @State private var editingLog: NutritionLog?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var didLoad = false

    private let nutritionService = NutritionService.shared
    private let reminderService = ReminderService.shared

    var body: some View {
        ZStack {
            AppTheme.Colors.backgroundPrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    summaryCard
                    weeklyTrendCard
                    reminderCard
                    logMealCard
                    recentMealsCard
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.lg)
            }
        }
        .navigationTitle("Chow")
        .task {
            guard !didLoad else { return }
            didLoad = true
            await loadLogs()
        }
        .sheet(item: $editingLog) { log in
            NutritionLogEditorSheet(log: log) { updatedLog in
                Task { await updateLog(updatedLog) }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var summaryCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Chow Log")
                            .font(AppTheme.Typography.titleMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        Text("Track meals, calories, and macros to support recovery, chow habits, and daily performance.")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }

                    Spacer()

                    Image("DashboardChow")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md))
                }

                HStack(spacing: AppTheme.Spacing.md) {
                    NutritionMetric(title: "Meals Today", value: "\(todaysLogs.count)")
                    NutritionMetric(title: "Calories", value: "\(todaysCalories)")
                    NutritionMetric(title: "Protein", value: macroText(todaysProtein))
                }

                HStack(spacing: AppTheme.Spacing.md) {
                    NutritionMetric(title: "Carbs", value: macroText(todaysCarbs))
                    NutritionMetric(title: "Fat", value: macroText(todaysFat))
                    NutritionMetric(title: "Entries", value: "\(logs.count)")
                }
            }
        }
    }

    private var logMealCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(spacing: AppTheme.Spacing.md) {
                MenuPickerField(title: "Meal Type", value: draft.mealType.rawValue) {
                    Picker("Meal Type", selection: $draft.mealType) {
                        ForEach(MealType.allCases, id: \.self) { mealType in
                            Text(mealType.rawValue).tag(mealType)
                        }
                    }
                }

                AuthTextField(
                    placeholder: "Calories",
                    icon: "flame.fill",
                    text: $draft.calories,
                    keyboardType: .numberPad
                )

                HStack(spacing: AppTheme.Spacing.md) {
                    AuthTextField(
                        placeholder: "Protein g",
                        icon: "p.circle.fill",
                        text: $draft.protein,
                        keyboardType: .decimalPad
                    )

                    AuthTextField(
                        placeholder: "Carbs g",
                        icon: "c.circle.fill",
                        text: $draft.carbs,
                        keyboardType: .decimalPad
                    )

                    AuthTextField(
                        placeholder: "Fat g",
                        icon: "f.circle.fill",
                        text: $draft.fat,
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
                    NutritionStatusBanner(message: errorMessage, color: AppTheme.Colors.error, icon: "exclamationmark.triangle.fill")
                }

                if let successMessage {
                    NutritionStatusBanner(message: successMessage, color: AppTheme.Colors.success, icon: "checkmark.circle.fill")
                }

                PrimaryButton("Log Meal", isLoading: isLoading) {
                    Task { await saveMeal() }
                }
            }
        }
    }

    private var weeklyTrendCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("Weekly Chow")
                    .font(AppTheme.Typography.titleMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                if weeklyCalories.isEmpty {
                    Text("Log a meal to start building your chow trend.")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                } else {
                    Chart(weeklyCalories) { point in
                        AreaMark(
                            x: .value("Day", point.date, unit: .day),
                            y: .value("Calories", point.value)
                        )
                        .foregroundStyle(AppTheme.Colors.warning.opacity(0.18))

                        LineMark(
                            x: .value("Day", point.date, unit: .day),
                            y: .value("Calories", point.value)
                        )
                        .foregroundStyle(AppTheme.Colors.warning)
                        .interpolationMethod(.catmullRom)
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
                Text("Meal Reminder")
                    .font(AppTheme.Typography.titleMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text("Set a daily reminder to check in on meals, calories, and macros at \(formattedReminderTime(ReminderPreferences.mealReminderTime())).")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)

                HStack(spacing: AppTheme.Spacing.md) {
                    PrimaryButton("Enable Reminder") {
                        Task { await enableMealReminder() }
                    }

                    SecondaryButton(title: "Clear") {
                        ReminderPreferences.setMealReminderEnabled(false)
                        reminderService.removeDailyMealReminder()
                        successMessage = "Meal reminder cleared."
                        errorMessage = nil
                    }
                }
            }
        }
    }

    private var recentMealsCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack {
                    Text("Recent Chow Entries")
                        .font(AppTheme.Typography.titleMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    Spacer()
                    if isLoading {
                        ProgressView()
                            .tint(AppTheme.Colors.accentSecondary)
                    }
                }

                if logs.isEmpty {
                    Text("No meals logged yet. Add your first meal above.")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                } else {
                    ForEach(logs.prefix(8)) { log in
                        NutritionLogRow(
                            log: log,
                            onEdit: { editingLog = log },
                            onDelete: { Task { await deleteLog(log.id) } }
                        )
                    }
                }
            }
        }
    }

    private var todaysLogs: [NutritionLog] {
        let calendar = Calendar.current
        return logs.filter { calendar.isDateInToday($0.loggedAt) }
    }

    private var todaysCalories: Int {
        todaysLogs.reduce(0) { $0 + $1.calories }
    }

    private var todaysProtein: Double {
        todaysLogs.reduce(0) { $0 + $1.protein }
    }

    private var todaysCarbs: Double {
        todaysLogs.reduce(0) { $0 + $1.carbs }
    }

    private var todaysFat: Double {
        todaysLogs.reduce(0) { $0 + $1.fat }
    }

    private var weeklyCalories: [NutritionDailyPoint] {
        let calendar = Calendar.current
        let dates = (0..<7).compactMap { offset in
            calendar.startOfDay(for: calendar.date(byAdding: .day, value: -6 + offset, to: Date()) ?? Date())
        }

        return dates.map { date in
            let total = logs.reduce(0.0) { partial, log in
                guard calendar.isDate(log.loggedAt, inSameDayAs: date) else {
                    return partial
                }
                return partial + Double(log.calories)
            }
            return NutritionDailyPoint(date: date, value: total)
        }
    }

    private func loadLogs() async {
        guard let userId = authVM.currentUserId else { return }

        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer { isLoading = false }

        do {
            logs = try await nutritionService.fetchLogs(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func saveMeal() async {
        guard validateDraft() else { return }
        guard let userId = authVM.currentUserId else {
            errorMessage = "Session unavailable. Please sign in again."
            return
        }

        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer { isLoading = false }

        let log = NutritionLog(
            id: UUID(),
            userId: userId,
            mealType: draft.mealType,
            calories: Int(draft.calories) ?? 0,
            protein: Double(draft.protein) ?? 0,
            carbs: Double(draft.carbs) ?? 0,
            fat: Double(draft.fat) ?? 0,
            notes: draft.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : draft.notes.trimmingCharacters(in: .whitespacesAndNewlines),
            loggedAt: Date()
        )

        do {
            try await nutritionService.createLog(log)
            successMessage = "Meal logged."
            draft.calories = ""
            draft.protein = ""
            draft.carbs = ""
            draft.fat = ""
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
            try await nutritionService.deleteLog(id: id)
            logs.removeAll { $0.id == id }
            successMessage = "Meal deleted."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func updateLog(_ log: NutritionLog) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer { isLoading = false }

        do {
            try await nutritionService.updateLog(log)
            if let index = logs.firstIndex(where: { $0.id == log.id }) {
                logs[index] = log
                logs.sort { $0.loggedAt > $1.loggedAt }
            }
            editingLog = nil
            successMessage = "Meal updated."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func enableMealReminder() async {
        do {
            let granted = try await reminderService.requestAuthorization()
            guard granted else {
                errorMessage = "Notifications are disabled. Enable them in Settings."
                successMessage = nil
                return
            }

            ReminderPreferences.setMealReminderEnabled(true)
            let reminderTime = ReminderPreferences.mealReminderTime()
            try await reminderService.scheduleDailyMealReminder(at: reminderTime)
            successMessage = "Daily meal reminder set for \(formattedReminderTime(reminderTime))."
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
        guard let calories = Int(draft.calories), calories > 0 else {
            errorMessage = "Calories must be greater than zero."
            return false
        }

        guard let protein = Double(draft.protein), protein >= 0 else {
            errorMessage = "Protein must be numeric."
            return false
        }

        guard let carbs = Double(draft.carbs), carbs >= 0 else {
            errorMessage = "Carbs must be numeric."
            return false
        }

        guard let fat = Double(draft.fat), fat >= 0 else {
            errorMessage = "Fat must be numeric."
            return false
        }

        _ = protein
        _ = carbs
        _ = fat
        return true
    }

    private func macroText(_ value: Double) -> String {
        if value.rounded() == value {
            return "\(Int(value))g"
        }
        return String(format: "%.1fg", value)
    }
}

private struct NutritionDailyPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

private struct NutritionMetric: View {
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

private struct NutritionLogRow: View {
    let log: NutritionLog
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            HStack {
                Text(log.mealType.rawValue)
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
                Label("\(log.calories) cal", systemImage: "flame")
                Label(macroValue(log.protein, unit: "P"), systemImage: "p.circle")
                Label(macroValue(log.carbs, unit: "C"), systemImage: "c.circle")
                Label(macroValue(log.fat, unit: "F"), systemImage: "f.circle")
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

    private func macroValue(_ value: Double, unit: String) -> String {
        if value.rounded() == value {
            return "\(unit) \(Int(value))g"
        }
        return String(format: "%@ %.1fg", unit, value)
    }
}

private struct NutritionLogEditorSheet: View {
    @Environment(\.dismiss) private var dismiss

    let log: NutritionLog
    let onSave: (NutritionLog) -> Void

    @State private var draft: NutritionLogDraft
    @State private var errorMessage: String?

    init(log: NutritionLog, onSave: @escaping (NutritionLog) -> Void) {
        self.log = log
        self.onSave = onSave
        _draft = State(
            initialValue: NutritionLogDraft(
                mealType: log.mealType,
                calories: String(log.calories),
                protein: log.protein.rounded() == log.protein ? "\(Int(log.protein))" : String(format: "%.1f", log.protein),
                carbs: log.carbs.rounded() == log.carbs ? "\(Int(log.carbs))" : String(format: "%.1f", log.carbs),
                fat: log.fat.rounded() == log.fat ? "\(Int(log.fat))" : String(format: "%.1f", log.fat),
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
                        MenuPickerField(title: "Meal Type", value: draft.mealType.rawValue) {
                            Picker("Meal Type", selection: $draft.mealType) {
                                ForEach(MealType.allCases, id: \.self) { mealType in
                                    Text(mealType.rawValue).tag(mealType)
                                }
                            }
                        }

                        AuthTextField(
                            placeholder: "Calories",
                            icon: "flame.fill",
                            text: $draft.calories,
                            keyboardType: .numberPad
                        )

                        HStack(spacing: AppTheme.Spacing.md) {
                            AuthTextField(
                                placeholder: "Protein g",
                                icon: "p.circle.fill",
                                text: $draft.protein,
                                keyboardType: .decimalPad
                            )

                            AuthTextField(
                                placeholder: "Carbs g",
                                icon: "c.circle.fill",
                                text: $draft.carbs,
                                keyboardType: .decimalPad
                            )

                            AuthTextField(
                                placeholder: "Fat g",
                                icon: "f.circle.fill",
                                text: $draft.fat,
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
                            NutritionStatusBanner(message: errorMessage, color: AppTheme.Colors.error, icon: "exclamationmark.triangle.fill")
                        }
                    }
                    .padding(AppTheme.Spacing.md)
                }
            }
            .navigationTitle("Edit Meal")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        guard validate() else { return }
                        onSave(
                            NutritionLog(
                                id: log.id,
                                userId: log.userId,
                                mealType: draft.mealType,
                                calories: Int(draft.calories) ?? 0,
                                protein: Double(draft.protein) ?? 0,
                                carbs: Double(draft.carbs) ?? 0,
                                fat: Double(draft.fat) ?? 0,
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
        guard let calories = Int(draft.calories), calories > 0 else {
            errorMessage = "Calories must be greater than zero."
            return false
        }

        guard let protein = Double(draft.protein), protein >= 0 else {
            errorMessage = "Protein must be numeric."
            return false
        }

        guard let carbs = Double(draft.carbs), carbs >= 0 else {
            errorMessage = "Carbs must be numeric."
            return false
        }

        guard let fat = Double(draft.fat), fat >= 0 else {
            errorMessage = "Fat must be numeric."
            return false
        }

        errorMessage = nil
        _ = calories
        _ = protein
        _ = carbs
        _ = fat
        return true
    }
}

private struct NutritionStatusBanner: View {
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
        NutritionView()
            .environmentObject(AuthViewModel())
            .preferredColorScheme(.dark)
    }
}
