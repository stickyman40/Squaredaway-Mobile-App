import SwiftUI

struct ChowLogDayView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @StateObject private var vm = ChowLogViewModel()
    @State private var showScanner = false
    @State private var showManualEntry = false
    @State private var appeared = false

    var body: some View {
        ZStack {
            AppTheme.Colors.backgroundPrimary.ignoresSafeArea()

            Circle()
                .fill(AppTheme.Colors.success.opacity(0.06))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: 80, y: -40)

            VStack(spacing: 0) {
                dateNavigator
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.top, AppTheme.Spacing.sm)

                if vm.isLoading {
                    Spacer()
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.accentPrimary))
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: AppTheme.Spacing.lg) {
                            if let summary = vm.summary, let goals = vm.goals {
                                dailyMacroSummary(summary: summary, goals: goals)
                                    .padding(.horizontal, AppTheme.Spacing.md)
                                    .opacity(appeared ? 1 : 0)
                                    .offset(y: appeared ? 0 : 10)
                            }

                            ForEach(MealType.allCases, id: \.self) { mealType in
                                mealSection(mealType: mealType, entries: vm.summary?.entries(for: mealType) ?? [])
                                    .padding(.horizontal, AppTheme.Spacing.md)
                                    .opacity(appeared ? 1 : 0)
                            }

                            Text("Nutrition data is for informational use only. Not medical or dietary advice.")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.textTertiary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, AppTheme.Spacing.xl)

                            Spacer(minLength: 100)
                        }
                        .padding(.top, AppTheme.Spacing.md)
                    }
                }
            }

            VStack {
                Spacer()
                fabRow
                    .padding(.bottom, AppTheme.Spacing.lg)
            }
        }
        .onAppear {
            if let id = authVM.currentUserId {
                vm.configure(userId: id)
            }
            Task { await vm.loadDay() }
            withAnimation(AppTheme.Animation.standard.delay(0.1)) {
                appeared = true
            }
        }
        .sheet(isPresented: $showScanner) {
            NavigationStack {
                BarcodeScannerView(vm: makeScanVM())
            }
        }
        .sheet(isPresented: $showManualEntry) {
            ManualEntrySheet(vm: vm)
        }
    }

    private var dateNavigator: some View {
        HStack {
            Button { vm.goToPreviousDay() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(AppTheme.Colors.backgroundCard)
                    .cornerRadius(AppTheme.Radius.sm)
            }

            Spacer()

            Text(vm.displayDate)
                .font(AppTheme.Typography.titleMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)

            Spacer()

            Button { vm.goToNextDay() } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(vm.isToday ? AppTheme.Colors.textTertiary : AppTheme.Colors.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(vm.isToday ? Color.clear : AppTheme.Colors.backgroundCard)
                    .cornerRadius(AppTheme.Radius.sm)
            }
            .disabled(vm.isToday)
        }
    }

    private func dailyMacroSummary(summary: DailyNutritionSummary, goals: UserNutritionGoals) -> some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(spacing: AppTheme.Spacing.md) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(Int(summary.totalCalories))")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    Text("/ \(goals.calorieTarget) cal")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(summary.remainingCalories)")
                            .font(AppTheme.Typography.titleMedium)
                            .foregroundColor(summary.remainingCalories == 0 ? AppTheme.Colors.error : AppTheme.Colors.success)
                        Text("remaining")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule().fill(AppTheme.Colors.glassBorder).frame(height: 8)
                        Capsule()
                            .fill(summary.calorieProgress >= 1 ? AppTheme.Colors.error : AppTheme.Colors.accentPrimary)
                            .frame(width: geometry.size.width * summary.calorieProgress, height: 8)
                            .animation(AppTheme.Animation.slow, value: summary.calorieProgress)
                    }
                }
                .frame(height: 8)

                Divider().background(AppTheme.Colors.glassBorder)

                MacroProgressStrip(
                    calories: summary.totalCalories,
                    calorieGoal: goals.calorieTarget,
                    protein: summary.totalProtein,
                    proteinGoal: goals.proteinTarget,
                    carbs: summary.totalCarbs,
                    carbGoal: goals.carbTarget,
                    fat: summary.totalFat,
                    fatGoal: goals.fatTarget
                )
            }
        }
    }

    private func mealSection(mealType: MealType, entries: [ChowEntry]) -> some View {
        let mealCalories = Int(entries.reduce(0) { $0 + $1.totalCalories })
        return VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: mealType.icon)
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.Colors.accentSecondary)
                    Text(mealType.rawValue)
                        .font(AppTheme.Typography.label)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .textCase(.uppercase)
                        .tracking(1)
                    Text("· \(mealType.timeRange)")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }

                Spacer()

                if mealCalories > 0 {
                    Text("\(mealCalories) cal")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }

                HStack(spacing: 4) {
                    Button(action: { showScanner = true }) {
                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.Colors.accentSecondary)
                    }
                    Button(action: {
                        vm.manualMealType = mealType
                        showManualEntry = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(AppTheme.Colors.accentSecondary)
                    }
                }
            }

            if entries.isEmpty {
                Text("Tap + to add \(mealType.rawValue.lowercased())")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, AppTheme.Spacing.xs)
            } else {
                ForEach(entries) { entry in
                    ChowEntryRow(entry: entry) {
                        Task { await vm.deleteEntry(entry) }
                    }
                }
            }
        }
    }

    private var fabRow: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Button(action: { showManualEntry = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "pencil")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Manual")
                        .font(AppTheme.Typography.button)
                }
                .foregroundColor(AppTheme.Colors.textPrimary)
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.vertical, AppTheme.Spacing.md)
                .background(AppTheme.Colors.backgroundCard)
                .cornerRadius(AppTheme.Radius.full)
                .overlay(Capsule().stroke(AppTheme.Colors.glassBorder, lineWidth: 1))
            }
            .buttonStyle(PlainButtonStyle())

            Button(action: { showScanner = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "barcode.viewfinder")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Scan Food")
                        .font(AppTheme.Typography.button)
                }
                .foregroundColor(.white)
                .padding(.horizontal, AppTheme.Spacing.xl)
                .padding(.vertical, AppTheme.Spacing.md)
                .background(AppTheme.Gradients.primaryButton)
                .cornerRadius(AppTheme.Radius.full)
                .shadow(color: AppTheme.Colors.accentPrimary.opacity(0.4), radius: 12, x: 0, y: 5)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, AppTheme.Spacing.md)
    }

    private func makeScanVM() -> FuelCheckViewModel {
        let scanVM = FuelCheckViewModel()
        if let id = authVM.currentUserId {
            let goal = vm.goals?.primaryGoal ?? .maintenance
            scanVM.configure(userId: id, goal: goal)
        }
        return scanVM
    }
}

