import Foundation

enum FuelScoringEngine {
    static func score(
        nutrition: ProductNutrition,
        category: ProductCategory,
        ingredientFlags: [IngredientFlag],
        goal: UserGoal = .maintenance
    ) -> ProductScores {
        let overall = computeOverall(nutrition: nutrition, category: category, flags: ingredientFlags)
        let fatLoss = computeGoalScore(nutrition: nutrition, goal: .fatLoss, flags: ingredientFlags)
        let muscleGain = computeGoalScore(nutrition: nutrition, goal: .muscleGain, flags: ingredientFlags)
        let performance = computeGoalScore(nutrition: nutrition, goal: .performance, flags: ingredientFlags)
        let convenience = computeConvenience(category: category)
        let factors = buildFactors(nutrition: nutrition, category: category, flags: ingredientFlags)
        let guidance = buildGoalGuidance(nutrition: nutrition, scores: (overall, fatLoss, muscleGain, performance))

        return ProductScores(
            overall: overall,
            fatLoss: fatLoss,
            muscleGain: muscleGain,
            performance: performance,
            convenience: convenience,
            rating: FuelRating.from(score: overall),
            primaryReason: primaryReason(from: factors),
            factors: factors,
            goalGuidance: guidance,
            computedAt: Date()
        )
    }

    private static func computeOverall(
        nutrition n: ProductNutrition,
        category: ProductCategory,
        flags: [IngredientFlag]
    ) -> Int {
        var score = 50.0
        score += proteinBonus(ratio: n.proteinCalorieRatio)

        if n.proteinG >= 25 { score += 8 }
        else if n.proteinG >= 15 { score += 4 }
        else if n.proteinG < 5 && n.calories > 150 { score -= 5 }

        if let sugar = n.sugarG { score += sugarPenalty(sugarG: sugar) }
        if let sodium = n.sodiumMg { score += sodiumPenalty(sodiumMg: sodium) }
        if let satFat = n.saturatedFatG { score += satFatPenalty(satFatG: satFat) }

        if let fiber = n.fiberG {
            if fiber >= 5 { score += 8 }
            else if fiber >= 3 { score += 5 }
            else if fiber >= 1 { score += 2 }
        }

        if let caloriesPer100g = n.calPer100g {
            if caloriesPer100g > 500 { score -= 10 }
            else if caloriesPer100g > 400 { score -= 5 }
        }

        switch category {
        case .supplement:
            score += 5
        case .candy:
            score -= 15
        case .mre:
            score += 3
        default:
            break
        }

        for flag in flags {
            switch flag.severity {
            case .high: score -= 12
            case .medium: score -= 5
            case .low: score -= 2
            }
        }

        return clamp(score)
    }

    private static func computeGoalScore(
        nutrition n: ProductNutrition,
        goal: UserGoal,
        flags: [IngredientFlag]
    ) -> Int {
        var score = 50.0

        switch goal {
        case .fatLoss:
            score += proteinBonus(ratio: n.proteinCalorieRatio) * 1.5
            if let sugar = n.sugarG { score += sugarPenalty(sugarG: sugar) * 1.4 }
            if n.calories > 300 { score -= Double(n.calories - 300) / 25.0 }
            if n.proteinG >= 20 { score += 10 }
            if let satFat = n.saturatedFatG { score += satFatPenalty(satFatG: satFat) * 1.3 }
            if let fiber = n.fiberG, fiber >= 3 { score += 8 }
        case .muscleGain:
            score += proteinBonus(ratio: n.proteinCalorieRatio) * 1.8
            if n.proteinG >= 25 { score += 15 }
            else if n.proteinG >= 15 { score += 8 }
            else if n.proteinG < 12 { score -= 18 }
            if n.calories < 100 && n.proteinG < 10 { score -= 10 }
            if n.proteinG < 15 && n.calories > 220 { score -= 10 }
            if let sugar = n.sugarG { score += sugarPenalty(sugarG: sugar) * 0.7 }
        case .performance:
            score += proteinBonus(ratio: n.proteinCalorieRatio) * 1.2
            if let fiber = n.fiberG, fiber >= 3 { score += 6 }
            if let sugar = n.sugarG { score += sugarPenalty(sugarG: sugar) * 0.9 }
            if let sodium = n.sodiumMg { score += sodiumPenalty(sodiumMg: sodium) * 1.2 }
            if n.carbsG > 20 && n.carbsG < 60 { score += 5 }
        case .highProtein:
            score += proteinBonus(ratio: n.proteinCalorieRatio) * 2.0
            if n.proteinG >= 30 { score += 15 }
            else if n.proteinG >= 20 { score += 8 }
            else if n.proteinG < 10 { score -= 20 }
        case .fieldConvenience:
            score += proteinBonus(ratio: n.proteinCalorieRatio)
            score += computeConvenience(category: .mre) > 70 ? 10 : 0
            if let sodium = n.sodiumMg { score += sodiumPenalty(sodiumMg: sodium) * 0.5 }
        case .maintenance:
            score += proteinBonus(ratio: n.proteinCalorieRatio)
            if let sugar = n.sugarG { score += sugarPenalty(sugarG: sugar) }
            if let sodium = n.sodiumMg { score += sodiumPenalty(sodiumMg: sodium) }
        }

        for flag in flags {
            switch flag.severity {
            case .high: score -= 10
            case .medium: score -= 4
            case .low: score -= 1
            }
        }

        return clamp(score)
    }

