import SwiftUI

// MARK: - PTDashboardView
// The main Fitness / PT module screen.
// Shows: User summary · Branch PT card · Activity · AI Coach · Daily missions
// Everything is branch-specific — no cross-branch data ever shows.

struct PTDashboardView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @AppStorage(NotificationPreferences.activityEnabledKey) private var activityNotificationsEnabled = true
    @StateObject private var vm = PTDashboardViewModel()
    @State private var appeared = false
    @State private var plannerDate = Calendar.current.startOfDay(for: Date())
    @State private var plannerScope: WorkoutPlannerScope = .day
    @State private var plannerEditorDraft: WorkoutPlannerDraft?

    var body: some View {
        ZStack {
            AppTheme.Colors.backgroundPrimary.ignoresSafeArea()

            // Ambient glow
            VStack {
                Circle()
                    .fill(AppTheme.Colors.accentPrimary.opacity(0.08))
                    .frame(width: 340, height: 340)
                    .blur(radius: 90)
                    .offset(x: 70, y: -60)
                Spacer()
            }

            if vm.isLoading && vm.fitnessProfile == nil {
                // First load skeleton
                VStack {
                    Spacer()
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.accentPrimary))
                        .scaleEffect(1.3)
                    Text("Loading fitness data...").font(AppTheme.Typography.bodySmall).foregroundColor(AppTheme.Colors.textSecondary).padding(.top, 8)
                    Spacer()
                }
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: AppTheme.Spacing.lg) {

                        if vm.fitnessProfile != nil {
                            WorkoutPlannerCard(
                                vm: vm,
                                selectedDate: $plannerDate,
                                scope: $plannerScope,
                                onEditPlan: {
                                    plannerEditorDraft = vm.workoutPlannerDraft(for: plannerDate)
                                }
                            )
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 12)
                        }

                        if vm.fitnessProfile != nil {
                            PlannerReminderCard(
                                vm: vm,
                                remindersEnabled: activityNotificationsEnabled,
                                onOpenDate: { date in
                                    plannerDate = Calendar.current.startOfDay(for: date)
                                    plannerScope = .day
                                }
                            )
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .opacity(appeared ? 1 : 0)
                        }

                        // ── 1. Fitness Summary Card ────────────────
                        FitnessSummaryCard(vm: vm)
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 12)

                        PlannerInsightsCard(vm: vm)
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .opacity(appeared ? 1 : 0)

                        PlannerHistoryCard(
                            vm: vm,
                            onSelectDate: { date in
                                let normalizedDate = Calendar.current.startOfDay(for: date)
                                plannerDate = normalizedDate
                                plannerScope = .day
                                plannerEditorDraft = vm.workoutPlannerDraft(for: normalizedDate)
                            },
                            onSelectWeek: { date in
                                plannerDate = Calendar.current.startOfDay(for: date)
                                plannerScope = .week
                            }
                        )
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .opacity(appeared ? 1 : 0)

                        // ── 2. Quick Actions ───────────────────────
                        QuickActionsRow(vm: vm)
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .opacity(appeared ? 1 : 0)

                        // ── 3. Daily Mission Card ──────────────────
                        DailyMissionCard(vm: vm)
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .opacity(appeared ? 1 : 0)

                        // ── 4. Activity Summary (HealthKit) ────────
                        ActivitySummaryCard(vm: vm)
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .opacity(appeared ? 1 : 0)

                        // ── 5. Branch PT Score Card ────────────────
                        // ONLY shows data relevant to user's branch
                        if let config = vm.ptConfig {
                            BranchPTCard(config: config, record: vm.latestPTRecord, vm: vm)
                                .padding(.horizontal, AppTheme.Spacing.md)
                                .opacity(appeared ? 1 : 0)
                        }

                        // ── 9. Energy Card ─────────────────────────
                        DailyEnergyCard(summary: vm.netCalories)
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .opacity(appeared ? 1 : 0)

                        // ── 10. AI Coach Card ──────────────────────
                        AICoachCard(recommendations: vm.recommendations)
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .opacity(appeared ? 1 : 0)

                        // Bottom spacing
                        Spacer(minLength: AppTheme.Spacing.xxl)
                    }
                    .padding(.top, AppTheme.Spacing.md)
                }
            }
        }
        .navigationTitle("Fitness")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(AppTheme.Colors.backgroundPrimary, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { vm.showProfileSetup = true } label: {
                    Image(systemName: "person.crop.circle")
                        .foregroundColor(AppTheme.Colors.accentSecondary)
                }
            }
        }
        .onAppear {
            if let id = authVM.currentUserId,
               let branch = authVM.lockedBranch {
                vm.configure(userId: id, branch: branch)
                Task { await vm.loadAll() }
            }
            withAnimation(AppTheme.Animation.standard.delay(0.1)) { appeared = true }
        }
        .sheet(isPresented: $vm.showProfileSetup) {
            FitnessProfileSetupView(existingProfile: vm.fitnessProfile) { _ in
                Task { await vm.loadAll() }
            }
        }
        .sheet(isPresented: $vm.showWeightLog) {
            WeightLogSheet(vm: vm)
        }
        .sheet(isPresented: $vm.showWorkoutLog) {
            WorkoutLogSheet(vm: vm)
        }
        .sheet(item: $plannerEditorDraft) { draft in
            WorkoutPlannerEditorSheet(
                draft: draft,
                hasSavedOverride: vm.plannerHasOverride(for: draft.date),
                weekDates: vm.plannerWeekDates(containing: draft.date),
                monthDates: vm.plannerMonthDates(containing: draft.date),
                onSave: { updatedDraft in
                    vm.saveWorkoutPlannerOverride(updatedDraft)
                    plannerEditorDraft = nil
                },
                onSaveWeek: { updatedDraft in
                    vm.saveWorkoutPlannerOverride(updatedDraft, for: vm.plannerWeekDates(containing: updatedDraft.date))
                    plannerEditorDraft = nil
                },
                onSaveMonth: { updatedDraft in
                    vm.saveWorkoutPlannerOverride(updatedDraft, for: vm.plannerMonthDates(containing: updatedDraft.date))
                    plannerEditorDraft = nil
                },
                onReset: {
                    vm.removeWorkoutPlannerOverride(for: draft.date)
                    plannerEditorDraft = nil
                }
            )
        }
        .sheet(isPresented: $vm.showPTEntry) {
            if let config = vm.ptConfig, let userId = authVM.currentUserId {
                PTScoreEntryView(config: config, userId: userId) { record in
                    vm.latestPTRecord = record
                    vm.ptScoreHistory.insert(record, at: 0)
                }
            }
        }
    }
}

// MARK: ── Fitness Summary Card ────────────────────────────────
private struct FitnessSummaryCard: View {
    @ObservedObject var vm: PTDashboardViewModel