struct ManualEntrySheet: View {
    @ObservedObject var vm: ChowLogViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.backgroundPrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        GlassCard(padding: AppTheme.Spacing.md) {
                            Picker("Meal", selection: $vm.manualMealType) {
                                ForEach(MealType.allCases, id: \.self) { mealType in
                                    Text(mealType.rawValue).tag(mealType)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding(.horizontal, AppTheme.Spacing.md)

                        GlassCard(padding: AppTheme.Spacing.lg) {
                            VStack(spacing: AppTheme.Spacing.md) {
                                AuthTextField(placeholder: "Food name", icon: "fork.knife", text: $vm.manualName)

                                HStack(spacing: AppTheme.Spacing.sm) {
                                    AuthTextField(placeholder: "Calories", icon: "flame.fill", text: $vm.manualCalories, keyboardType: .numberPad)
                                    AuthTextField(placeholder: "Protein (g)", icon: "p.circle.fill", text: $vm.manualProtein, keyboardType: .decimalPad)
                                }

                                HStack(spacing: AppTheme.Spacing.sm) {
                                    AuthTextField(placeholder: "Carbs (g)", icon: "c.circle.fill", text: $vm.manualCarbs, keyboardType: .decimalPad)
                                    AuthTextField(placeholder: "Fat (g)", icon: "f.circle.fill", text: $vm.manualFat, keyboardType: .decimalPad)
                                }

                                AuthTextField(placeholder: "Note (optional)", icon: "note.text", text: $vm.manualNotes)
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.md)

                        PrimaryButton("Add to Log", isLoading: vm.isLoggingManual) {
                            Task { await vm.logManualEntry() }
                        }
                        .padding(.horizontal, AppTheme.Spacing.md)

                        Spacer(minLength: AppTheme.Spacing.xxl)
                    }
                    .padding(.top, AppTheme.Spacing.md)
                }
            }
            .navigationTitle("Manual Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: vm.showManualEntry) { _, showing in
            if !showing {
                dismiss()
            }
        }
    }
}