    private static func computeConvenience(category: ProductCategory) -> Int {
        switch category {
        case .mre, .snack, .supplement:
            return 85
        case .drink:
            return 80
        case .protein:
            return 75
        case .fastFood, .frozen:
            return 60
        case .meal:
            return 50
        default:
            return 40
        }
    }

    private static func buildFactors(
        nutrition n: ProductNutrition,
        category: ProductCategory,
        flags: [IngredientFlag]
    ) -> [ScoreFactor] {
        var factors: [ScoreFactor] = []

        if n.proteinCalorieRatio >= 0.35 {
            factors.append(.init(label: "High protein efficiency", detail: "\(formatted(n.proteinG))g protein for \(Int(n.calories)) cal.", impact: .positive, category: .protein))
        } else if n.proteinCalorieRatio >= 0.20 {
            factors.append(.init(label: "Solid protein ratio", detail: "\(formatted(n.proteinG))g protein per serving.", impact: .positive, category: .protein))
        } else if n.proteinG < 5 && n.calories > 100 {
            factors.append(.init(label: "Low protein for the calories", detail: "This serving is calorie-heavy without much protein.", impact: .negative, category: .protein))
        }

        if let sugar = n.sugarG {
            if sugar > 20 {
                factors.append(.init(label: "Very high sugar content", detail: "\(formatted(sugar))g sugar per serving.", impact: .negative, category: .sugar))
            } else if sugar <= 3 {
                factors.append(.init(label: "Low sugar", detail: "Only \(formatted(sugar))g sugar per serving.", impact: .positive, category: .sugar))
            }
        }

        if let sodium = n.sodiumMg {
            if sodium > 1000 {
                factors.append(.init(label: "Very high sodium", detail: "\(Int(sodium))mg sodium in one serving.", impact: .negative, category: .sodium))
            } else if sodium < 150 && n.calories > 100 {
                factors.append(.init(label: "Low sodium", detail: "Keeps sodium load low for the serving.", impact: .positive, category: .sodium))
            }
        }

        if let fiber = n.fiberG, fiber >= 3 {
            factors.append(.init(label: "Useful fiber content", detail: "\(formatted(fiber))g fiber supports fullness and balance.", impact: .positive, category: .fiber))
        }

        if let satFat = n.saturatedFatG, satFat > 7 {
            factors.append(.init(label: "High saturated fat", detail: "\(formatted(satFat))g saturated fat per serving.", impact: .negative, category: .fat))
        }

        switch category {
        case .mre:
            factors.append(.init(label: "Field convenient", detail: "Practical for field use or grab-and-go fueling.", impact: .positive, category: .overall))
        case .supplement:
            factors.append(.init(label: "Supplement-focused", detail: "Built for a specific training or recovery use case.", impact: .neutral, category: .overall))
        case .candy:
            factors.append(.init(label: "Limited nutritional value", detail: "Higher sugar and lower performance value than better alternatives.", impact: .negative, category: .overall))
        default:
            break
        }

        for flag in flags.prefix(3) {
            factors.append(.init(label: "Contains \(flag.name)", detail: flag.concern, impact: flag.severity == .low ? .neutral : .negative, category: .ingredients))
        }

        return factors
    }

    private static func buildGoalGuidance(
        nutrition n: ProductNutrition,
        scores: (Int, Int, Int, Int)
    ) -> [GoalGuidance] {
        let (_, fatLoss, muscleGain, performance) = scores
        return [
            GoalGuidance(goal: .fatLoss, headline: fatLoss >= 75 ? "Fits well into a fat loss plan" : fatLoss >= 50 ? "Acceptable for fat loss in moderation" : "Use sparingly during a cut", detail: fatLossDetail(n), rating: FuelRating.from(score: fatLoss)),
            GoalGuidance(goal: .muscleGain, headline: muscleGain >= 75 ? "Supports muscle gain goals" : muscleGain >= 50 ? "Decent option for muscle gain" : "Not optimized for muscle building", detail: muscleGainDetail(n), rating: FuelRating.from(score: muscleGain)),
            GoalGuidance(goal: .performance, headline: performance >= 75 ? "Strong choice for PT performance" : performance >= 50 ? "Adequate for training and activity" : "May not support peak performance", detail: performanceDetail(n), rating: FuelRating.from(score: performance))
        ]
    }