    var body: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(spacing: AppTheme.Spacing.md) {

                // Top row: goal + streak
                HStack {
                    if let profile = vm.fitnessProfile {
                        HStack(spacing: 8) {
                            Image(systemName: profile.fitnessGoal.icon)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(hex: profile.fitnessGoal.color))
                            Text(profile.fitnessGoal.label)
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        .padding(.horizontal, AppTheme.Spacing.sm)
                        .padding(.vertical, 4)
                        .background(Color(hex: profile.fitnessGoal.color).opacity(0.1))
                        .cornerRadius(AppTheme.Radius.full)
                    }
                    Spacer()
                    if vm.currentStreak > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill").foregroundColor(Color(hex: "#FF6B6B"))
                            Text("\(vm.currentStreak) day completion streak")
                                .font(AppTheme.Typography.bodySmall).foregroundColor(AppTheme.Colors.textPrimary)
                        }
                        .font(.system(size: 13))
                    }
                }

                // Weight + BMI row
                HStack(spacing: AppTheme.Spacing.xl) {
                    StatCell(
                        label: "Current Weight",
                        value: vm.fitnessProfile.map { String(format: "%.0f lb", $0.weightLbs) } ?? "—",
                        icon: "scalemass.fill",
                        color: "#45B7D1",
                        accessibilityIdentifier: "pt-summary-current-weight"
                    )
                    if let goal = vm.goalWeightLbs {
                        StatCell(
                            label: "Goal Weight",
                            value: String(format: "%.0f lb", goal),
                            icon: "target",
                            color: "#96CEB4",
                            accessibilityIdentifier: "pt-summary-goal-weight"
                        )
                    }
                    StatCell(
                        label: "BMI",
                        value: vm.bmi > 0 ? String(format: "%.1f", vm.bmi) : "—",
                        icon: "heart.text.clipboard",
                        color: vm.bmiCategory.color.description,
                        accessibilityIdentifier: "pt-summary-bmi"
                    )
                }

                // BMI category badge
                if vm.bmi > 0 {
                    HStack {
                        Text("BMI: \(vm.bmiCategory.label)")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(vm.bmiCategory.color)
                        Spacer()
                        Text(String(format: "%.1f", vm.bmi))
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(vm.bmiCategory.color)
                    }
                    .padding(.horizontal, AppTheme.Spacing.sm)
                    .padding(.vertical, 5)
                    .background(vm.bmiCategory.bgColor)
                    .cornerRadius(AppTheme.Radius.sm)
                }

                // Weight progress (only if goal set)
                if let profile = vm.fitnessProfile, profile.goalWeightKg != nil {
                    VStack(spacing: 4) {
                        HStack {
                            Text("Progress to goal")
                                .font(AppTheme.Typography.caption).foregroundColor(AppTheme.Colors.textTertiary)
                            Spacer()
                            Text("\(Int(vm.weightProgressPercent * 100))%")
                                .font(AppTheme.Typography.caption).foregroundColor(AppTheme.Colors.accentSecondary)
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(AppTheme.Colors.glassBorder).frame(height: 5)
                                Capsule().fill(AppTheme.Gradients.primaryButton)
                                    .frame(width: geo.size.width * vm.weightProgressPercent, height: 5)
                                    .animation(AppTheme.Animation.slow, value: vm.weightProgressPercent)
                            }
                        }.frame(height: 5)
                    }
                }
            }
        }
    }
}

private struct PlannerReminderCard: View {
    @ObservedObject var vm: PTDashboardViewModel
    let remindersEnabled: Bool
    let onOpenDate: (Date) -> Void

    var body: some View {
        if let prompt = vm.activePlannerPrompt {
            GlassCard(padding: AppTheme.Spacing.md) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                        Image(systemName: prompt.icon)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(hex: prompt.tintHex))
                            .frame(width: 34, height: 34)
                            .background(Color(hex: prompt.tintHex).opacity(0.14))
                            .cornerRadius(AppTheme.Radius.md)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(prompt.title)
                                .font(AppTheme.Typography.titleSmall)
                                .foregroundColor(AppTheme.Colors.textPrimary)
                            Text(prompt.detail)
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }

                        Spacer()

                        Text(remindersEnabled ? "Reminders on" : "Reminders off")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(remindersEnabled ? AppTheme.Colors.success : AppTheme.Colors.warning)
                            .padding(.horizontal, AppTheme.Spacing.sm)
                            .padding(.vertical, 4)
                            .background((remindersEnabled ? AppTheme.Colors.success : AppTheme.Colors.warning).opacity(0.12))
                            .cornerRadius(AppTheme.Radius.full)
                    }

                    Button {
                        onOpenDate(prompt.date)
                    } label: {
                        HStack {
                            Text(prompt.actionTitle)
                            Spacer()
                            Image(systemName: "arrow.right")
                        }
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(Color(hex: prompt.tintHex))
                        .padding(.horizontal, AppTheme.Spacing.sm)
                        .padding(.vertical, AppTheme.Spacing.sm)
                        .background(Color(hex: prompt.tintHex).opacity(0.12))
                        .cornerRadius(AppTheme.Radius.md)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("pt-planner-reminder-open")

                    if !remindersEnabled {
                        Text("Turn on Fitness & Chow activity notifications in Settings if you want these reminders reflected in your notification preferences too.")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    } else {
                        Text("Uses your saved workout reminder time from Reminder Settings.")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                }
            }
            .accessibilityIdentifier("pt-planner-reminder-card")
        }
    }
}

private struct PlannerInsightsCard: View {
    @ObservedObject var vm: PTDashboardViewModel

    var body: some View {
        GlassCard(padding: AppTheme.Spacing.md) {
            VStack(spacing: AppTheme.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Planner Insights")
                            .font(AppTheme.Typography.titleSmall)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        Text(vm.plannerTrendSummary)
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                    Spacer()
                    Text(vm.plannerMomentumLabel)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(Color(hex: "#FF6B6B"))
                        .padding(.horizontal, AppTheme.Spacing.sm)
                        .padding(.vertical, 4)
                        .background(Color(hex: "#FF6B6B").opacity(0.12))
                        .cornerRadius(AppTheme.Radius.full)
                        .accessibilityIdentifier("pt-planner-momentum")
                }

                HStack(spacing: AppTheme.Spacing.xl) {
                    StatCell(
                        label: "Week To Date",
                        value: vm.currentWeekLabel,
                        icon: "calendar.badge.clock",
                        color: "#45B7D1",
                        accessibilityIdentifier: "pt-summary-week-completion"
                    )
                    StatCell(
                        label: "Best Streak",
                        value: "\(vm.bestPlannerStreak)d",
                        icon: "flame.fill",
                        color: "#FF6B6B",
                        accessibilityIdentifier: "pt-summary-best-streak"
                    )
                    StatCell(
                        label: "Missed This Week",
                        value: "\(vm.missedTrainingDaysThisWeek)",
                        icon: "exclamationmark.circle",
                        color: "#FF9F0A",
                        accessibilityIdentifier: "pt-summary-missed-week"
                    )
                }

                PlannerInsightProgressRow(
                    title: "7-day adherence",
                    valueText: "\(vm.trailingSevenDayCompletionPercent)%",
                    progress: Double(vm.trailingSevenDayCompletionPercent) / 100.0,
                    color: "#45B7D1",
                    accessibilityIdentifier: "pt-summary-7-day-adherence"
                )

                PlannerInsightProgressRow(
                    title: "Month to date",
                    valueText: "\(vm.monthlyPlannerCompletionPercent)% · \(vm.currentMonthLabel)",
                    progress: Double(vm.monthlyPlannerCompletionPercent) / 100.0,
                    color: "#96CEB4",
                    accessibilityIdentifier: "pt-summary-month-completion"
                )

                PlannerInsightProgressRow(
                    title: "30-day adherence",
                    valueText: "\(vm.trailingThirtyDayCompletionPercent)%",
                    progress: Double(vm.trailingThirtyDayCompletionPercent) / 100.0,
                    color: "#A29BFE",
                    accessibilityIdentifier: "pt-summary-30-day-adherence"
                )
            }
        }
    }
}

