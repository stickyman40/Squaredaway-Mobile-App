import SwiftUI

struct FuelRatingBadge: View {
    let score: Int
    let rating: FuelRating
    var size: BadgeSize = .medium
    var showLabel = true

    enum BadgeSize {
        case small
        case medium
        case large

        var diameter: CGFloat {
            switch self {
            case .small: return 44
            case .medium: return 72
            case .large: return 110
            }
        }

        var lineWidth: CGFloat {
            switch self {
            case .small: return 4
            case .medium: return 7
            case .large: return 10
            }
        }

        var fontSize: CGFloat {
            switch self {
            case .small: return 14
            case .medium: return 22
            case .large: return 36
            }
        }
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            ZStack {
                Circle()
                    .fill(rating.glowColor)
                    .frame(width: size.diameter + 12, height: size.diameter + 12)
                    .blur(radius: 10)

                Circle()
                    .stroke(rating.color.opacity(0.2), lineWidth: size.lineWidth)
                    .frame(width: size.diameter, height: size.diameter)

                Circle()
                    .trim(from: 0, to: CGFloat(score) / 100)
                    .stroke(rating.color, style: StrokeStyle(lineWidth: size.lineWidth, lineCap: .round))
                    .frame(width: size.diameter, height: size.diameter)
                    .rotationEffect(.degrees(-90))
                    .animation(AppTheme.Animation.slow, value: score)

                Text("\(score)")
                    .font(.system(size: size.fontSize, weight: .bold, design: .rounded))
                    .foregroundColor(rating.color)
            }

            if showLabel {
                Text(rating.shortLabel.uppercased())
                    .font(AppTheme.Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(rating.color)
                    .tracking(1)
            }
        }
    }
}

struct FuelRatingPill: View {
    let rating: FuelRating

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: rating.icon)
                .font(.system(size: 10, weight: .semibold))
            Text(rating.shortLabel)
                .font(AppTheme.Typography.caption)
                .fontWeight(.semibold)
        }
        .foregroundColor(rating.color)
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, 3)
        .background(rating.bgColor)
        .cornerRadius(AppTheme.Radius.full)
        .overlay(Capsule().stroke(rating.color.opacity(0.3), lineWidth: 1))
    }
}

struct MacroProgressStrip: View {
    let calories: Double
    let calorieGoal: Int
    let protein: Double
    let proteinGoal: Int
    let carbs: Double
    let carbGoal: Int
    let fat: Double
    let fatGoal: Int

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            MacroCircle(label: "Cal", current: Int(calories), goal: calorieGoal, color: "#FF6B6B", unit: "")
            MacroCircle(label: "Pro", current: Int(protein), goal: proteinGoal, color: "#45B7D1", unit: "g")
            MacroCircle(label: "Carb", current: Int(carbs), goal: carbGoal, color: "#FFD700", unit: "g")
            MacroCircle(label: "Fat", current: Int(fat), goal: fatGoal, color: "#FF9F0A", unit: "g")
        }
    }
}

private struct MacroCircle: View {
    let label: String
    let current: Int
    let goal: Int
    let color: String
    let unit: String

    private var progress: Double {
        goal > 0 ? min(1.0, Double(current) / Double(goal)) : 0
    }

    private var overGoal: Bool {
        current > goal && goal > 0
    }

    var body: some View {
        VStack(spacing: 5) {
            ZStack {
                Circle()
                    .stroke(Color(hex: color).opacity(0.15), lineWidth: 4)
                    .frame(width: 52, height: 52)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(overGoal ? AppTheme.Colors.error : Color(hex: color), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 52, height: 52)
                    .rotationEffect(.degrees(-90))
                    .animation(AppTheme.Animation.slow, value: progress)

                VStack(spacing: 0) {
                    Text("\(current)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.system(size: 8))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                }
            }

            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.textTertiary)
            Text("/ \(goal)\(unit)")
                .font(.system(size: 9))
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ScoreFactorRow: View {
    let factor: ScoreFactor

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
            Image(systemName: factor.impact.icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(factor.impact.color)
                .frame(width: 22, height: 22)
                .background(factor.impact.color.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(factor.label)
                    .font(AppTheme.Typography.titleSmall)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Text(factor.detail)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }

            Spacer()
        }
        .padding(AppTheme.Spacing.sm)
        .background(factor.impact.color.opacity(0.04))
        .cornerRadius(AppTheme.Radius.md)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.md).stroke(factor.impact.color.opacity(0.12), lineWidth: 1))
    }
}

struct CompactNutritionRow: View {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double

    var body: some View {
        HStack(spacing: AppTheme.Spacing.lg) {
            NutrientPill(label: "Cal", value: Int(calories), color: "#FF6B6B")
            NutrientPill(label: "Pro", value: Int(protein), unit: "g", color: "#45B7D1")
            NutrientPill(label: "Carb", value: Int(carbs), unit: "g", color: "#FFD700")
            NutrientPill(label: "Fat", value: Int(fat), unit: "g", color: "#FF9F0A")
            Spacer()
        }
    }
}

private struct NutrientPill: View {
    let label: String
    let value: Int
    var unit = ""
    let color: String

    var body: some View {
        VStack(spacing: 1) {
            Text("\(value)\(unit)")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color(hex: color))
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
    }
}

struct ScanHistoryRow: View {
    let scan: FuelScan
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.Spacing.md) {
                RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                    .fill(AppTheme.Colors.backgroundElevated)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "barcode.viewfinder")
                            .foregroundColor(AppTheme.Colors.textTertiary)
                            .font(.system(size: 18))
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(scan.product?.name ?? "Barcode: \(scan.barcode)")
                        .font(AppTheme.Typography.titleSmall)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        Text(scan.scannedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textTertiary)
                        if scan.wasLogged {
                            Text("Logged")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.success)
                        }
                    }
                }

                Spacer()

                if let scores = scan.product?.scores {
                    FuelRatingPill(rating: scores.rating)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.Colors.backgroundCard)
            .cornerRadius(AppTheme.Radius.lg)
            .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.lg).stroke(AppTheme.Colors.glassBorder, lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ChowEntryRow: View {
    let entry: ChowEntry
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: entry.source == .scan ? "barcode.viewfinder" : "pencil.line")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(entry.source == .scan ? AppTheme.Colors.accentSecondary : AppTheme.Colors.textTertiary)
                .frame(width: 32, height: 32)
                .background(entry.source == .scan ? AppTheme.Colors.accentPrimary.opacity(0.12) : AppTheme.Colors.backgroundElevated)
                .cornerRadius(AppTheme.Radius.sm)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.displayName)
                        .font(AppTheme.Typography.titleSmall)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .lineLimit(1)

                    if entry.servings != 1 {
                        Text("x\(String(format: "%.1f", entry.servings))")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                }

                CompactNutritionRow(
                    calories: entry.totalCalories,
                    protein: entry.totalProtein,
                    carbs: entry.totalCarbs,
                    fat: entry.totalFat
                )
            }

            Spacer()

            if let rating = entry.fuelRating {
                FuelRatingPill(rating: rating)
            }

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .frame(width: 28, height: 28)
                    .background(AppTheme.Colors.backgroundElevated)
                    .cornerRadius(AppTheme.Radius.sm)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.backgroundCard)
        .cornerRadius(AppTheme.Radius.lg)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.lg).stroke(AppTheme.Colors.glassBorder, lineWidth: 1))
    }
}
