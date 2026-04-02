import SwiftUI

// MARK: - WeightLogSheet
struct WeightLogSheet: View {
    @ObservedObject var vm: PTDashboardViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.backgroundPrimary.ignoresSafeArea()
                VStack(spacing: AppTheme.Spacing.lg) {

                    // Recent weight trend
                    if !vm.weightHistory.isEmpty {
                        WeightTrendCard(history: vm.weightHistory)
                            .padding(.horizontal, AppTheme.Spacing.md)
                    }

                    GlassCard(padding: AppTheme.Spacing.lg) {
                        VStack(spacing: AppTheme.Spacing.md) {
                            // Input
                            HStack(spacing: AppTheme.Spacing.md) {
                                Image(systemName: "scalemass.fill")
                                    .font(.system(size: 24)).foregroundColor(AppTheme.Colors.accentSecondary)
                                    .frame(width: 52, height: 52).background(AppTheme.Colors.accentPrimary.opacity(0.12)).cornerRadius(AppTheme.Radius.md)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Current Weight").font(AppTheme.Typography.titleSmall).foregroundColor(AppTheme.Colors.textPrimary)
                                    Text("Enter in pounds").font(AppTheme.Typography.caption).foregroundColor(AppTheme.Colors.textTertiary)
                                }
                                Spacer()
                                TextField("lbs", text: $vm.logWeightKg)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.center)
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(AppTheme.Colors.accentSecondary)
                                    .frame(width: 80)
                                    .padding(AppTheme.Spacing.sm)
                                    .background(AppTheme.Colors.backgroundElevated)
                                    .cornerRadius(AppTheme.Radius.md)
                            }
                            // Live BMI preview
                            if let lbs = Double(vm.logWeightKg), lbs > 0,
                               let profile = vm.fitnessProfile {
                                let kg = lbs * 0.453592
                                let meters = profile.heightCm / 100
                                let bmi = meters > 0 ? kg / (meters * meters) : 0
                                let cat = BMICategory.from(bmi: bmi)
                                HStack {
                                    Text("BMI: \(String(format: "%.1f", bmi)) · \(cat.label)")
                                        .font(AppTheme.Typography.bodySmall).foregroundColor(cat.color)
                                    Spacer()
                                    if let goal = profile.goalWeightLbs {
                                        let diff = lbs - goal
                                        Text(diff > 0 ? "\(String(format: "%.0f", diff)) lbs to goal" : "At goal! 🎯")
                                            .font(AppTheme.Typography.bodySmall)
                                            .foregroundColor(diff > 0 ? AppTheme.Colors.textSecondary : AppTheme.Colors.success)
                                    }
                                }
                                .padding(AppTheme.Spacing.sm)
                                .background(cat.bgColor)
                                .cornerRadius(AppTheme.Radius.sm)
                                .animation(AppTheme.Animation.standard, value: bmi)
                            }
                        }
                    }.padding(.horizontal, AppTheme.Spacing.md)

                    PrimaryButton("Log Weight", isLoading: vm.isLoggingWeight) {
                        Task { await vm.logWeight() }
                    }.padding(.horizontal, AppTheme.Spacing.md)

                    Spacer()
                }
                .padding(.top, AppTheme.Spacing.md)
            }
            .navigationTitle("Log Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: { Image(systemName: "xmark").foregroundColor(AppTheme.Colors.textSecondary) }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Weight Trend Card
private struct WeightTrendCard: View {
    let history: [WeightLog]
    private var recent: [WeightLog] { Array(history.prefix(7)) }
    private var trend: Double {
        guard recent.count >= 2 else { return 0 }
        return recent[0].weightLbs - recent[recent.count - 1].weightLbs
    }
    private var trendColor: Color {
        abs(trend) < 0.5 ? Color(hex: "#96CEB4") : trend < 0 ? AppTheme.Colors.success : Color(hex: "#FF9F0A")
    }
    var body: some View {
        GlassCard(padding: AppTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                HStack {
                    Text("Weight Trend").font(AppTheme.Typography.titleSmall).foregroundColor(AppTheme.Colors.textPrimary)
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: trend < -0.5 ? "arrow.down.right" : trend > 0.5 ? "arrow.up.right" : "arrow.right")
                            .font(.system(size: 12)).foregroundColor(trendColor)
                        Text(trend == 0 ? "Stable" : String(format: "%+.1f lbs", -trend) + " (7 days)")
                            .font(AppTheme.Typography.bodySmall).foregroundColor(trendColor)
                    }
                }
                // Recent entries
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        ForEach(recent.reversed()) { log in
                            VStack(spacing: 3) {
                                Text(String(format: "%.0f", log.weightLbs))
                                    .font(.system(size: 14, weight: .bold)).foregroundColor(AppTheme.Colors.textPrimary)
                                Text(log.loggedAt.formatted(.dateTime.month(.abbreviated).day()))
                                    .font(.system(size: 10)).foregroundColor(AppTheme.Colors.textTertiary)
                            }
                            .padding(.horizontal, AppTheme.Spacing.sm).padding(.vertical, AppTheme.Spacing.xs)
                            .background(AppTheme.Colors.backgroundElevated).cornerRadius(AppTheme.Radius.sm)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - WorkoutLogSheet
struct WorkoutLogSheet: View {
    @ObservedObject var vm: PTDashboardViewModel
    @Environment(\.dismiss) private var dismiss

    private let workoutTypes = ["Run", "Strength", "HIIT", "Ruck", "Swim", "Yoga/Mobility", "Sports", "Cardio", "Full Body", "Custom"]
    private var availableWorkoutTypes: [String] {
        if workoutTypes.contains(vm.logWorkoutType) {
            return workoutTypes
        }
        return [vm.logWorkoutType] + workoutTypes
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.backgroundPrimary.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppTheme.Spacing.lg) {

                        // Today's planned workout hint
                        if let today = vm.todayWorkout, !today.isRestDay {
                            GlassCard(padding: AppTheme.Spacing.md) {
                                HStack(spacing: AppTheme.Spacing.sm) {
                                    Image(systemName: "lightbulb.fill").foregroundColor(Color(hex: "#FFD700"))
                                    Text("Today's plan: \(today.name) — \(today.focus)")
                                        .font(AppTheme.Typography.bodySmall).foregroundColor(AppTheme.Colors.textSecondary)
                                }
                            }.padding(.horizontal, AppTheme.Spacing.md)
                        }

                        GlassCard(padding: AppTheme.Spacing.lg) {
                            VStack(spacing: AppTheme.Spacing.lg) {
                                // Workout type
                                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                                    Text("Workout Type").font(AppTheme.Typography.label).foregroundColor(AppTheme.Colors.textTertiary).textCase(.uppercase).tracking(1)
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: AppTheme.Spacing.xs) {
                                            ForEach(availableWorkoutTypes, id: \.self) { type in
                                                Button { vm.logWorkoutType = type } label: {
                                                    Text(type)
                                                        .font(AppTheme.Typography.bodySmall)
                                                        .foregroundColor(vm.logWorkoutType == type ? .white : AppTheme.Colors.textSecondary)
                                                        .padding(.horizontal, AppTheme.Spacing.sm).padding(.vertical, AppTheme.Spacing.xs)
                                                        .background(vm.logWorkoutType == type ? AppTheme.Colors.accentPrimary : AppTheme.Colors.backgroundElevated)
                                                        .cornerRadius(AppTheme.Radius.full)
                                                        .overlay(Capsule().stroke(vm.logWorkoutType == type ? Color.clear : AppTheme.Colors.glassBorder, lineWidth: 1))
                                                }.buttonStyle(PlainButtonStyle())
                                            }
                                        }
                                    }
                                }
                                Divider().background(AppTheme.Colors.glassBorder)
                                // Duration
                                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                                    HStack {
                                        Text("Duration").font(AppTheme.Typography.label).foregroundColor(AppTheme.Colors.textTertiary).textCase(.uppercase).tracking(1)
                                        Spacer()
                                        Text("\(vm.logDurationMin) min").font(AppTheme.Typography.titleSmall).foregroundColor(AppTheme.Colors.accentSecondary)
                                    }
                                    Slider(value: Binding(get: { Double(vm.logDurationMin) }, set: { vm.logDurationMin = Int($0) }), in: 10...180, step: 5)
                                        .tint(AppTheme.Colors.accentPrimary)
                                    HStack { Text("10 min").font(.system(size: 10)).foregroundColor(AppTheme.Colors.textTertiary); Spacer(); Text("3 hrs").font(.system(size: 10)).foregroundColor(AppTheme.Colors.textTertiary) }
                                }
                                Divider().background(AppTheme.Colors.glassBorder)
                                // Calories (optional)
                                HStack {
                                    Image(systemName: "flame.fill").foregroundColor(Color(hex: "#FF6B6B"))
                                    TextField("Calories burned (optional)", text: $vm.logCaloriesBurned)
                                        .keyboardType(.numberPad)
                                        .font(AppTheme.Typography.bodyMedium).foregroundColor(AppTheme.Colors.textPrimary)
                                }
                            }
                        }.padding(.horizontal, AppTheme.Spacing.md)

                        PrimaryButton("Log Workout", isLoading: vm.isLoggingWorkout) {
                            Task { await vm.logWorkout() }
                        }.padding(.horizontal, AppTheme.Spacing.md)

                        Spacer(minLength: AppTheme.Spacing.xxl)
                    }.padding(.top, AppTheme.Spacing.md)
                }
            }
            .navigationTitle("Log Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: { Image(systemName: "xmark").foregroundColor(AppTheme.Colors.textSecondary) }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