private struct PlannerHistoryCard: View {
    @ObservedObject var vm: PTDashboardViewModel
    let onSelectDate: (Date) -> Void
    let onSelectWeek: (Date) -> Void

    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter
    }()

    private let weekFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    var body: some View {
        GlassCard(padding: AppTheme.Spacing.md) {
            VStack(spacing: AppTheme.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Recent History")
                            .font(AppTheme.Typography.titleSmall)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        Text("Last 14 days and weekly adherence snapshots.")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textTertiary)
                        Text("Tap a day to edit it, or a week row to jump the planner.")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppTheme.Colors.accentSecondary)
                    }
                    Spacer()
                    Text("\(vm.trailingThirtyDayCompletionPercent)%")
                        .font(AppTheme.Typography.titleSmall)
                        .foregroundColor(AppTheme.Colors.accentSecondary)
                        .accessibilityIdentifier("pt-history-30-day")
                }

                HStack(spacing: 8) {
                    ForEach(vm.recentPlannerDailyStatuses) { status in
                        Button {
                            onSelectDate(status.date)
                        } label: {
                            VStack(spacing: 6) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(color(for: status))
                                    .frame(height: 36)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(borderColor(for: status), lineWidth: 1)
                                    )
                                Text(dayFormatter.string(from: status.date))
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(AppTheme.Colors.textTertiary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityIdentifier("pt-history-day-\(status.id.timeIntervalSince1970)")
                    }
                }
                .accessibilityIdentifier("pt-history-14-day-strip")

                HStack(spacing: AppTheme.Spacing.md) {
                    PlannerHistoryLegendItem(label: "Completed", color: Color(hex: "#34C759"))
                    PlannerHistoryLegendItem(label: "Missed", color: Color(hex: "#FF9F0A"))
                    PlannerHistoryLegendItem(label: "Recovery", color: AppTheme.Colors.glassBorder)
                }

                VStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(vm.recentPlannerWeeklySnapshots) { snapshot in
                        Button {
                            onSelectWeek(snapshot.focusDate)
                        } label: {
                            VStack(spacing: 6) {
                                HStack {
                                    Text("\(weekFormatter.string(from: snapshot.startDate)) - \(weekFormatter.string(from: snapshot.endDate))")
                                        .font(AppTheme.Typography.bodySmall)
                                        .foregroundColor(AppTheme.Colors.textPrimary)
                                    Spacer()
                                    Text(snapshot.totalDays == 0 ? "No sessions" : "\(snapshot.completedDays)/\(snapshot.totalDays) · \(snapshot.completionPercent)%")
                                        .font(AppTheme.Typography.caption)
                                        .foregroundColor(AppTheme.Colors.textTertiary)
                                }
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(AppTheme.Colors.glassBorder)
                                            .frame(height: 5)
                                        Capsule()
                                            .fill(AppTheme.Gradients.primaryButton)
                                            .frame(width: geo.size.width * (Double(snapshot.completionPercent) / 100.0), height: 5)
                                    }
                                }
                                .frame(height: 5)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityIdentifier("pt-history-week-\(snapshot.id.timeIntervalSince1970)")
                    }
                }
                .accessibilityIdentifier("pt-history-weekly-snapshots")
            }
        }
    }

    private func color(for status: PlannerDayStatus) -> Color {
        if !status.isTrainingDay {
            return AppTheme.Colors.glassBorder.opacity(0.55)
        }
        return status.isCompleted ? Color(hex: "#34C759") : Color(hex: "#FF9F0A").opacity(0.75)
    }

    private func borderColor(for status: PlannerDayStatus) -> Color {
        if !status.isTrainingDay {
            return AppTheme.Colors.glassBorder
        }
        return status.isCompleted ? Color(hex: "#34C759").opacity(0.9) : Color(hex: "#FF9F0A")
    }
}

private struct PlannerHistoryLegendItem: View {
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct PlannerInsightProgressRow: View {
    let title: String
    let valueText: String
    let progress: Double
    let color: String
    let accessibilityIdentifier: String

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(title)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textTertiary)
                Spacer()
                Text(valueText)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(Color(hex: color))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppTheme.Colors.glassBorder)
                        .frame(height: 5)
                    Capsule()
                        .fill(Color(hex: color))
                        .frame(width: geo.size.width * min(max(progress, 0), 1), height: 5)
                        .animation(AppTheme.Animation.slow, value: progress)
                }
            }
            .frame(height: 5)
        }
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}

private struct StatCell: View {
    let label: String
    let value: String
    let icon: String
    let color: String
    let accessibilityIdentifier: String?
    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 14)).foregroundColor(Color(hex: color))
            Text(value).font(AppTheme.Typography.titleSmall).foregroundColor(AppTheme.Colors.textPrimary)
            Text(label).font(AppTheme.Typography.caption).foregroundColor(AppTheme.Colors.textTertiary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier(accessibilityIdentifier ?? "")
    }
}

// MARK: ── Quick Actions Row ───────────────────────────────────
private struct QuickActionsRow: View {
    @ObservedObject var vm: PTDashboardViewModel
    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            QuickAction(label: "Log Workout", icon: "figure.run", color: "#45B7D1") { vm.showWorkoutLog = true }
            QuickAction(label: "Log Weight",  icon: "scalemass.fill",   color: "#FF9F0A") { vm.showWeightLog = true }
            QuickAction(label: "PT Score",    icon: "star.circle.fill", color: "#A29BFE") { vm.showPTEntry = true }
        }
    }
}

private struct QuickAction: View {
    let label: String; let icon: String; let color: String; let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(hex: color))
                    .frame(width: 48, height: 48)
                    .background(Color(hex: color).opacity(0.12))
                    .cornerRadius(AppTheme.Radius.md)
                Text(label)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(AppTheme.Spacing.sm)
            .background(AppTheme.Colors.backgroundCard)
            .cornerRadius(AppTheme.Radius.lg)
            .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.lg).stroke(AppTheme.Colors.glassBorder, lineWidth: 1))
        }
        .accessibilityIdentifier("pt-quick-action-\(label.lowercased().replacingOccurrences(of: " ", with: "-"))")
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: ── Daily Mission Card ──────────────────────────────────
private struct DailyMissionCard: View {
    @ObservedObject var vm: PTDashboardViewModel
    var body: some View {
        GlassCard(padding: AppTheme.Spacing.md) {
            VStack(spacing: AppTheme.Spacing.md) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill").foregroundColor(Color(hex: "#FFD700"))
                        Text("Daily Mission").font(AppTheme.Typography.titleSmall).foregroundColor(AppTheme.Colors.textPrimary)
                    }
                    Spacer()
                    Text("\(vm.completedMissions)/\(vm.dailyMissions.count) done")
                        .font(AppTheme.Typography.bodySmall).foregroundColor(AppTheme.Colors.textTertiary)
                }

                // Mission progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(AppTheme.Colors.glassBorder).frame(height: 4)
                        Capsule().fill(LinearGradient(colors: [Color(hex: "#FFD700"), AppTheme.Colors.accentPrimary], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * vm.missionProgress, height: 4)
                            .animation(AppTheme.Animation.slow, value: vm.missionProgress)
                    }
                }.frame(height: 4)

                // Mission items
                ForEach(vm.dailyMissions) { mission in
                    MissionRow(mission: mission) {
                        vm.completeMission(mission)
                    }
                }
            }
        }
    }
}

private struct MissionRow: View {
    let mission: DailyMission; let onTap: () -> Void
    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Button(action: onTap) {
                Image(systemName: mission.completed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(mission.completed ? AppTheme.Colors.success : AppTheme.Colors.textTertiary)
                    .animation(AppTheme.Animation.spring, value: mission.completed)
            }.buttonStyle(PlainButtonStyle())

            Image(systemName: mission.icon)
                .font(.system(size: 13)).foregroundColor(Color(hex: mission.color))
                .frame(width: 28, height: 28).background(Color(hex: mission.color).opacity(0.12)).cornerRadius(AppTheme.Radius.sm)

            VStack(alignment: .leading, spacing: 1) {
                Text(mission.title).font(AppTheme.Typography.bodyMedium).foregroundColor(mission.completed ? AppTheme.Colors.textTertiary : AppTheme.Colors.textPrimary)
                    .strikethrough(mission.completed)
                Text(mission.detail).font(AppTheme.Typography.caption).foregroundColor(AppTheme.Colors.textTertiary)
            }
            Spacer()
        }
    }
}

// MARK: ── Activity Summary Card (HealthKit) ───────────────────
struct ActivitySummaryCard: View {
    @ObservedObject var vm: PTDashboardViewModel

    var body: some View {
        GlassCard(padding: AppTheme.Spacing.md) {
            VStack(spacing: AppTheme.Spacing.md) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill").foregroundColor(Color(hex: "#FF6B6B"))
                        Text("Activity Today").font(AppTheme.Typography.titleSmall).foregroundColor(AppTheme.Colors.textPrimary)
                    }
                    Spacer()
                    if vm.healthKit.permissionGranted {
                        HStack(spacing: 4) {
                            Circle().fill(AppTheme.Colors.success).frame(width: 6, height: 6)
                            Text("Health Synced").font(AppTheme.Typography.caption).foregroundColor(AppTheme.Colors.success)
                        }
                    } else {
                        Button {
                            Task { await vm.healthKit.requestAuthorization() }
                        } label: {
                            Text("Connect Health").font(AppTheme.Typography.caption).foregroundColor(AppTheme.Colors.accentSecondary)
                        }
                    }
                }

