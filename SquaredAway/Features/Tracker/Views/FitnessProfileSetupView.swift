import SwiftUI

// MARK: - FitnessProfileSetupView
struct FitnessProfileSetupView: View {
    let existingProfile: FitnessProfile?
    let onSave: (FitnessProfile) -> Void

    @EnvironmentObject private var authVM: AuthViewModel
    @StateObject private var vm = FitnessProfileViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.backgroundPrimary.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppTheme.Spacing.lg) {

                        // ── BMI Live Preview ─────────────────────
                        BMILiveCard(vm: vm)
                            .padding(.horizontal, AppTheme.Spacing.md)

                        // ── Height & Weight ──────────────────────
                        GlassCard(padding: AppTheme.Spacing.lg) {
                            VStack(spacing: AppTheme.Spacing.md) {
                                SectionLabel("Body Measurements")
                                // Height
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Height").font(AppTheme.Typography.bodySmall).foregroundColor(AppTheme.Colors.textSecondary)
                                        Spacer()
                                        Text("\(vm.heightFeet)' \(vm.heightInches)\"").font(AppTheme.Typography.titleSmall).foregroundColor(AppTheme.Colors.accentSecondary)
                                    }
                                    HStack(spacing: AppTheme.Spacing.lg) {
                                        Picker("ft", selection: $vm.heightFeet) {
                                            ForEach(4...7, id: \.self) { Text("\($0) ft").tag($0) }
                                        }.pickerStyle(.wheel).frame(height: 90).clipped()
                                        Picker("in", selection: $vm.heightInches) {
                                            ForEach(0...11, id: \.self) { Text("\($0) in").tag($0) }
                                        }.pickerStyle(.wheel).frame(height: 90).clipped()
                                    }
                                }
                                Divider().background(AppTheme.Colors.glassBorder)
                                // Weight
                                HStack {
                                    AuthTextField(placeholder: "Current weight (lbs)", icon: "scalemass.fill", text: $vm.weightLbs, keyboardType: .decimalPad)
                                }
                                HStack {
                                    AuthTextField(placeholder: "Goal weight (lbs, optional)", icon: "target", text: $vm.goalWeightLbs, keyboardType: .decimalPad)
                                }
                            }
                        }.padding(.horizontal, AppTheme.Spacing.md)

                        // ── Fitness Goal ─────────────────────────
                        GlassCard(padding: AppTheme.Spacing.md) {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                                SectionLabel("Fitness Goal")
                                ForEach(PTFitnessGoal.allCases, id: \.self) { goal in
                                    GoalRow(goal: goal, isSelected: vm.fitnessGoal == goal) {
                                        withAnimation(AppTheme.Animation.spring) { vm.fitnessGoal = goal }
                                    }
                                }
                            }
                        }.padding(.horizontal, AppTheme.Spacing.md)

                        // ── Experience Level ─────────────────────
                        GlassCard(padding: AppTheme.Spacing.md) {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                                SectionLabel("Experience Level")
                                HStack(spacing: AppTheme.Spacing.sm) {
                                    ForEach(ExperienceLevel.allCases, id: \.self) { lvl in
                                        SelectChip(label: lvl.label, isSelected: vm.experienceLevel == lvl) {
                                            vm.experienceLevel = lvl
                                        }
                                    }
                                }
                                Text(vm.experienceLevel.weeklyVolume)
                                    .font(AppTheme.Typography.caption).foregroundColor(AppTheme.Colors.textTertiary)
                            }
                        }.padding(.horizontal, AppTheme.Spacing.md)

                        // ── Workout Split ────────────────────────
                        WorkoutSplitPicker(selected: $vm.workoutSplit)
                            .padding(.horizontal, AppTheme.Spacing.md)

                        // ── Weekly target ────────────────────────
                        GlassCard(padding: AppTheme.Spacing.md) {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                                HStack {
                                    SectionLabel("Weekly Workout Days")
                                    Spacer()
                                    Text("\(vm.weeklyTarget) days/week").font(AppTheme.Typography.titleSmall).foregroundColor(AppTheme.Colors.accentSecondary)
                                }
                                Slider(value: Binding(get: { Double(vm.weeklyTarget) }, set: { vm.weeklyTarget = Int($0) }), in: 2...7, step: 1).tint(AppTheme.Colors.accentPrimary)
                            }
                        }.padding(.horizontal, AppTheme.Spacing.md)

                        // Save button
                        PrimaryButton("Save Fitness Profile", isLoading: vm.isSaving) {
                            Task { await vm.save() }
                        }.padding(.horizontal, AppTheme.Spacing.md)

                        Spacer(minLength: AppTheme.Spacing.xxl)
                    }.padding(.top, AppTheme.Spacing.md)
                }
            }
            .navigationTitle("Fitness Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: { Image(systemName: "xmark").foregroundColor(AppTheme.Colors.textSecondary) }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if let id = authVM.currentUserId { vm.configure(userId: id) }
            if let profile = existingProfile { vm.load(from: profile) }
        }
        .onChange(of: vm.saveSuccess) { _, success in
            if success {
                if let profile = vm.savedProfile {
                    onSave(profile)
                }
                dismiss()
            }
        }
    }
}