struct AddToLogSheet: View {
    let product: FuelProduct
    let scanId: UUID?

    @EnvironmentObject private var authVM: AuthViewModel
    @StateObject private var logVM = ChowLogViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var selectedMeal: MealType = AddToLogSheet.suggestedMealType()
    @State private var servings = 1.0
    @State private var notes = ""
    @State private var isLogging = false
    @State private var logSuccess = false

    private var totalCalories: Double { product.nutrition.calories * servings }
    private var totalProtein: Double { product.nutrition.proteinG * servings }
    private var totalCarbs: Double { product.nutrition.carbsG * servings }
    private var totalFat: Double { product.nutrition.fatG * servings }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.backgroundPrimary.ignoresSafeArea()

                if logSuccess {
                    successState
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: AppTheme.Spacing.lg) {
                            productSummaryRow
                                .padding(.horizontal, AppTheme.Spacing.md)

                            GlassCard(padding: AppTheme.Spacing.md) {
                                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                                    Text("Meal")
                                        .font(AppTheme.Typography.label)
                                        .foregroundColor(AppTheme.Colors.textTertiary)
                                        .textCase(.uppercase)
                                        .tracking(1)

                                    HStack(spacing: AppTheme.Spacing.xs) {
                                        ForEach(MealType.allCases, id: \.self) { meal in
                                            Button {
                                                withAnimation(AppTheme.Animation.spring) {
                                                    selectedMeal = meal
                                                }
                                            } label: {
                                                VStack(spacing: 3) {
                                                    Image(systemName: meal.icon)
                                                        .font(.system(size: 14, weight: .semibold))
                                                        .foregroundColor(selectedMeal == meal ? .white : AppTheme.Colors.textTertiary)
                                                    Text(meal.rawValue)
                                                        .font(.system(size: 10, weight: .medium))
                                                        .foregroundColor(selectedMeal == meal ? .white : AppTheme.Colors.textSecondary)
                                                }
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, AppTheme.Spacing.sm)
                                                .background(selectedMeal == meal ? AppTheme.Colors.accentPrimary : AppTheme.Colors.backgroundElevated)
                                                .cornerRadius(AppTheme.Radius.md)
                                                .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.md).stroke(selectedMeal == meal ? Color.clear : AppTheme.Colors.glassBorder, lineWidth: 1))
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, AppTheme.Spacing.md)

                            GlassCard(padding: AppTheme.Spacing.lg) {
                                VStack(spacing: AppTheme.Spacing.md) {
                                    HStack {
                                        Text("Servings")
                                            .font(AppTheme.Typography.bodyMedium)
                                            .foregroundColor(AppTheme.Colors.textSecondary)
                                        Spacer()
                                        Text(servings == 1 ? "1 serving" : String(format: "%.1f servings", servings))
                                            .font(AppTheme.Typography.titleSmall)
                                            .foregroundColor(AppTheme.Colors.accentSecondary)
                                    }

                                    HStack(spacing: AppTheme.Spacing.md) {
                                        Button {
                                            if servings > 0.5 { servings -= 0.5 }
                                        } label: {
                                            Image(systemName: "minus")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(AppTheme.Colors.textSecondary)
                                                .frame(width: 40, height: 40)
                                                .background(AppTheme.Colors.backgroundElevated)
                                                .cornerRadius(AppTheme.Radius.sm)
                                        }
                                        .buttonStyle(PlainButtonStyle())

                                        Slider(value: $servings, in: 0.5...5, step: 0.5)
                                            .tint(AppTheme.Colors.accentPrimary)

                                        Button {
                                            if servings < 5 { servings += 0.5 }
                                        } label: {
                                            Image(systemName: "plus")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(AppTheme.Colors.accentSecondary)
                                                .frame(width: 40, height: 40)
                                                .background(AppTheme.Colors.accentPrimary.opacity(0.15))
                                                .cornerRadius(AppTheme.Radius.sm)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }

                                    Text("1 serving = \(product.servingSize)")
                                        .font(AppTheme.Typography.caption)
                                        .foregroundColor(AppTheme.Colors.textTertiary)
                                }
                            }
                            .padding(.horizontal, AppTheme.Spacing.md)

                            GlassCard(padding: AppTheme.Spacing.md) {
                                VStack(spacing: AppTheme.Spacing.sm) {
                                    Text("Logging")
                                        .font(AppTheme.Typography.label)
                                        .foregroundColor(AppTheme.Colors.textTertiary)
                                        .textCase(.uppercase)
                                        .tracking(1)
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                    HStack {
                                        macroLogPreview(label: "Calories", value: totalCalories, color: "#FF6B6B")
                                        Spacer()
                                        macroLogPreview(label: "Protein", value: totalProtein, color: "#45B7D1", unit: "g")
                                        Spacer()
                                        macroLogPreview(label: "Carbs", value: totalCarbs, color: "#FFD700", unit: "g")
                                        Spacer()
                                        macroLogPreview(label: "Fat", value: totalFat, color: "#FF9F0A", unit: "g")
                                    }
                                }
                            }
                            .padding(.horizontal, AppTheme.Spacing.md)

                            GlassCard(padding: AppTheme.Spacing.md) {
                                HStack(spacing: AppTheme.Spacing.sm) {
                                    Image(systemName: "note.text")
                                        .foregroundColor(AppTheme.Colors.textTertiary)
                                    TextField("Note (optional)", text: $notes)
                                        .font(AppTheme.Typography.bodyMedium)
                                        .foregroundColor(AppTheme.Colors.textPrimary)
                                }
                            }
                            .padding(.horizontal, AppTheme.Spacing.md)

                            PrimaryButton("Log to Chow Log", isLoading: isLogging) {
                                Task { await logIt() }
                            }
                            .padding(.horizontal, AppTheme.Spacing.md)

                            Spacer(minLength: AppTheme.Spacing.xxl)
                        }
                        .padding(.top, AppTheme.Spacing.md)
                    }
                }
            }
            .navigationTitle("Add to Chow Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if let id = authVM.currentUserId {
                logVM.configure(userId: id)
            }
        }
    }

    private var productSummaryRow: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                .fill(AppTheme.Colors.backgroundCard)
                .frame(width: 48, height: 48)
                .overlay(Image(systemName: product.category.icon).font(.system(size: 20)).foregroundColor(AppTheme.Colors.textTertiary))

            VStack(alignment: .leading, spacing: 3) {
                Text(product.name)
                    .font(AppTheme.Typography.titleSmall)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .lineLimit(1)
                if let brand = product.brand {
                    Text(brand)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }

            Spacer()

            if let scores = product.scores {
                FuelRatingBadge(score: scores.overall, rating: scores.rating, size: .small, showLabel: false)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.backgroundCard)
        .cornerRadius(AppTheme.Radius.lg)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.lg).stroke(AppTheme.Colors.glassBorder, lineWidth: 1))
    }

    private var successState: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer()
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.success.opacity(0.12))
                    .frame(width: 120, height: 120)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(AppTheme.Colors.success)
            }
            VStack(spacing: AppTheme.Spacing.sm) {
                Text("Logged!")
                    .font(AppTheme.Typography.displayMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Text("\(product.name) added to your Chow Log.")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            PrimaryButton("Done") { dismiss() }
                .padding(.horizontal, AppTheme.Spacing.xl)
            Spacer()
        }
    }

    private func macroLogPreview(label: String, value: Double, color: String, unit: String = "") -> some View {
        VStack(spacing: 2) {
            Text("\(Int(value))\(unit)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: color))
            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
    }

    private func logIt() async {
        isLogging = true
        let entry = await logVM.logProduct(product, mealType: selectedMeal, servings: servings, scanId: scanId, notes: notes.isEmpty ? nil : notes)
        isLogging = false
        if entry != nil {
            withAnimation(AppTheme.Animation.spring) {
                logSuccess = true
            }
        }
    }

    static func suggestedMealType() -> MealType {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<11: return .breakfast
        case 11..<14: return .lunch
        case 17..<21: return .dinner
        default: return .snack
        }
    }
}