                if vm.healthKit.isAvailable {
                    HStack(spacing: 0) {
                        ActivityStat(value: vm.healthKit.stepsFormatted, label: "Steps", icon: "figure.walk", color: "#45B7D1")
                        Divider().background(AppTheme.Colors.glassBorder).frame(height: 40)
                        ActivityStat(value: "\(Int(vm.healthKit.activeCaloriesToday))", label: "Cal Burned", icon: "flame.fill", color: "#FF6B6B", unit: "kcal")
                        Divider().background(AppTheme.Colors.glassBorder).frame(height: 40)
                        ActivityStat(value: "\(vm.healthKit.activeMinutesToday)", label: "Active Min", icon: "timer", color: "#96CEB4", unit: "min")
                        if let hr = vm.healthKit.heartRateAvg {
                            Divider().background(AppTheme.Colors.glassBorder).frame(height: 40)
                            ActivityStat(value: "\(Int(hr))", label: "Avg HR", icon: "heart.fill", color: "#FF6B6B", unit: "bpm")
                        }
                    }
                } else {
                    // HealthKit not available (simulator / no Health app)
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "applewatch").foregroundColor(AppTheme.Colors.textTertiary)
                        Text("Apple Health not available on this device")
                            .font(AppTheme.Typography.bodySmall).foregroundColor(AppTheme.Colors.textTertiary)
                    }
                }
            }
        }
    }
}

private struct ActivityStat: View {
    let value: String; let label: String; let icon: String; let color: String; var unit: String = ""
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 13)).foregroundColor(Color(hex: color))
            Text(value).font(.system(size: 18, weight: .bold, design: .rounded)).foregroundColor(AppTheme.Colors.textPrimary)
            if !unit.isEmpty { Text(unit).font(.system(size: 9)).foregroundColor(AppTheme.Colors.textTertiary) }
            Text(label).font(AppTheme.Typography.caption).foregroundColor(AppTheme.Colors.textTertiary)
        }.frame(maxWidth: .infinity)
    }
}

// MARK: ── Branch PT Score Card ────────────────────────────────
struct BranchPTCard: View {
    let config: BranchPTConfig
    let record: PTScoreRecord?
    @ObservedObject var vm: PTDashboardViewModel

    private var tier: PTTier? { vm.ptTier }
    private var score: Int { vm.ptScore }

    var body: some View {
        GlassCard(padding: AppTheme.Spacing.md) {
            VStack(spacing: AppTheme.Spacing.md) {

                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(config.testName)
                            .font(AppTheme.Typography.titleSmall).foregroundColor(AppTheme.Colors.textPrimary)
                        Text("Ref: \(config.officialRef)")
                            .font(AppTheme.Typography.caption).foregroundColor(AppTheme.Colors.textTertiary)
                    }
                    Spacer()
                    Button { vm.showPTEntry = true } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 15)).foregroundColor(AppTheme.Colors.accentSecondary)
                            .frame(width: 32, height: 32).background(AppTheme.Colors.accentPrimary.opacity(0.1)).cornerRadius(AppTheme.Radius.sm)
                    }
                }

                // Score ring + tier
                HStack(spacing: AppTheme.Spacing.lg) {
                    ZStack {
                        Circle().stroke(AppTheme.Colors.glassBorder, lineWidth: 8).frame(width: 80, height: 80)
                        Circle().trim(from: 0, to: vm.ptProgressPercent)
                            .stroke(tier.map { Color(hex: $0.color) } ?? AppTheme.Colors.accentSecondary,
                                    style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 80, height: 80).rotationEffect(.degrees(-90))
                            .animation(AppTheme.Animation.slow, value: vm.ptProgressPercent)
                        VStack(spacing: 0) {
                            Text("\(score)").font(.system(size: 20, weight: .bold, design: .rounded)).foregroundColor(AppTheme.Colors.textPrimary)
                            Text("/ \(config.maxScore)").font(.system(size: 10)).foregroundColor(AppTheme.Colors.textTertiary)
                        }
                    }

                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        if let tier {
                            HStack(spacing: 6) {
                                Image(systemName: tier.badge).foregroundColor(Color(hex: tier.color))
                                Text(tier.name).font(AppTheme.Typography.titleSmall).foregroundColor(Color(hex: tier.color))
                            }
                        } else {
                            Text("No score logged").font(AppTheme.Typography.bodySmall).foregroundColor(AppTheme.Colors.textTertiary)
                        }
                        HStack(spacing: 4) {
                            Image(systemName: vm.ptPassed ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(vm.ptPassed ? AppTheme.Colors.success : AppTheme.Colors.error)
                            Text(vm.ptPassed ? "Passing standard met" : "Below passing (\(config.passingScore) required)")
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(vm.ptPassed ? AppTheme.Colors.success : AppTheme.Colors.error)
                        }
                        if let bonus = vm.promotionPTBonus {
                            Text(bonus).font(AppTheme.Typography.caption).foregroundColor(AppTheme.Colors.accentSecondary)
                        }
                    }
                }

                // Event breakdown (if score exists)
                if let record, !record.eventScores.isEmpty {
                    Divider().background(AppTheme.Colors.glassBorder)
                    VStack(spacing: AppTheme.Spacing.xs) {
                        ForEach(config.events.prefix(6)) { event in
                            if let raw = record.eventScores[event.name] {
                                PTEventRow(event: event, rawValue: raw)
                            }
                        }
                    }
                }

                // Log prompt if no record
                if record == nil {
                    Button { vm.showPTEntry = true } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Log your first \(config.testName.components(separatedBy: "(").first?.trimmingCharacters(in: .whitespaces) ?? "PT") score")
                        }
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.accentSecondary)
                    }
                }
            }
        }
    }
}

private struct PTEventRow: View {
    let event: PTEvent; let rawValue: Double
    private var pts: Int { event.score(for: rawValue) }
    private var pct: Double { Double(pts) / Double(event.pointsMax) }
    private var displayValue: String {
        if event.unit == "secs" {
            let mins = Int(rawValue) / 60; let secs = Int(rawValue) % 60
            return String(format: "%d:%02d", mins, secs)
        }
        return String(format: "%.0f %@", rawValue, event.unit)
    }
    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: event.icon).font(.system(size: 12)).foregroundColor(AppTheme.Colors.textTertiary).frame(width: 20)
            Text(event.name).font(AppTheme.Typography.caption).foregroundColor(AppTheme.Colors.textSecondary).lineLimit(1).frame(maxWidth: .infinity, alignment: .leading)
            Text(displayValue).font(AppTheme.Typography.caption).foregroundColor(AppTheme.Colors.textPrimary).frame(width: 56, alignment: .trailing)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(AppTheme.Colors.glassBorder).frame(height: 4)
                    Capsule().fill(pct >= 0.8 ? AppTheme.Colors.success : pct >= 0.5 ? AppTheme.Colors.warning : AppTheme.Colors.error)
                        .frame(width: geo.size.width * pct, height: 4).animation(AppTheme.Animation.slow, value: pct)
                }
            }.frame(height: 4).frame(width: 60)
            Text("\(pts)").font(AppTheme.Typography.caption).foregroundColor(AppTheme.Colors.textSecondary).frame(width: 28, alignment: .trailing)
        }
    }
}

private enum WorkoutPlannerScope: String, CaseIterable, Identifiable {
    case day = "Day"
    case week = "Week"
    case month = "Month"

    var id: String { rawValue }
}

private struct WorkoutPlannerCard: View {
    @ObservedObject var vm: PTDashboardViewModel
    @Binding var selectedDate: Date
    @Binding var scope: WorkoutPlannerScope
    let onEditPlan: () -> Void

    private let calendar = Calendar.current

    private var split: WorkoutSplit? { vm.fitnessProfile?.workoutSplit }
    private var selectedWorkout: PlannedWorkout? { vm.plannedWorkout(on: selectedDate) }
    private var loggedDays: Set<Date> {
        Set(vm.workoutHistory.map { calendar.startOfDay(for: $0.loggedAt) })
    }
    private var completedDays: Set<Date> {
        vm.completedPlannerDates(in: plannerWeek + plannerMonthDays.compactMap { $0 })
    }

