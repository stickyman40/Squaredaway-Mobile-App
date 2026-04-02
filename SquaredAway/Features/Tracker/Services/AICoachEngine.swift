import Foundation

// ============================================================
//  AICoachEngine.swift
//  Rule-based AI recommendation engine. No external API.
//  Evaluates fitness profile + activity data + PT scores and
//  returns 2–3 prioritized, plain-English recommendations.
//
//  Educational guidance only — not medical advice.
//  All recommendation text should remain non-prescriptive.
// ============================================================

enum AICoachEngine {

    // MARK: - Main Entry Point
    // Returns max 3 recommendations sorted by priority.
    static func recommendations(
        profile: FitnessProfile?,
        ptRecord: PTScoreRecord?,
        ptConfig: BranchPTConfig?,
        activityLog: ActivityLog?,
        caloriesIn: Int,
        weightHistory: [WeightLog],
        branch: MilitaryBranch
    ) -> [AIRecommendation] {

        var all: [(rec: AIRecommendation, score: Int)] = []

        // ── BMI-based ────────────────────────────────────────
        if let profile {
            let bmi = profile.bmi
            let bmiCategory = profile.bmiCategory

            if bmiCategory == .overweight || bmiCategory == .obese {
                all.append((
                    AIRecommendation(
                        headline: "BMI is above the optimal range",
                        detail: "A BMI of \(String(format: "%.1f", bmi)) may impact your PT performance and height/weight standards. Consider a moderate calorie deficit combined with cardio.",
                        category: .weight,
                        priority: .high,
                        actionLabel: "Open Chow Log"
                    ), 90
                ))
            } else if bmiCategory == .underweight {
                all.append((
                    AIRecommendation(
                        headline: "BMI suggests room to add lean mass",
                        detail: "A BMI of \(String(format: "%.1f", bmi)) is below normal. Focus on strength training and a modest calorie surplus to support muscle gain.",
                        category: .strength,
                        priority: .medium,
                        actionLabel: nil
                    ), 60
                ))
            }
        }

        // ── Weight trend ─────────────────────────────────────
        if weightHistory.count >= 3 {
            let recent = weightHistory.prefix(3).map { $0.weightKg }
            let trend = recent[0] - recent[2]
            if let profile, let goal = profile.goalWeightKg {
                if profile.fitnessGoal == .loseFat && trend > 0.5 {
                    all.append((
                        AIRecommendation(
                            headline: "Weight trending up — review your intake",
                            detail: "Your goal is fat loss but weight has increased recently. Log your meals consistently and check your net calories.",
                            category: .nutrition,
                            priority: .high,
                            actionLabel: "Open Chow Log"
                        ), 85
                    ))
                } else if profile.fitnessGoal == .loseFat && trend < -0.3 && profile.weightKg <= goal + 1 {
                    all.append((
                        AIRecommendation(
                            headline: "Approaching your goal weight — great work",
                            detail: "You're within \(String(format: "%.1f", profile.weightKg - goal)) lbs of your goal. Consider shifting to a maintenance or body recomposition focus.",
                            category: .weight,
                            priority: .medium,
                            actionLabel: nil
                        ), 50
                    ))
                }
            }
        }

        // ── PT Score proximity ────────────────────────────────
        if let record = ptRecord, let config = ptConfig {
            let score = record.totalScore
            let passing = config.passingScore
            if !record.passed {
                all.append((
                    AIRecommendation(
                        headline: "PT score is below passing standard",
                        detail: "Your \(config.testName) score of \(score) is below the \(passing) minimum. Prioritize targeted event training 4–5 days per week.",
                        category: .ptScore,
                        priority: .high,
                        actionLabel: "Open Fitness"
                    ), 95
                ))
            } else {
                // Find next tier
                let nextTier = config.tiers.filter { $0.minScore > score }.min(by: { $0.minScore < $1.minScore })
                if let next = nextTier {
                    let gap = next.minScore - score
                    if gap <= 30 {
                        all.append((
                            AIRecommendation(
                                headline: "Only \(gap) points from \(next.name) tier",
                                detail: "Push targeted event training to close the gap. Focus on your lowest-scoring event first.",
                                category: .ptScore,
                                priority: .medium,
                                actionLabel: "Log PT Score"
                            ), 75
                        ))
                    }
                }

                // Check if score can contribute to promotion points (Army)
                if branch == .army && score >= 450 {
                    all.append((
                        AIRecommendation(
                            headline: "Top-tier AFT performance earns max promotion points",
                            detail: "Sustaining a 450+ AFT score keeps you in the highest Army fitness band for promotion points.",
                            category: .ptScore,
                            priority: .low,
                            actionLabel: "View Promotions"
                        ), 40
                    ))
                }
            }

            // Event-specific weak links
            let weakEvents = findWeakEvents(record: record, config: config)
            if let weakest = weakEvents.first {
                all.append((
                    AIRecommendation(
                        headline: "Focus on \(weakest) to boost your score",
                        detail: "This event appears to be your lowest scorer. Targeted training 3x/week can improve it significantly.",
                        category: .strength,
                        priority: .medium,
                        actionLabel: nil
                    ), 70
                ))
            }
        }

        // ── Activity / cardio ─────────────────────────────────
        if let activity = activityLog {
            if activity.steps < 5000 {
                all.append((
                    AIRecommendation(
                        headline: "Low step count today",
                        detail: "You've logged \(activity.steps) steps. Aim for 8,000–10,000 daily steps to support cardiovascular fitness and PT run performance.",
                        category: .cardio,
                        priority: .medium,
                        actionLabel: nil
                    ), 55
                ))
            }
            if activity.activeMinutes < 30 {
                all.append((
                    AIRecommendation(
                        headline: "Below 30 active minutes today",
                        detail: "Current guidelines recommend at least 30 minutes of moderate activity daily. A short run or circuit session can close this gap.",
                        category: .cardio,
                        priority: .medium,
                        actionLabel: "Log Workout"
                    ), 60
                ))
            }
        }

        // ── Calorie + goal alignment ──────────────────────────
        if let profile = profile, caloriesIn > 0 {
            let target = profile.dailyCalorieTarget ?? estimatedMaintenance(profile: profile)
            let diff = caloriesIn - target

            switch profile.fitnessGoal {
            case .loseFat:
                if diff > 300 {
                    all.append((
                        AIRecommendation(
                            headline: "In a calorie surplus — adjust intake",
                            detail: "You've consumed \(diff) calories above target today. For fat loss, aim for a 300–500 calorie deficit consistently.",
                            category: .nutrition,
                            priority: .high,
                            actionLabel: "Open Chow Log"
                        ), 80
                    ))
                }
            case .buildMuscle:
                if diff < -200 {
                    all.append((
                        AIRecommendation(
                            headline: "Below calorie target for muscle gain",
                            detail: "Building muscle requires a slight surplus. You're \(abs(diff)) calories under target — add a protein-rich meal or snack.",
                            category: .nutrition,
                            priority: .medium,
                            actionLabel: "Open Chow Log"
                        ), 65
                    ))
                }
            default:
                break
            }
        }

        // ── Goal-specific cardio ──────────────────────────────
        if let profile {
            switch profile.fitnessGoal {
            case .loseFat:
                if (activityLog?.activeCalories ?? 0) < 200 {
                    all.append((
                        AIRecommendation(
                            headline: "Add cardio to accelerate fat loss",
                            detail: "For fat loss, 3–5 cardio sessions per week (30+ minutes each) significantly accelerates results. Consider a run or HIIT circuit today.",
                            category: .cardio,
                            priority: .medium,
                            actionLabel: nil
                        ), 58
                    ))
                }
            case .improvePTScore:
                all.append((
                    AIRecommendation(
                        headline: "Run training 3x/week improves PT run times",
                        detail: "Interval training (e.g., 400m repeats) is the most efficient way to improve your timed run. Add one speed session, one tempo run, and one long easy run per week.",
                        category: .cardio,
                        priority: .medium,
                        actionLabel: nil
                    ), 55
                ))
            default:
                break
            }
        }

        // Sort by priority score, take top 3
        let sorted = all.sorted { $0.score > $1.score }.prefix(3)
        return sorted.map { $0.rec }
    }

    // MARK: - Weak Event Finder
    private static func findWeakEvents(record: PTScoreRecord, config: BranchPTConfig) -> [String] {
        // Identify events with below-average contribution
        var scored: [(name: String, score: Int)] = []
        for event in config.events {
            let raw = record.eventScores[event.name] ?? 0
            let pts = event.score(for: raw)
            if pts < (event.pointsMax / 2) {
                scored.append((event.name, pts))
            }
        }

        return scored.sorted { $0.score < $1.score }.map { $0.name }
    }

    // MARK: - Calorie Estimation (Mifflin-St Jeor, sedentary baseline)
    static func estimatedMaintenance(profile: FitnessProfile) -> Int {
        // Simplified estimate — always displayed as guidance only
        let bmr = 10 * profile.weightKg + 6.25 * profile.heightCm - 5 + 5  // male baseline
        let activityFactor = 1.55  // moderately active (military)
        return Int(bmr * activityFactor)
    }
}