    private static func fatLossDetail(_ n: ProductNutrition) -> String {
        if n.proteinCalorieRatio >= 0.3 {
            return "The protein content is strong for the calorie load."
        }
        if let sugar = n.sugarG, sugar > 15 {
            return "The sugar content makes this harder to fit into a tight cut."
        }
        return "Moderate calories and macros make this manageable in a balanced plan."
    }

    private static func muscleGainDetail(_ n: ProductNutrition) -> String {
        if n.proteinG >= 25 { return "High protein content supports recovery and growth." }
        if n.proteinG >= 15 { return "Moderate protein. Pair it with another protein source if needed." }
        return "Protein is too low to make this a strong muscle-gain choice."
    }

    private static func performanceDetail(_ n: ProductNutrition) -> String {
        if n.carbsG > 30 && n.proteinG > 10 { return "Balanced carbs and protein make this useful around training." }
        if let sodium = n.sodiumMg, sodium > 800 { return "Higher sodium means hydration matters if this is near PT." }
        return "This can fit general training needs depending on timing and portion."
    }

    private static func primaryReason(from factors: [ScoreFactor]) -> String {
        if let positive = factors.first(where: { $0.impact == .positive }) { return positive.label }
        if let negative = factors.first(where: { $0.impact == .negative }) { return negative.label }
        return "Balanced nutritional profile"
    }

    private static func proteinBonus(ratio: Double) -> Double {
        switch ratio {
        case 0.50...: return 25
        case 0.35..<0.50: return 18
        case 0.25..<0.35: return 12
        case 0.15..<0.25: return 6
        case 0.08..<0.15: return 2
        default: return 0
        }
    }

    private static func sugarPenalty(sugarG: Double) -> Double {
        switch sugarG {
        case let sugar where sugar > 25: return -20
        case let sugar where sugar > 18: return -15
        case let sugar where sugar > 12: return -10
        case let sugar where sugar > 6: return -5
        default: return 0
        }
    }

    private static func sodiumPenalty(sodiumMg: Double) -> Double {
        switch sodiumMg {
        case let sodium where sodium > 1200: return -15
        case let sodium where sodium > 900: return -10
        case let sodium where sodium > 600: return -6
        case let sodium where sodium > 400: return -3
        default: return 0
        }
    }

    private static func satFatPenalty(satFatG: Double) -> Double {
        switch satFatG {
        case let sat where sat > 12: return -12
        case let sat where sat > 8: return -8
        case let sat where sat > 5: return -4
        default: return 0
        }
    }

    private static func clamp(_ value: Double) -> Int {
        Int(min(100, max(0, value.rounded())))
    }

    private static func formatted(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(value))" : String(format: "%.1f", value)
    }

    static func flagIngredients(from ingredientsText: String) -> [IngredientFlag] {
        let lower = ingredientsText.lowercased()
        let knownFlags: [(pattern: String, name: String, concern: String, severity: FlagSeverity)] = [
            ("high fructose corn syrup", "High Fructose Corn Syrup", "A highly refined sweetener common in processed foods.", .high),
            ("partially hydrogenated", "Partially Hydrogenated Oils", "A source of trans fats and usually a poor fit choice.", .high),
            ("trans fat", "Trans Fats", "Generally a poor nutritional tradeoff.", .high),
            ("monosodium glutamate", "MSG", "Flavor enhancer that can increase sodium load.", .medium),
            ("sodium nitrite", "Sodium Nitrite", "Preservative commonly found in processed meats.", .medium),
            ("artificial color", "Artificial Colors", "Synthetic dyes with little nutritional upside.", .low),
            ("artificial flavor", "Artificial Flavors", "Flavor additives with limited nutritional value.", .low),
            ("sodium benzoate", "Sodium Benzoate", "Preservative that also adds to sodium load.", .low),
            ("carrageenan", "Carrageenan", "Emulsifier often found in processed foods.", .low),
            ("aspartame", "Aspartame", "Artificial sweetener.", .low),
            ("sucralose", "Sucralose", "Artificial sweetener.", .low)
        ]

        return knownFlags.compactMap { flag in
            lower.contains(flag.pattern)
                ? IngredientFlag(name: flag.name, concern: flag.concern, severity: flag.severity)
                : nil
        }
    }
}