    private var plannerWeek: [Date] {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: selectedDate) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: interval.start) }
    }

    private var plannerMonthDays: [Date?] {
        guard
            let interval = calendar.dateInterval(of: .month, for: selectedDate),
            let firstWeek = calendar.dateInterval(of: .weekOfMonth, for: interval.start)
        else { return [] }

        let days = calendar.dateComponents([.day], from: firstWeek.start, to: interval.end).day ?? 0
        return (0..<days).map { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: firstWeek.start) else { return nil }
            return calendar.isDate(date, equalTo: selectedDate, toGranularity: .month) ? date : nil
        }
    }

    var body: some View {
        GlassCard(padding: AppTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Workout Planner")
                            .font(AppTheme.Typography.titleSmall)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        Text(split.map { "\($0.label) · \($0.recommendedDaysText)" } ?? "Choose a split to build your plan")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    Spacer()
                    if let split {
                        Text(split.abbreviation)
                            .font(AppTheme.Typography.label)
                            .foregroundColor(AppTheme.Colors.accentSecondary)
                            .padding(.horizontal, AppTheme.Spacing.sm)
                            .padding(.vertical, 4)
                            .background(AppTheme.Colors.accentPrimary.opacity(0.1))
                            .cornerRadius(AppTheme.Radius.full)
                    }
                }

                HStack(spacing: AppTheme.Spacing.sm) {
                    Button(action: onEditPlan) {
                        Label("Edit Plan", systemImage: "slider.horizontal.3")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.accentSecondary)
                    }
                    .buttonStyle(.plain)

                    if vm.plannerHasOverride(for: selectedDate) {
                        Button {
                            vm.removeWorkoutPlannerOverride(for: selectedDate)
                        } label: {
                            Label("Reset", systemImage: "arrow.uturn.backward")
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Colors.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()
                }

                PlannerDateStrip(
                    selectedDate: $selectedDate,
                    weekDates: plannerWeek,
                    loggedDays: loggedDays,
                    completedDays: completedDays
                )

                Picker("Planner Scope", selection: $scope) {
                    ForEach(WorkoutPlannerScope.allCases) { scope in
                        Text(scope.rawValue).tag(scope)
                    }
                }
                .pickerStyle(.segmented)

                if let selectedWorkout {
                    PlannedWorkoutHeadline(
                        workout: selectedWorkout,
                        selectedDate: selectedDate,
                        completionFraction: vm.completionFraction(for: selectedWorkout),
                        isCompleted: vm.isWorkoutCompleted(selectedWorkout),
                        onToggleCompletion: { vm.toggleWorkoutCompletion(for: selectedWorkout) }
                    )

                    switch scope {
                    case .day:
                        PlannedWorkoutExerciseList(
                            workout: selectedWorkout,
                            isExerciseCompleted: { exercise, index in
                                vm.isExerciseCompleted(exercise, at: index, in: selectedWorkout)
                            },
                            onToggleExercise: { index in
                                vm.toggleExerciseCompletion(at: index, in: selectedWorkout)
                            }
                        )
                    case .week:
                        WorkoutPlannerWeekView(
                            workouts: vm.plannedWorkouts(startingAt: plannerWeek.first ?? selectedDate, days: 7),
                            selectedDate: $selectedDate,
                            loggedDays: loggedDays,
                            completedDays: completedDays,
                            onToggleCompletion: { workout in
                                vm.toggleWorkoutCompletion(for: workout)
                            },
                            onLogWorkout: { workout in
                                vm.prepareWorkoutLog(for: workout)
                                vm.showWorkoutLog = true
                            }
                        )
                    case .month:
                        WorkoutPlannerMonthView(
                            days: plannerMonthDays,
                            selectedDate: $selectedDate,
                            loggedDays: loggedDays,
                            completedDays: completedDays,
                            planner: { date in vm.plannedWorkout(on: date) },
                            onToggleCompletion: { workout in
                                vm.toggleWorkoutCompletion(for: workout)
                            },
                            onLogWorkout: { workout in
                                vm.prepareWorkoutLog(for: workout)
                                vm.showWorkoutLog = true
                            }
                        )
                    }

                    PlannerActionRow(
                        isRestDay: selectedWorkout.isRestDay,
                        isCompleted: vm.isWorkoutCompleted(selectedWorkout),
                        hasOverride: vm.plannerHasOverride(for: selectedDate),
                        onToggleCompletion: {
                            vm.toggleWorkoutCompletion(for: selectedWorkout)
                        },
                        onLogWorkout: {
                            vm.prepareWorkoutLog(for: selectedWorkout)
                            vm.showWorkoutLog = true
                        },
                        onReset: {
                            vm.removeWorkoutPlannerOverride(for: selectedDate)
                        }
                    )
                } else {
                    Text("Set up your fitness profile to build a workout plan.")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
        }
    }
}

private struct PlannerActionRow: View {
    let isRestDay: Bool
    let isCompleted: Bool
    let hasOverride: Bool
    let onToggleCompletion: () -> Void
    let onLogWorkout: () -> Void
    let onReset: () -> Void

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            if !isRestDay {
                PlannerQuickActionButton(
                    title: isCompleted ? "Undo Complete" : "Mark Complete",
                    systemImage: isCompleted ? "arrow.uturn.backward.circle" : "checkmark.circle.fill",
                    tint: isCompleted ? AppTheme.Colors.success : AppTheme.Colors.accentSecondary,
                    accessibilityIdentifier: "pt-planner-action-toggle-completion",
                    action: onToggleCompletion
                )

                PlannerQuickActionButton(
                    title: "Log Workout",
                    systemImage: "plus.circle.fill",
                    tint: AppTheme.Colors.accentSecondary,
                    accessibilityIdentifier: "pt-planner-action-log-workout",
                    action: onLogWorkout
                )
            }

            if hasOverride {
                PlannerQuickActionButton(
                    title: "Reset to Split",
                    systemImage: "arrow.uturn.backward",
                    tint: AppTheme.Colors.textTertiary,
                    accessibilityIdentifier: "pt-planner-action-reset",
                    action: onReset
                )
            }
        }
    }
}

private struct PlannerQuickActionButton: View {
    let title: String
    let systemImage: String
    let tint: Color
    let accessibilityIdentifier: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                Text(title)
            }
            .font(AppTheme.Typography.bodySmall)
            .foregroundColor(tint)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(tint.opacity(0.12))
            .cornerRadius(AppTheme.Radius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                    .stroke(tint.opacity(0.18), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}

private struct PlannerDateStrip: View {
    @Binding var selectedDate: Date
    let weekDates: [Date]
    let loggedDays: Set<Date>
    let completedDays: Set<Date>

    private let calendar = Calendar.current

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.sm) {
                ForEach(weekDates, id: \.self) { date in
                    Button {
                        selectedDate = calendar.startOfDay(for: date)
                    } label: {
                        VStack(spacing: 4) {
                            Text(date.formatted(.dateTime.weekday(.narrow)))
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.textTertiary)
                            Text(date.formatted(.dateTime.day()))
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(calendar.isDate(date, inSameDayAs: selectedDate) ? .white : AppTheme.Colors.textPrimary)
                            Circle()
                                .fill(
                                    completedDays.contains(calendar.startOfDay(for: date)) ? AppTheme.Colors.success :
                                        (loggedDays.contains(calendar.startOfDay(for: date)) ? AppTheme.Colors.warning : Color.clear)
                                )
                                .frame(width: 6, height: 6)
                        }
                        .frame(width: 44, height: 62)
                        .background(calendar.isDate(date, inSameDayAs: selectedDate) ? AppTheme.Colors.accentPrimary : AppTheme.Colors.backgroundElevated)
                        .cornerRadius(AppTheme.Radius.md)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct PlannedWorkoutHeadline: View {
    let workout: PlannedWorkout
    let selectedDate: Date
    let completionFraction: Double
    let isCompleted: Bool
    let onToggleCompletion: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(selectedDate.formatted(.dateTime.weekday(.wide).month().day()))
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                    Text(workout.workout.name)
                        .font(AppTheme.Typography.titleMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    Text(workout.workout.focus)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text("\(workout.durationMinutes) min")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.accentSecondary)
                    Text(workout.isRestDay ? "Recovery" : "\(workout.workout.exercises.count) moves")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                    if workout.isCustom {
                        Text("Custom")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.warning)
                    }
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.xs) {
                    ForEach(workout.muscleGroups, id: \.self) { group in
                        Text(group)
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .padding(.horizontal, AppTheme.Spacing.sm)
                            .padding(.vertical, 6)
                            .background(AppTheme.Colors.backgroundElevated)
                            .cornerRadius(AppTheme.Radius.full)
                    }
                }
            }

            if !workout.isRestDay {
                HStack(spacing: AppTheme.Spacing.sm) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(isCompleted ? "Workout complete" : "Workout progress")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textTertiary)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(AppTheme.Colors.glassBorder)
                                    .frame(height: 6)
                                Capsule()
                                    .fill(isCompleted ? AppTheme.Colors.success : AppTheme.Colors.accentSecondary)
                                    .frame(width: geo.size.width * completionFraction, height: 6)
                            }
                        }
                        .frame(height: 6)
                    }

                    Button(action: onToggleCompletion) {
                        Text(isCompleted ? "Mark Incomplete" : "Mark Done")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(isCompleted ? AppTheme.Colors.success : AppTheme.Colors.accentSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            if let notes = workout.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                    Text(notes)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                .padding(AppTheme.Spacing.sm)
                .background(AppTheme.Colors.backgroundElevated)
                .cornerRadius(AppTheme.Radius.md)
            }
        }
    }
}

