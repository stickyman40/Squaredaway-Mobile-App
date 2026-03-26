import SwiftUI

struct ProductResultView: View {
    let product: FuelProduct
    let scanId: UUID?
    let isSaved: Bool
    let goal: UserGoal
    let onSaveToggle: () -> Void
    let onScanAgain: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showAddToLog = false
    @State private var appeared = false
    @State private var selectedGoalTab: UserGoal

    init(
        product: FuelProduct,
        scanId: UUID?,
        isSaved: Bool,
        goal: UserGoal,
        onSaveToggle: @escaping () -> Void,
        onScanAgain: @escaping () -> Void
    ) {
        self.product = product
        self.scanId = scanId
        self.isSaved = isSaved
        self.goal = goal
        self.onSaveToggle = onSaveToggle
        self.onScanAgain = onScanAgain
        _selectedGoalTab = State(initialValue: goal)
    }

    private var scores: ProductScores? { product.scores }
    private var displayScore: Int { scores?.score(for: selectedGoalTab) ?? scores?.overall ?? 0 }
    private var displayRating: FuelRating { FuelRating.from(score: displayScore) }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.backgroundPrimary.ignoresSafeArea()

                Circle()
                    .fill(displayRating.color.opacity(0.08))
                    .frame(width: 360, height: 360)
                    .blur(radius: 100)
                    .offset(x: 60, y: -80)
                    .animation(AppTheme.Animation.slow, value: displayRating)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        productHeader
                        ratingHeroCard
                            .padding(.horizontal, AppTheme.Spacing.md)
                        goalSelectorTabs
                            .padding(.horizontal, AppTheme.Spacing.md)

                        if let scores, !scores.factors.isEmpty {
                            factorsSection(scores.factors)
                                .padding(.horizontal, AppTheme.Spacing.md)
                        }

                        macroBreakdownCard
                            .padding(.horizontal, AppTheme.Spacing.md)

                        if let guidance = scores?.goalGuidance.first(where: { $0.goal == selectedGoalTab }) {
                            goalGuidanceCard(guidance)
                                .padding(.horizontal, AppTheme.Spacing.md)
                        }

                        if !product.ingredientFlags.isEmpty {
                            ingredientFlagsSection(product.ingredientFlags)
                                .padding(.horizontal, AppTheme.Spacing.md)
                        }