// MARK: - BMI Live Card
private struct BMILiveCard: View {
    @ObservedObject var vm: FitnessProfileViewModel
    var body: some View {
        HStack(spacing: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: 4) {
                Text("BMI").font(AppTheme.Typography.label).foregroundColor(AppTheme.Colors.textTertiary).textCase(.uppercase).tracking(1)
                Text(vm.bmi > 0 ? vm.bmiFormatted : "—")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(vm.bmiCategory.color)
                Text(vm.bmi > 0 ? vm.bmiCategory.label : "Enter height & weight")
                    .font(AppTheme.Typography.bodySmall).foregroundColor(AppTheme.Colors.textSecondary)
            }
            Spacer()
            // BMI Scale visual
            BMIScaleBar(bmi: vm.bmi)
        }
        .padding(AppTheme.Spacing.md)
        .background(vm.bmiCategory.bgColor)
        .cornerRadius(AppTheme.Radius.xl)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.xl).stroke(vm.bmiCategory.color.opacity(0.25), lineWidth: 1))
        .animation(AppTheme.Animation.standard, value: vm.bmi)
    }
}

private struct BMIScaleBar: View {
    let bmi: Double
    private let segments: [(color: Color, range: ClosedRange<Double>, label: String)] = [
        (Color(hex: "#FFD700"), 0...18.5, "Under"),
        (Color(hex: "#34C759"), 18.5...25, "Normal"),
        (Color(hex: "#FF9F0A"), 25...30, "Over"),
        (Color(hex: "#FF453A"), 30...50, "High"),
    ]
    private var progress: Double { min(1.0, max(0, (bmi - 10) / 40)) }
    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    HStack(spacing: 2) {
                        ForEach(0..<segments.count, id: \.self) { i in
                            Capsule().fill(segments[i].color.opacity(0.3)).frame(height: 12)
                        }
                    }
                    Circle().fill(bmi > 0 ? Color.white : Color.clear)
                        .frame(width: 14, height: 14)
                        .shadow(radius: 3)
                        .offset(x: geo.size.width * progress - 7)
                        .animation(AppTheme.Animation.slow, value: bmi)
                }
            }.frame(width: 120, height: 14)
            HStack {
                Text("18.5").font(.system(size: 9)).foregroundColor(AppTheme.Colors.textTertiary)
                Spacer()
                Text("25").font(.system(size: 9)).foregroundColor(AppTheme.Colors.textTertiary)
                Spacer()
                Text("30+").font(.system(size: 9)).foregroundColor(AppTheme.Colors.textTertiary)
            }.frame(width: 120)
        }
    }
}

// MARK: - Goal Row
private struct GoalRow: View {
    let goal: PTFitnessGoal; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: goal.icon)
                    .font(.system(size: 16, weight: .semibold)).foregroundColor(Color(hex: goal.color))
                    .frame(width: 36, height: 36).background(Color(hex: goal.color).opacity(0.12)).cornerRadius(AppTheme.Radius.sm)
                Text(goal.label).font(AppTheme.Typography.titleSmall)
                    .foregroundColor(isSelected ? AppTheme.Colors.textPrimary : AppTheme.Colors.textSecondary)
                Spacer()
                if isSelected { Image(systemName: "checkmark.circle.fill").foregroundColor(AppTheme.Colors.accentPrimary) }
            }
            .padding(AppTheme.Spacing.sm)
            .background(isSelected ? AppTheme.Colors.accentPrimary.opacity(0.06) : Color.clear)
            .cornerRadius(AppTheme.Radius.md)
        }.buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Workout Split Picker
struct WorkoutSplitPicker: View {
    @Binding var selected: WorkoutSplit
    var body: some View {
        GlassCard(padding: AppTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                SectionLabel("Workout Split")
                ForEach(WorkoutSplit.allCases.filter { $0 != .custom }, id: \.self) { split in
                    Button { withAnimation(AppTheme.Animation.spring) { selected = split } } label: {
                        HStack(spacing: AppTheme.Spacing.md) {
                            Text(split.abbreviation)
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(selected == split ? .white : AppTheme.Colors.accentSecondary)
                                .frame(width: 44, height: 36)
                                .background(selected == split ? AppTheme.Colors.accentPrimary : AppTheme.Colors.accentPrimary.opacity(0.1))
                                .cornerRadius(AppTheme.Radius.sm)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(split.label).font(AppTheme.Typography.titleSmall).foregroundColor(AppTheme.Colors.textPrimary)
                                Text(split.summary)
                                    .font(AppTheme.Typography.caption)
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                    .lineLimit(2)
                                Text(split.recommendedDaysText)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(AppTheme.Colors.textTertiary)
                            }
                            Spacer()
                            if selected == split { Image(systemName: "checkmark.circle.fill").foregroundColor(AppTheme.Colors.accentPrimary) }
                        }
                        .padding(AppTheme.Spacing.sm)
                        .background(selected == split ? AppTheme.Colors.accentPrimary.opacity(0.06) : Color.clear)
                        .cornerRadius(AppTheme.Radius.md)
                    }.buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

// MARK: - Shared small components
private struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text).font(AppTheme.Typography.label).foregroundColor(AppTheme.Colors.textTertiary).textCase(.uppercase).tracking(1).frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SelectChip: View {
    let label: String; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label).font(AppTheme.Typography.bodySmall)
                .foregroundColor(isSelected ? .white : AppTheme.Colors.textSecondary)
                .padding(.horizontal, AppTheme.Spacing.sm).padding(.vertical, AppTheme.Spacing.xs)
                .background(isSelected ? AppTheme.Colors.accentPrimary : AppTheme.Colors.backgroundElevated)
                .cornerRadius(AppTheme.Radius.full)
                .overlay(Capsule().stroke(isSelected ? Color.clear : AppTheme.Colors.glassBorder, lineWidth: 1))
        }.buttonStyle(PlainButtonStyle())
    }
}