private struct PlannedWorkoutExerciseList: View {
    let workout: PlannedWorkout
    let isExerciseCompleted: (ExerciseEntry, Int) -> Bool
    let onToggleExercise: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            if workout.isRestDay {
                HStack(spacing: 8) {
                    Image(systemName: "moon.zzz.fill")
                        .foregroundColor(Color(hex: "#A29BFE"))
                    Text("Recovery day. Use this slot for mobility, a walk, or full rest.")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                .padding(AppTheme.Spacing.sm)
                .background(AppTheme.Colors.backgroundElevated)
                .cornerRadius(AppTheme.Radius.md)
            } else {
                ForEach(Array(workout.workout.exercises.prefix(6).enumerated()), id: \.offset) { index, exercise in
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Button {
                            onToggleExercise(index)
                        } label: {
                            Image(systemName: isExerciseCompleted(exercise, index) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(isExerciseCompleted(exercise, index) ? AppTheme.Colors.success : AppTheme.Colors.textTertiary)
                        }
                        .buttonStyle(.plain)
                        Image(systemName: exercise.isCardio ? "figure.run" : "dumbbell.fill")
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                            .frame(width: 18)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(exercise.name)
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Colors.textPrimary)
                            if let notes = exercise.notes, !notes.isEmpty {
                                Text(notes)
                                    .font(AppTheme.Typography.caption)
                                    .foregroundColor(AppTheme.Colors.textTertiary)
                            }
                        }
                        Spacer()
                        Text("\(exercise.sets)×\(exercise.reps)")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                }
            }
        }
    }
}

private struct WorkoutPlannerWeekView: View {
    let workouts: [PlannedWorkout]
    @Binding var selectedDate: Date
    let loggedDays: Set<Date>
    let completedDays: Set<Date>
    let onToggleCompletion: (PlannedWorkout) -> Void
    let onLogWorkout: (PlannedWorkout) -> Void

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            ForEach(workouts) { workout in
                HStack(spacing: AppTheme.Spacing.sm) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(workout.date.formatted(.dateTime.weekday(.abbreviated).day()))
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textTertiary)
                        Text(workout.workout.name)
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        Text(workout.workout.focus)
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .lineLimit(2)
                    }
                    Spacer()
                    if completedDays.contains(calendar.startOfDay(for: workout.date)) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppTheme.Colors.success)
                    } else if loggedDays.contains(calendar.startOfDay(for: workout.date)) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppTheme.Colors.warning)
                    } else if workout.isCustom {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(AppTheme.Colors.warning)
                    }
                }
                .padding(AppTheme.Spacing.sm)
                .background(calendar.isDate(workout.date, inSameDayAs: selectedDate) ? AppTheme.Colors.accentPrimary.opacity(0.08) : AppTheme.Colors.backgroundElevated)
                .cornerRadius(AppTheme.Radius.md)
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedDate = workout.date
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    if !workout.isRestDay {
                        Button {
                            onLogWorkout(workout)
                        } label: {
                            Label("Log", systemImage: "plus.circle.fill")
                        }
                        .tint(Color(hex: "#45B7D1"))

                        Button {
                            onToggleCompletion(workout)
                        } label: {
                            Label(
                                completedDays.contains(calendar.startOfDay(for: workout.date)) ? "Undo" : "Complete",
                                systemImage: completedDays.contains(calendar.startOfDay(for: workout.date)) ? "arrow.uturn.backward.circle" : "checkmark.circle.fill"
                            )
                        }
                        .tint(completedDays.contains(calendar.startOfDay(for: workout.date)) ? AppTheme.Colors.success : AppTheme.Colors.accentPrimary)
                    }
                }
                .accessibilityIdentifier("pt-week-workout-\(calendar.startOfDay(for: workout.date).timeIntervalSince1970)")
            }
        }
    }
}

private struct WorkoutPlannerMonthView: View {
    let days: [Date?]
    @Binding var selectedDate: Date
    let loggedDays: Set<Date>
    let completedDays: Set<Date>
    let planner: (Date) -> PlannedWorkout?
    let onToggleCompletion: (PlannedWorkout) -> Void
    let onLogWorkout: (PlannedWorkout) -> Void

    private let calendar = Calendar.current
    private let weekdayLabels = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                ForEach(Array(weekdayLabels.enumerated()), id: \.offset) { _, label in
                    Text(label)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }

                ForEach(Array(days.enumerated()), id: \.offset) { _, date in
                    if let date {
                        let plannedWorkout = planner(date)
                        WorkoutPlannerMonthCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isLogged: loggedDays.contains(calendar.startOfDay(for: date)),
                            isCompleted: completedDays.contains(calendar.startOfDay(for: date)),
                            isTrainingDay: !(plannedWorkout?.isRestDay ?? true),
                            isCustom: plannedWorkout?.isCustom ?? false,
                            onQuickToggleCompletion: plannedWorkout.map { workout in
                                { onToggleCompletion(workout) }
                            }
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedDate = calendar.startOfDay(for: date)
                        }
                        .contextMenu {
                            if let plannedWorkout, !plannedWorkout.isRestDay {
                                Button {
                                    onToggleCompletion(plannedWorkout)
                                } label: {
                                    Label(
                                        completedDays.contains(calendar.startOfDay(for: date)) ? "Mark Incomplete" : "Mark Complete",
                                        systemImage: completedDays.contains(calendar.startOfDay(for: date)) ? "arrow.uturn.backward.circle" : "checkmark.circle.fill"
                                    )
                                }

                                Button {
                                    onLogWorkout(plannedWorkout)
                                } label: {
                                    Label("Log Workout", systemImage: "plus.circle.fill")
                                }
                            }
                        }
                    } else {
                        Color.clear.frame(height: 40)
                    }
                }
            }
        }
    }
}

private struct WorkoutPlannerMonthCell: View {
    let date: Date
    let isSelected: Bool
    let isLogged: Bool
    let isCompleted: Bool
    let isTrainingDay: Bool
    let isCustom: Bool
    let onQuickToggleCompletion: (() -> Void)?

    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                .fill(isSelected ? AppTheme.Colors.accentPrimary.opacity(0.14) : AppTheme.Colors.backgroundElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                        .stroke(
                            isSelected ? AppTheme.Colors.accentPrimary.opacity(0.35) :
                                (isTrainingDay ? AppTheme.Colors.accentPrimary.opacity(0.14) : AppTheme.Colors.glassBorder),
                            lineWidth: 1
                        )
                )

            Text(date.formatted(.dateTime.day()))
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Colors.textPrimary)

            Circle()
                .fill(
                    isCompleted ? AppTheme.Colors.success :
                        (isLogged ? AppTheme.Colors.warning :
                        (isCustom ? AppTheme.Colors.warning :
                            (isTrainingDay ? AppTheme.Colors.warning.opacity(0.9) : Color.clear)))
                )
                .frame(width: 6, height: 6)
                .padding(.bottom, 4)

            if isTrainingDay, let onQuickToggleCompletion {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: onQuickToggleCompletion) {
                            Image(systemName: isCompleted ? "arrow.uturn.backward.circle.fill" : "checkmark.circle.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(isCompleted ? AppTheme.Colors.success : AppTheme.Colors.accentSecondary)
                                .padding(3)
                                .background(AppTheme.Colors.backgroundPrimary.opacity(0.92))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 2)
                        .padding(.trailing, 2)
                    }
                    Spacer()
                }
            }
        }
        .frame(height: 40)
    }
}