                        Text("For educational purposes only. Not medical or dietary advice. Suitability depends on your goals, health status, and serving size.")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textTertiary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppTheme.Spacing.xl)

                        Spacer(minLength: 100)
                    }
                    .padding(.top, AppTheme.Spacing.sm)
                }

                VStack {
                    Spacer()
                    bottomActionBar
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .frame(width: 32, height: 32)
                            .background(AppTheme.Colors.backgroundCard)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .onAppear {
            withAnimation(AppTheme.Animation.slow.delay(0.15)) {
                appeared = true
            }
        }
        .sheet(isPresented: $showAddToLog) {
            AddToLogSheet(product: product, scanId: scanId)
        }
        .preferredColorScheme(.dark)
    }

    private var productHeader: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                .fill(AppTheme.Colors.backgroundCard)
                .frame(width: 64, height: 64)
                .overlay(
                    Group {
                        if let url = product.imageURL, let imageURL = URL(string: url) {
                            AsyncImage(url: imageURL) { image in
                                image.resizable().scaledToFit()
                            } placeholder: {
                                Image(systemName: product.category.icon)
                                    .font(.system(size: 24))
                                    .foregroundColor(AppTheme.Colors.textTertiary)
                            }
                        } else {
                            Image(systemName: product.category.icon)
                                .font(.system(size: 24))
                                .foregroundColor(AppTheme.Colors.textTertiary)
                        }
                    }
                )
                .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.md).stroke(AppTheme.Colors.glassBorder, lineWidth: 1))

            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(AppTheme.Typography.titleMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .lineLimit(2)
                if let brand = product.brand {
                    Text(brand)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                Text("Per \(product.servingSize)")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }

            Spacer()

            Button(action: onSaveToggle) {
                Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 18))
                    .foregroundColor(isSaved ? AppTheme.Colors.accentSecondary : AppTheme.Colors.textSecondary)
                    .frame(width: 38, height: 38)
                    .background(isSaved ? AppTheme.Colors.accentPrimary.opacity(0.15) : AppTheme.Colors.backgroundCard)
                    .cornerRadius(AppTheme.Radius.sm)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
    }

    private var ratingHeroCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            HStack(spacing: AppTheme.Spacing.xl) {
                FuelRatingBadge(score: displayScore, rating: displayRating, size: .large)
                    .scaleEffect(appeared ? 1 : 0.5)
                    .opacity(appeared ? 1 : 0)

                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text(displayRating.label.uppercased())
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundColor(displayRating.color)
                        .tracking(0.5)

                    if let reason = product.scores?.primaryReason {
                        Text(reason)
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .lineLimit(3)
                    }

                    HStack(spacing: AppTheme.Spacing.md) {
                        quickMacro(label: "Cal", value: Int(product.nutrition.calories))
                        quickMacro(label: "Pro", value: Int(product.nutrition.proteinG), unit: "g")
                        quickMacro(label: "Carb", value: Int(product.nutrition.carbsG), unit: "g")
                    }
                }

                Spacer()
            }
        }
    }

    private var goalSelectorTabs: some View {
        let goals: [UserGoal] = [.fatLoss, .muscleGain, .performance]
        return HStack(spacing: AppTheme.Spacing.xs) {
            ForEach(goals, id: \.self) { currentGoal in
                Button {
                    withAnimation(AppTheme.Animation.spring) {
                        selectedGoalTab = currentGoal
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: currentGoal.icon)
                            .font(.system(size: 11, weight: .semibold))
                        Text(currentGoal.label)
                            .font(AppTheme.Typography.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(selectedGoalTab == currentGoal ? .white : AppTheme.Colors.textSecondary)
                    .padding(.horizontal, AppTheme.Spacing.sm)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .background(selectedGoalTab == currentGoal ? Color(hex: currentGoal.color) : AppTheme.Colors.backgroundCard)
                    .cornerRadius(AppTheme.Radius.full)
                    .overlay(Capsule().stroke(selectedGoalTab == currentGoal ? Color.clear : AppTheme.Colors.glassBorder, lineWidth: 1))
                }
                .buttonStyle(PlainButtonStyle())
            }

            Spacer()
        }
    }

    private func factorsSection(_ factors: [ScoreFactor]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Why this score")
                .font(AppTheme.Typography.label)
                .foregroundColor(AppTheme.Colors.textTertiary)
                .textCase(.uppercase)
                .tracking(1)

            ForEach(Array(factors.prefix(4))) { factor in
                ScoreFactorRow(factor: factor)
            }
        }
    }

    private var macroBreakdownCard: some View {
        GlassCard(padding: AppTheme.Spacing.md) {
            VStack(spacing: AppTheme.Spacing.md) {
                Text("Nutrition Per Serving")
                    .font(AppTheme.Typography.label)
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .textCase(.uppercase)
                    .tracking(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                macroDetailRow(label: "Calories", value: "\(Int(product.nutrition.calories))", color: "#FF6B6B")
                macroDetailRow(label: "Protein", value: "\(formatted(product.nutrition.proteinG))g", color: "#45B7D1")
                macroDetailRow(label: "Carbohydrates", value: "\(formatted(product.nutrition.carbsG))g", color: "#FFD700")
                if let sugar = product.nutrition.sugarG {
                    macroDetailRow(label: "  -> Sugars", value: "\(formatted(sugar))g", color: "#FF9F0A", isSubrow: true)
                }
                macroDetailRow(label: "Total Fat", value: "\(formatted(product.nutrition.fatG))g", color: "#FF9F0A")
                if let satFat = product.nutrition.saturatedFatG {
                    macroDetailRow(label: "  -> Sat Fat", value: "\(formatted(satFat))g", color: "#FF6B6B", isSubrow: true)
                }
                if let fiber = product.nutrition.fiberG {
                    macroDetailRow(label: "Fiber", value: "\(formatted(fiber))g", color: "#96CEB4")
                }
                if let sodium = product.nutrition.sodiumMg {
                    macroDetailRow(label: "Sodium", value: "\(Int(sodium))mg", color: "#A29BFE")
                }
            }
        }
    }

    private func goalGuidanceCard(_ guidance: GoalGuidance) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
            Image(systemName: guidance.goal.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: guidance.goal.color))
                .frame(width: 36, height: 36)
                .background(Color(hex: guidance.goal.color).opacity(0.12))
                .cornerRadius(AppTheme.Radius.sm)

            VStack(alignment: .leading, spacing: 4) {
                Text(guidance.headline)
                    .font(AppTheme.Typography.titleSmall)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Text(guidance.detail)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }

            Spacer()
            FuelRatingPill(rating: guidance.rating)
        }
        .padding(AppTheme.Spacing.md)
        .background(Color(hex: guidance.goal.color).opacity(0.06))
        .cornerRadius(AppTheme.Radius.lg)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.lg).stroke(Color(hex: guidance.goal.color).opacity(0.2), lineWidth: 1))
    }

    private func ingredientFlagsSection(_ flags: [IngredientFlag]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Ingredient Notes")
                .font(AppTheme.Typography.label)
                .foregroundColor(AppTheme.Colors.textTertiary)
                .textCase(.uppercase)
                .tracking(1)

            ForEach(flags) { flag in
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(flag.severity.color)
                        .frame(width: 28, height: 28)
                        .background(flag.severity.color.opacity(0.1))
                        .cornerRadius(AppTheme.Radius.sm)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(flag.name)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        Text(flag.concern)
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }

                    Spacer()
                }
                .padding(AppTheme.Spacing.sm)
                .background(flag.severity.color.opacity(0.05))
                .cornerRadius(AppTheme.Radius.md)
                .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.md).stroke(flag.severity.color.opacity(0.15), lineWidth: 1))
            }
        }
    }

    private var bottomActionBar: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Button(action: {
                dismiss()
                onScanAgain()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "barcode.viewfinder")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Scan Again")
                        .font(AppTheme.Typography.button)
                }
                .foregroundColor(AppTheme.Colors.textPrimary)
                .frame(height: 52)
                .frame(maxWidth: .infinity)
                .background(AppTheme.Colors.backgroundCard)
                .cornerRadius(AppTheme.Radius.lg)
                .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.lg).stroke(AppTheme.Colors.glassBorder, lineWidth: 1))
            }
            .buttonStyle(PlainButtonStyle())

            Button(action: { showAddToLog = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Add to Chow Log")
                        .font(AppTheme.Typography.button)
                }
                .foregroundColor(.white)
                .frame(height: 52)
                .frame(maxWidth: .infinity)
                .background(AppTheme.Gradients.primaryButton)
                .cornerRadius(AppTheme.Radius.lg)
                .shadow(color: AppTheme.Colors.accentPrimary.opacity(0.35), radius: 10, x: 0, y: 5)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.md)
        .background(AppTheme.Colors.backgroundPrimary.shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: -6))
    }

    private func quickMacro(label: String, value: Int, unit: String = "") -> some View {
        VStack(spacing: 1) {
            Text("\(value)\(unit)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppTheme.Colors.textPrimary)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
    }

    private func macroDetailRow(label: String, value: String, color: String, isSubrow: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(isSubrow ? AppTheme.Typography.caption : AppTheme.Typography.bodySmall)
                .foregroundColor(isSubrow ? AppTheme.Colors.textTertiary : AppTheme.Colors.textSecondary)
            Spacer()
            Text(value)
                .font(AppTheme.Typography.titleSmall)
                .foregroundColor(Color(hex: color))
        }
        .padding(.horizontal, isSubrow ? AppTheme.Spacing.md : 0)
    }

    private func formatted(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(value))" : String(format: "%.1f", value)
    }
}

extension FuelProduct {
    static var preview: FuelProduct {
        let nutrition = ProductNutrition(
            calories: 210,
            proteinG: 25,
            carbsG: 10,
            fatG: 7,
            saturatedFatG: 2,
            fiberG: 1,
            sugarG: 4,
            sodiumMg: 320,
            cholesterolMg: nil,
            potassiumMg: nil,
            calPer100g: 420,
            proteinPer100g: 50,
            carbsPer100g: 20,
            fatPer100g: 14,
            sugarPer100g: 8,
            sodiumPer100g: 640
        )

        return FuelProduct(
            id: UUID(),
            barcode: "123456789012",
            name: "Whey Protein Bar",
            brand: "MilPro Nutrition",
            imageURL: nil,
            category: .protein,
            servingSize: "1 bar (50g)",
            servingSizeGrams: 50,
            nutrition: nutrition,
            scores: FuelScoringEngine.score(nutrition: nutrition, category: .protein, ingredientFlags: [], goal: .muscleGain),
            ingredientFlags: [],
            dataSource: .manual,
            createdAt: Date()
        )
    }
}