private struct WorkoutPlannerEditorSheet: View {
    let draft: WorkoutPlannerDraft
    let hasSavedOverride: Bool
    let weekDates: [Date]
    let monthDates: [Date]
    let onSave: (WorkoutPlannerDraft) -> Void
    let onSaveWeek: (WorkoutPlannerDraft) -> Void
    let onSaveMonth: (WorkoutPlannerDraft) -> Void
    let onReset: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var editableDraft: WorkoutPlannerDraft
    @State private var selectedExerciseCategory: ExerciseLibraryCategory = .upper
    @State private var editableExercises: [WorkoutPlannerExerciseDraft]

    init(
        draft: WorkoutPlannerDraft,
        hasSavedOverride: Bool,
        weekDates: [Date],
        monthDates: [Date],
        onSave: @escaping (WorkoutPlannerDraft) -> Void,
        onSaveWeek: @escaping (WorkoutPlannerDraft) -> Void,
        onSaveMonth: @escaping (WorkoutPlannerDraft) -> Void,
        onReset: @escaping () -> Void
    ) {
        self.draft = draft
        self.hasSavedOverride = hasSavedOverride
        self.weekDates = weekDates
        self.monthDates = monthDates
        self.onSave = onSave
        self.onSaveWeek = onSaveWeek
        self.onSaveMonth = onSaveMonth
        self.onReset = onReset
        _editableDraft = State(initialValue: draft)
        _editableExercises = State(initialValue: draft.exerciseDrafts)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.backgroundPrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        headerSection
                        templateSection
                        detailsSection

                        if !editableDraft.isRestDay {
                            exerciseLibrarySection
                            exerciseEditorSection
                        }

                        notesSection
                        saveSection
                        reuseSection

                        if hasSavedOverride { resetButton }
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.lg)
                }
            }
            .navigationTitle("Edit Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var filteredExerciseLibraryItems: [ExerciseLibraryItem] {
        ExerciseLibraryCatalog.items.filter { $0.category == selectedExerciseCategory }
    }

    private var headerSection: some View {
        GlassCard(padding: AppTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text(editableDraft.date.formatted(.dateTime.weekday(.wide).month().day()))
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textTertiary)
                Text("Plan this workout your way.")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }

    private var templateSection: some View {
        GlassCard(padding: AppTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("Quick Templates")
                    .font(AppTheme.Typography.titleSmall)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Text("Start with a common workout, then tweak anything you want.")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textTertiary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        ForEach(WorkoutPlannerTemplatePreset.allCases) { template in
                            Button {
                                editableDraft.applyTemplate(template)
                                editableExercises = editableDraft.exerciseDrafts
                            } label: {
                                PlannerTemplateChip(template: template)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var detailsSection: some View {
        GlassCard(padding: AppTheme.Spacing.md) {
            VStack(spacing: AppTheme.Spacing.md) {
                AuthTextField(
                    placeholder: "Workout title",
                    icon: "figure.strengthtraining.traditional",
                    text: $editableDraft.title,
                    autocapitalization: .words,
                    autocorrectionDisabled: false
                )

                AuthTextField(
                    placeholder: "Focus or goal for the session",
                    icon: "target",
                    text: $editableDraft.focus,
                    autocapitalization: .sentences,
                    autocorrectionDisabled: false
                )

                AuthTextField(
                    placeholder: "Muscle groups (comma separated)",
                    icon: "list.bullet",
                    text: $editableDraft.muscleGroupsText,
                    autocapitalization: .words,
                    autocorrectionDisabled: false
                )

                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    HStack {
                        Text("Duration")
                            .font(AppTheme.Typography.label)
                            .foregroundColor(AppTheme.Colors.textTertiary)
                        Spacer()
                        Text("\(Int(editableDraft.durationMinutes.rounded())) min")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.accentSecondary)
                    }
                    Slider(value: $editableDraft.durationMinutes, in: 10...180, step: 5)
                        .tint(AppTheme.Colors.accentPrimary)
                }

                Toggle("Recovery / rest day", isOn: $editableDraft.isRestDay)
                    .tint(AppTheme.Colors.accentPrimary)
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }
        }
    }

    private var exerciseLibrarySection: some View {
        GlassCard(padding: AppTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("Exercise Library")
                    .font(AppTheme.Typography.titleSmall)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Text("Tap to add common movements into your workout.")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textTertiary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        ForEach(ExerciseLibraryCategory.allCases) { category in
                            Button {
                                selectedExerciseCategory = category
                            } label: {
                                Text(category.rawValue)
                                    .font(AppTheme.Typography.bodySmall)
                                    .foregroundColor(selectedExerciseCategory == category ? .white : AppTheme.Colors.textSecondary)
                                    .padding(.horizontal, AppTheme.Spacing.sm)
                                    .padding(.vertical, AppTheme.Spacing.xs)
                                    .background(selectedExerciseCategory == category ? AppTheme.Colors.accentPrimary : AppTheme.Colors.backgroundElevated)
                                    .cornerRadius(AppTheme.Radius.full)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        ForEach(filteredExerciseLibraryItems) { item in
                            Button {
                                editableDraft.appendExercise(item.exercise)
                                editableExercises = editableDraft.exerciseDrafts
                            } label: {
                                ExerciseLibraryChip(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var exerciseEditorSection: some View {
        GlassCard(padding: AppTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Exercises")
                            .font(AppTheme.Typography.titleSmall)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        Text("Edit each row instead of typing the whole list manually.")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                    Spacer()
                    Button {
                        editableExercises.append(
                            WorkoutPlannerExerciseDraft(
                                name: "New Exercise",
                                sets: 3,
                                reps: "8-10",
                                notes: "",
                                isCardio: false
                            )
                        )
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(AppTheme.Colors.accentSecondary)
                    }
                    .buttonStyle(.plain)
                }

                if editableExercises.isEmpty {
                    Text("Add an exercise to start building this workout.")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                } else {
                    ForEach(Array(editableExercises.enumerated()), id: \.element.id) { index, exercise in
                        PlannerExerciseEditorRow(
                            exercise: $editableExercises[index],
                            canMoveUp: index > 0,
                            canMoveDown: index < editableExercises.count - 1,
                            onMoveUp: { moveExercise(at: index, direction: -1) },
                            onMoveDown: { moveExercise(at: index, direction: 1) }
                        ) {
                            editableExercises.removeAll { $0.id == exercise.id }
                        }
                    }
                }
            }
        }
    }

    private var notesSection: some View {
        PlannerEditorTextCard(
            title: "Notes",
            subtitle: "Add anything you want to remember for this session.",
            text: $editableDraft.notes
        )
    }

    private var saveSection: some View {
        PrimaryButton("Save Plan") {
            onSave(synchronizedDraft())
            dismiss()
        }
    }

    private var reuseSection: some View {
        GlassCard(padding: AppTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("Reuse This Plan")
                    .font(AppTheme.Typography.titleSmall)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Text("Copy this workout across a larger schedule to build your week or month faster.")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textTertiary)

                Button {
                    onSaveWeek(synchronizedDraft())
                    dismiss()
                } label: {
                    PlannerApplyButtonLabel(
                        title: "Apply to This Week",
                        subtitle: "\(weekDates.count) days"
                    )
                }
                .buttonStyle(.plain)

                Button {
                    onSaveMonth(synchronizedDraft())
                    dismiss()
                } label: {
                    PlannerApplyButtonLabel(
                        title: "Apply to This Month",
                        subtitle: "\(monthDates.count) days"
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var resetButton: some View {
        Button(role: .destructive) {
            onReset()
            dismiss()
        } label: {
            Text("Reset to Split Default")
                .font(AppTheme.Typography.bodySmall)
        }
    }

    private func synchronizedDraft() -> WorkoutPlannerDraft {
        var draft = editableDraft
        draft.replaceExercises(with: editableExercises)
        return draft
    }

    private func moveExercise(at index: Int, direction: Int) {
        let destination = index + direction
        guard editableExercises.indices.contains(index),
              editableExercises.indices.contains(destination) else { return }
        editableExercises.swapAt(index, destination)
    }
}

private struct PlannerTemplateChip: View {
    let template: WorkoutPlannerTemplatePreset

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(template.title)
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Colors.textPrimary)
            Text(template.focus)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.textTertiary)
                .lineLimit(2)
        }
        .frame(width: 140, alignment: .leading)
        .padding(AppTheme.Spacing.sm)
        .background(AppTheme.Colors.backgroundElevated)
        .cornerRadius(AppTheme.Radius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                .stroke(AppTheme.Colors.glassBorder, lineWidth: 1)
        )
    }
}

private struct ExerciseLibraryChip: View {
    let item: ExerciseLibraryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.exercise.name)
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Colors.textPrimary)
            Text("\(item.exercise.sets)x\(item.exercise.reps)")
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.accentSecondary)
            if let notes = item.exercise.notes, !notes.isEmpty {
                Text(notes)
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .lineLimit(2)
            }
        }
        .frame(width: 150, alignment: .leading)
        .padding(AppTheme.Spacing.sm)
        .background(AppTheme.Colors.backgroundElevated)
        .cornerRadius(AppTheme.Radius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                .stroke(AppTheme.Colors.glassBorder, lineWidth: 1)
        )
    }
}

private struct PlannerExerciseEditorRow: View {
    @Binding var exercise: WorkoutPlannerExerciseDraft
    let canMoveUp: Bool
    let canMoveDown: Bool
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            HStack(spacing: AppTheme.Spacing.sm) {
                TextField("Exercise name", text: $exercise.name)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Button(action: onMoveUp) {
                    Image(systemName: "arrow.up.circle")
                        .foregroundColor(canMoveUp ? AppTheme.Colors.textSecondary : AppTheme.Colors.textTertiary.opacity(0.4))
                }
                .buttonStyle(.plain)
                .disabled(!canMoveUp)

                Button(action: onMoveDown) {
                    Image(systemName: "arrow.down.circle")
                        .foregroundColor(canMoveDown ? AppTheme.Colors.textSecondary : AppTheme.Colors.textTertiary.opacity(0.4))
                }
                .buttonStyle(.plain)
                .disabled(!canMoveDown)

                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(AppTheme.Colors.error)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: AppTheme.Spacing.sm) {
                Stepper(value: $exercise.sets, in: 1...10) {
                    Text("Sets: \(exercise.sets)")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }

                TextField("Reps", text: $exercise.reps)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 90)
            }

            TextField("Notes", text: $exercise.notes)
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .textFieldStyle(.roundedBorder)

            Toggle("Cardio movement", isOn: $exercise.isCardio)
                .tint(AppTheme.Colors.accentPrimary)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .padding(AppTheme.Spacing.sm)
        .background(AppTheme.Colors.backgroundElevated)
        .cornerRadius(AppTheme.Radius.md)
    }
}

private struct PlannerApplyButtonLabel: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Text(subtitle)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
            Spacer()
            Image(systemName: "arrow.right.circle.fill")
                .foregroundColor(AppTheme.Colors.accentSecondary)
        }
        .padding(AppTheme.Spacing.sm)
        .background(AppTheme.Colors.backgroundElevated)
        .cornerRadius(AppTheme.Radius.md)
    }
}

private struct PlannerEditorTextCard: View {
    let title: String
    let subtitle: String
    @Binding var text: String

    var body: some View {
        GlassCard(padding: AppTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text(title)
                    .font(AppTheme.Typography.titleSmall)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Text(subtitle)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textTertiary)

                TextEditor(text: $text)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: title == "Exercises" ? 150 : 120)
                    .padding(AppTheme.Spacing.sm)
                    .background(AppTheme.Colors.backgroundElevated)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                            .stroke(AppTheme.Colors.glassBorder, lineWidth: 1)
                    )
                    .cornerRadius(AppTheme.Radius.md)
            }
        }
    }
}

// MARK: ── Daily Energy Card ───────────────────────────────────
struct DailyEnergyCard: View {
    let summary: NetCalorieSummary
    var body: some View {
        GlassCard(padding: AppTheme.Spacing.md) {
            VStack(spacing: AppTheme.Spacing.md) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.circle.fill").foregroundColor(Color(hex: "#FFD700"))
                        Text("Daily Energy").font(AppTheme.Typography.titleSmall).foregroundColor(AppTheme.Colors.textPrimary)
                    }
                    Spacer()
                }
                HStack(spacing: 0) {
                    EnergyCol(label: "Calories In", value: "\(summary.caloriesIn)", unit: "kcal", color: "#FF9F0A", icon: "fork.knife")
                    Divider().background(AppTheme.Colors.glassBorder).frame(height: 44)
                    EnergyCol(label: "Calories Out", value: "\(summary.caloriesOut)", unit: "kcal", color: "#45B7D1", icon: "flame.fill")
                    Divider().background(AppTheme.Colors.glassBorder).frame(height: 44)
                    EnergyCol(label: "Net", value: summary.netLabel, unit: "", color: summary.netColor.description, icon: "equal.circle.fill", highlight: true)
                }
                Text("For educational reference only. Calorie data from logged meals and activity.")
                    .font(.system(size: 10)).foregroundColor(AppTheme.Colors.textTertiary)
            }
        }
    }
}

private struct EnergyCol: View {
    let label: String; let value: String; let unit: String; let color: String; let icon: String; var highlight: Bool = false
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 14)).foregroundColor(Color(hex: color))
            Text(value).font(.system(size: highlight ? 14 : 18, weight: .bold, design: .rounded))
                .foregroundColor(highlight ? Color(hex: color) : AppTheme.Colors.textPrimary).lineLimit(1).minimumScaleFactor(0.7)
            if !unit.isEmpty { Text(unit).font(.system(size: 9)).foregroundColor(AppTheme.Colors.textTertiary) }
            Text(label).font(AppTheme.Typography.caption).foregroundColor(AppTheme.Colors.textTertiary)
        }.frame(maxWidth: .infinity)
    }
}

// MARK: ── AI Coach Card ───────────────────────────────────────
struct AICoachCard: View {
    let recommendations: [AIRecommendation]
    var body: some View {
        GlassCard(padding: AppTheme.Spacing.md) {
            VStack(spacing: AppTheme.Spacing.md) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "brain.head.profile").foregroundColor(AppTheme.Colors.accentSecondary)
                        Text("AI Coach").font(AppTheme.Typography.titleSmall).foregroundColor(AppTheme.Colors.textPrimary)
                    }
                    Spacer()
                    Text("Guidance only").font(AppTheme.Typography.caption).foregroundColor(AppTheme.Colors.textTertiary)
                }
                if recommendations.isEmpty {
                    HStack {
                        Image(systemName: "checkmark.seal.fill").foregroundColor(AppTheme.Colors.success)
                        Text("All systems green — keep it up!").font(AppTheme.Typography.bodySmall).foregroundColor(AppTheme.Colors.textSecondary)
                    }
                } else {
                    ForEach(recommendations) { rec in
                        AIRecommendationRow(rec: rec)
                    }
                }
                Text("AI suggestions are educational. Not medical or professional fitness advice.")
                    .font(.system(size: 10)).foregroundColor(AppTheme.Colors.textTertiary)
            }
        }
    }
}

private struct AIRecommendationRow: View {
    let rec: AIRecommendation
    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
            Image(systemName: rec.category.icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(hex: rec.category.color))
                .frame(width: 30, height: 30)
                .background(Color(hex: rec.category.color).opacity(0.12))
                .cornerRadius(AppTheme.Radius.sm)
            VStack(alignment: .leading, spacing: 3) {
                Text(rec.headline).font(AppTheme.Typography.titleSmall).foregroundColor(AppTheme.Colors.textPrimary)
                Text(rec.detail).font(AppTheme.Typography.bodySmall).foregroundColor(AppTheme.Colors.textSecondary).lineLimit(3)
            }
            Spacer()
            if rec.priority == .high {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 12)).foregroundColor(AppTheme.Colors.warning)
            }
        }
        .padding(AppTheme.Spacing.sm)
        .background(Color(hex: rec.category.color).opacity(0.04))
        .cornerRadius(AppTheme.Radius.md)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.md).stroke(Color(hex: rec.category.color).opacity(0.12), lineWidth: 1))
    }
}

#Preview {
    NavigationStack { PTDashboardView() }
        .environmentObject(AuthViewModel())
        .preferredColorScheme(.dark)
}
