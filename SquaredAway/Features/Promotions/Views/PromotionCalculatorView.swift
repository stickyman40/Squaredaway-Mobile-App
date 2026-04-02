import SwiftUI

struct PromotionCalculatorView: View {
    @ObservedObject var vm: PromotionsViewModel
    @State private var appeared = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppTheme.Spacing.lg) {
                CalcScoreHeader(vm: vm)
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .opacity(appeared ? 1 : 0)

                Group {
                    switch vm.config.branch {
                    case .army:
                        ArmyCalcSection(vm: vm)
                    case .airForce, .spaceForce:
                        WAPSCalcSection(vm: vm)
                    case .navy:
                        NavyCalcSection(vm: vm)
                    case .marines:
                        MarineCalcSection(vm: vm)
                    case .coastGuard:
                        CGCalcSection(vm: vm)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .opacity(appeared ? 1 : 0)

                CutoffInputCard(vm: vm)
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .opacity(appeared ? 1 : 0)

                TimeInServiceCard(vm: vm)
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .opacity(appeared ? 1 : 0)

                if vm.isBoardSelected {
                    BoardDateCard(vm: vm)
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .opacity(appeared ? 1 : 0)
                }

                if let errorMessage = vm.errorMessage {
                    StatusBanner(message: errorMessage, color: AppTheme.Colors.error, icon: "exclamationmark.triangle.fill")
                        .padding(.horizontal, AppTheme.Spacing.md)
                }

                PrimaryButton("Save My Scores", isLoading: vm.isSaving) {
                    Task { await vm.save() }
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .opacity(appeared ? 1 : 0)

                if vm.saveSuccess {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppTheme.Colors.success)
                        Text("Saved!")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.success)
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }

                Spacer(minLength: AppTheme.Spacing.xxl)
            }
            .padding(.top, AppTheme.Spacing.md)
        }
        .onAppear {
            withAnimation(AppTheme.Animation.standard.delay(0.1)) {
                appeared = true
            }
        }
    }
}

private struct CalcScoreHeader: View {
    @ObservedObject var vm: PromotionsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Calculator")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textTertiary)

                    Text(vm.config.systemName)
                        .font(AppTheme.Typography.titleSmall)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .lineLimit(2)
                }

                Spacer()

                Image("SquaredAway Calculator")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 52, height: 52)
                    .padding(8)
                    .background(Color(hex: vm.config.accentHex).opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous))
            }

            HStack(spacing: AppTheme.Spacing.xl) {
                PromotionScoreRing(score: vm.totalScore, maxScore: vm.maxScore, accentHex: vm.config.accentHex, size: 80, lineWidth: 8)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Your Score")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textTertiary)

                    Text("\(vm.totalScore)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .animation(AppTheme.Animation.standard, value: vm.totalScore)

                    if !vm.isBoardSelected, let cutoff = vm.cutoffScore {
                        let gap = cutoff - vm.totalScore
                        Text(gap > 0 ? "\(gap) pts to \(vm.cutoffLabel) (\(cutoff))" : "Above \(vm.cutoffLabel) (\(cutoff))")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(gap > 0 ? AppTheme.Colors.warning : AppTheme.Colors.success)
                    } else if vm.isBoardSelected {
                        Text("Board-selected rank with no point threshold")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    } else {
                        Text("Enter your \(vm.cutoffLabel.lowercased()) below")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                }

                Spacer()
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.backgroundCard)
        .cornerRadius(AppTheme.Radius.xl)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                .stroke(AppTheme.Colors.glassBorder, lineWidth: 1)
        )
    }
}

private struct ArmyCalcSection: View {
    @ObservedObject var vm: PromotionsViewModel

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            PromoSectionHeader(title: "Army Promotion Points", subtitle: "AR 600-8-19")

            Text("Army Fitness Test (AFT) uses a 500-point scale with deadlift, hand-release push-up, sprint-drag-carry, plank, and the 2-mile run. Enter the promotion points awarded from your current AFT result.")
                .font(.system(size: 11))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppTheme.Spacing.xs)

            CalcSlider(label: "Military Education", hint: "PME, functional schools, and related military education", value: Binding(get: { Double(vm.record.armyMilEdPts ?? 0) }, set: { vm.record.armyMilEdPts = Int($0) }), range: 0...220, color: "#45B7D1", icon: "graduationcap.fill", current: vm.record.armyMilEdPts ?? 0, maximum: 220)
            CivEdPicker(vm: vm)
            CalcSlider(label: "Awards", hint: "Approved awards reflected in your record", value: Binding(get: { Double(vm.record.armyAwardsPts ?? 0) }, set: { vm.record.armyAwardsPts = Int($0) }), range: 0...125, color: "#FFD700", icon: "rosette", current: vm.record.armyAwardsPts ?? 0, maximum: 125)
            CalcSlider(label: "Military Training", hint: "ASI, DLPT, and military training-related points", value: Binding(get: { Double(vm.record.armyMilTrgPts ?? 0) }, set: { vm.record.armyMilTrgPts = Int($0) }), range: 0...100, color: "#A29BFE", icon: "wrench.and.screwdriver.fill", current: vm.record.armyMilTrgPts ?? 0, maximum: 100)
            AFTPointsPicker(vm: vm)
            WeaponsQualPicker(vm: vm)

            CalcTextField(label: "Your MOS", placeholder: "e.g. 11B, 68W, 25U", icon: "tag.fill") {
                TextField("MOS", text: Binding(get: { vm.record.armyMos ?? "" }, set: { vm.record.armyMos = $0.isEmpty ? nil : $0 }))
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }
        }
    }
}

private struct CivEdPicker: View {
    @ObservedObject var vm: PromotionsViewModel
    private let options: [(String, Int)] = [("None", 0), ("Associate", 40), ("Bachelor's", 75), ("Master's", 100)]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Civilian Education", systemImage: "building.columns.fill")
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Colors.textSecondary)

            HStack(spacing: 6) {
                ForEach(options, id: \.0) { label, points in
                    let isSelected = vm.record.armyCivEdPts == points
                    Button {
                        vm.record.armyCivEdPts = points
                    } label: {
                        VStack(spacing: 2) {
                            Text(label)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(isSelected ? .white : AppTheme.Colors.textSecondary)
                            Text("+\(points)")
                                .font(.system(size: 9))
                                .foregroundColor(isSelected ? .white.opacity(0.75) : AppTheme.Colors.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(isSelected ? Color(hex: "#96CEB4") : AppTheme.Colors.backgroundElevated)
                        .cornerRadius(AppTheme.Radius.sm)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.backgroundCard)
        .cornerRadius(AppTheme.Radius.lg)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.lg).stroke(AppTheme.Colors.glassBorder, lineWidth: 1))
    }
}

private struct AFTPointsPicker: View {
    @ObservedObject var vm: PromotionsViewModel
    private let tiers: [Int] = [0, 20, 25, 35, 45, 55, 60]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("AFT Promotion Points", systemImage: "figure.run")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                Spacer()
                Text("\(vm.record.armyAftPts ?? 0) / 60 pts")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "#FF6B6B"))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(tiers, id: \.self) { tier in
                        let isSelected = vm.record.armyAftPts == tier
                        Button {
                            vm.record.armyAftPts = tier
                        } label: {
                            VStack(spacing: 2) {
                                Text("\(tier)")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(isSelected ? .white : AppTheme.Colors.textPrimary)
                                Text(tier == 0 ? "None" : "Points")
                                    .font(.system(size: 9))
                                    .foregroundColor(isSelected ? .white.opacity(0.75) : AppTheme.Colors.textTertiary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(isSelected ? Color(hex: "#FF6B6B") : AppTheme.Colors.backgroundElevated)
                            .cornerRadius(AppTheme.Radius.md)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Text("Use the official AFT-to-promotion-points value from your latest Army guidance.")
                .font(.system(size: 9))
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.backgroundCard)
        .cornerRadius(AppTheme.Radius.lg)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.lg).stroke(AppTheme.Colors.glassBorder, lineWidth: 1))
    }
}

private struct WeaponsQualPicker: View {
    @ObservedObject var vm: PromotionsViewModel
    private let options = [("Expert", 20), ("Sharpshooter", 14), ("Marksman", 10), ("None", 0)]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Weapons Qualification", systemImage: "scope")
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Colors.textSecondary)

            HStack(spacing: 6) {
                ForEach(options, id: \.0) { label, points in
                    let isSelected = vm.record.armyWeaponsPts == points
                    Button {
                        vm.record.armyWeaponsPts = points
                    } label: {
                        VStack(spacing: 2) {
                            Text(label)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(isSelected ? .white : AppTheme.Colors.textSecondary)
                            Text("+\(points)")
                                .font(.system(size: 9))
                                .foregroundColor(isSelected ? .white.opacity(0.75) : AppTheme.Colors.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(isSelected ? Color(hex: "#FF9F0A") : AppTheme.Colors.backgroundElevated)
                        .cornerRadius(AppTheme.Radius.sm)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.backgroundCard)
        .cornerRadius(AppTheme.Radius.lg)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.lg).stroke(AppTheme.Colors.glassBorder, lineWidth: 1))
    }
}

private struct WAPSCalcSection: View {
    @ObservedObject var vm: PromotionsViewModel

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            PromoSectionHeader(title: "WAPS Inputs", subtitle: vm.selectedTargetRank?.payGrade ?? "E-5")

            let factor = (vm.selectedTargetRank?.payGrade == "E-7" || vm.selectedTargetRank?.payGrade == "E-8") ? 2.0 : 1.5

            CalcSlider(label: "SKT Raw Score", hint: "Weighted at x\(String(format: "%.1f", factor)) for this grade", value: Binding(get: { Double(vm.record.wapsSktRaw ?? 0) }, set: { vm.record.wapsSktRaw = Int($0) }), range: 0...100, color: "#45B7D1", icon: "doc.text.magnifyingglass", current: vm.record.wapsSktRaw ?? 0, maximum: 100)
            CalcSlider(label: "PFE Raw Score", hint: "Use the official study material and bibliography", value: Binding(get: { Double(vm.record.wapsPfeRaw ?? 0) }, set: { vm.record.wapsPfeRaw = Int($0) }), range: 0...100, color: "#A29BFE", icon: "book.fill", current: vm.record.wapsPfeRaw ?? 0, maximum: 100)
            EPRRatingPicker(vm: vm)
            CalcSlider(label: "Decorations Points", hint: "Officially credited decorations only", value: Binding(get: { Double(vm.record.wapsDecorationsPts ?? 0) }, set: { vm.record.wapsDecorationsPts = Int($0) }), range: 0...25, color: "#FFD700", icon: "rosette", current: vm.record.wapsDecorationsPts ?? 0, maximum: 25)
            CalcSlider(label: "AFADCONS Points", hint: "Volunteer, off-duty education, and professional activity", value: Binding(get: { Double(vm.record.wapsAfadconsPts ?? 0) }, set: { vm.record.wapsAfadconsPts = Int($0) }), range: 0...25, color: "#96CEB4", icon: "person.2.fill", current: vm.record.wapsAfadconsPts ?? 0, maximum: 25)

            HStack(spacing: AppTheme.Spacing.sm) {
                NumericStepperCard(label: "Years TIS", value: Binding(get: { vm.record.wapsTisYears ?? 0 }, set: { vm.record.wapsTisYears = $0 }), min: 0, max: 30, color: "#4ECDC4")
                NumericStepperCard(label: "Months TIG", value: Binding(get: { vm.record.wapsTigMonths ?? 0 }, set: { vm.record.wapsTigMonths = $0 }), min: 0, max: 120, color: "#4ECDC4")
            }
        }
    }
}

private struct EPRRatingPicker: View {
    @ObservedObject var vm: PromotionsViewModel

    var body: some View {
        let ratings = [5, 4, 3, 2, 1]
        let grade = vm.selectedTargetRank?.payGrade ?? "E-5"

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("EPR Rating", systemImage: "star.fill")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                Spacer()
                Text("\(WAPSPoints.eprPts(vm.record.wapsEprRating ?? 0, grade: grade)) pts")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "#FFD700"))
            }

            HStack(spacing: 6) {
                ForEach(ratings, id: \.self) { rating in
                    let points = WAPSPoints.eprPts(rating, grade: grade)
                    let isSelected = vm.record.wapsEprRating == rating
                    Button {
                        vm.record.wapsEprRating = rating
                    } label: {
                        VStack(spacing: 2) {
                            Text("\(rating)")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(isSelected ? .white : AppTheme.Colors.textPrimary)
                            Text("\(points)")
                                .font(.system(size: 9))
                                .foregroundColor(isSelected ? .white.opacity(0.75) : AppTheme.Colors.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(isSelected ? Color(hex: "#FFD700") : AppTheme.Colors.backgroundElevated)
                        .cornerRadius(AppTheme.Radius.sm)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.backgroundCard)
        .cornerRadius(AppTheme.Radius.lg)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.lg).stroke(AppTheme.Colors.glassBorder, lineWidth: 1))
    }
}

private struct NavyCalcSection: View {
    @ObservedObject var vm: PromotionsViewModel

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            PromoSectionHeader(title: "Navy FMS Inputs", subtitle: "MILPERSMAN 1430-010")

            PMASlider(vm: vm)
            CalcSlider(label: "Advancement Exam", hint: "Raw exam score", value: Binding(get: { Double(vm.record.navyExamRaw ?? 0) }, set: { vm.record.navyExamRaw = Int($0) }), range: 0...80, color: "#45B7D1", icon: "doc.text.fill", current: vm.record.navyExamRaw ?? 0, maximum: 80)
            CalcSlider(label: "Awards Points", hint: "Only credited awards count", value: Binding(get: { Double(vm.record.navyAwardsPts ?? 0) }, set: { vm.record.navyAwardsPts = Int($0) }), range: 0...15, color: "#FFD700", icon: "rosette", current: vm.record.navyAwardsPts ?? 0, maximum: 15)

            HStack(spacing: AppTheme.Spacing.sm) {
                NumericDecimalCard(label: "Years in Grade", value: Binding(get: { vm.record.navySipgYears ?? 0 }, set: { vm.record.navySipgYears = $0 }), hint: "SIPG bonus", color: "#96CEB4")
                PNAAttemptsPicker(vm: vm)
            }
        }
    }
}

private struct PMASlider: View {
    @ObservedObject var vm: PromotionsViewModel

    var body: some View {
        let pma = vm.record.navyPma ?? 1.0
        let points = NavyFMS.pmaPoints(pma)

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("PMA", systemImage: "star.fill")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                Spacer()
                Text(String(format: "%.2f -> %.0f pts", pma, points))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: "#FFD700"))
            }

            Slider(value: Binding(get: { pma }, set: { vm.record.navyPma = $0 }), in: 1.0...5.0, step: 0.01)
                .tint(Color(hex: "#FFD700"))

            Text("Formula: ((PMA x 10) - 10) x 2")
                .font(.system(size: 9))
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.backgroundCard)
        .cornerRadius(AppTheme.Radius.lg)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.lg).stroke(AppTheme.Colors.glassBorder, lineWidth: 1))
    }
}

private struct PNAAttemptsPicker: View {
    @ObservedObject var vm: PromotionsViewModel

    var body: some View {
        VStack(spacing: 4) {
            Text("PNA Attempts")
                .font(.system(size: 10))
                .foregroundColor(AppTheme.Colors.textTertiary)

            HStack(spacing: 4) {
                ForEach(0...3, id: \.self) { count in
                    Button {
                        vm.record.navyPnaAttempts = count
                    } label: {
                        Text("\(count)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(vm.record.navyPnaAttempts == count ? .white : AppTheme.Colors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(vm.record.navyPnaAttempts == count ? Color(hex: "#A29BFE") : AppTheme.Colors.backgroundElevated)
                            .cornerRadius(AppTheme.Radius.sm)
                    }
                    .buttonStyle(.plain)
                }
            }

            Text("+\(String(format: "%.1f", NavyFMS.pnaPts(vm.record.navyPnaAttempts ?? 0))) pts")
                .font(.system(size: 9))
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.sm)
        .background(AppTheme.Colors.backgroundCard)
        .cornerRadius(AppTheme.Radius.lg)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.lg).stroke(AppTheme.Colors.glassBorder, lineWidth: 1))
    }
}

private struct MarineCalcSection: View {
    @ObservedObject var vm: PromotionsViewModel

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            PromoSectionHeader(title: "Marine Composite Inputs", subtitle: "MCO P1400.32D")

            MarineMarkSlider(label: "PRO Mark", value: Binding(get: { vm.record.marineProMark ?? 4.0 }, set: { vm.record.marineProMark = $0 }), points: MarineComposite.proPts(vm.record.marineProMark ?? 0), color: "#CC0000")
            MarineMarkSlider(label: "CON Mark", value: Binding(get: { vm.record.marineConMark ?? 4.0 }, set: { vm.record.marineConMark = $0 }), points: MarineComposite.conPts(vm.record.marineConMark ?? 0), color: "#FF6B6B")
            CalcSlider(label: "PFT Score", hint: "Scaled from raw 0-300 to composite points", value: Binding(get: { Double(vm.record.marinePftRaw ?? 0) }, set: { vm.record.marinePftRaw = Int($0) }), range: 0...300, color: "#FF9F0A", icon: "figure.run", current: vm.record.marinePftRaw ?? 0, maximum: 300)
            CalcSlider(label: "CFT Score", hint: "Scaled from raw 0-300 to composite points", value: Binding(get: { Double(vm.record.marineCftRaw ?? 0) }, set: { vm.record.marineCftRaw = Int($0) }), range: 0...300, color: "#FFD700", icon: "figure.walk", current: vm.record.marineCftRaw ?? 0, maximum: 300)
            MarineRifleQualPicker(vm: vm)
            CalcSlider(label: "MCI Credits", hint: "Credits earned, max 100 points", value: Binding(get: { Double(min(100, vm.record.marineMciCredits ?? 0)) }, set: { vm.record.marineMciCredits = Int($0) }), range: 0...100, color: "#A29BFE", icon: "graduationcap.fill", current: min(100, vm.record.marineMciCredits ?? 0), maximum: 100)
        }
    }
}

private struct MarineMarkSlider: View {
    let label: String
    @Binding var value: Double
    let points: Int
    let color: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                Spacer()
                Text(String(format: "%.1f -> %d pts", value, points))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: color))
            }

            Slider(value: $value, in: 1.0...5.0, step: 0.1)
                .tint(Color(hex: color))
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.backgroundCard)
        .cornerRadius(AppTheme.Radius.lg)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.lg).stroke(AppTheme.Colors.glassBorder, lineWidth: 1))
    }
}

private struct MarineRifleQualPicker: View {
    @ObservedObject var vm: PromotionsViewModel
    private let options = [("Expert", 50), ("Sharpshooter", 40), ("Marksman", 30), ("Unqual", 0)]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Rifle Qualification", systemImage: "scope")
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Colors.textSecondary)

            HStack(spacing: 6) {
                ForEach(options, id: \.0) { label, points in
                    let isSelected = vm.record.marineRifleQual == points
                    Button {
                        vm.record.marineRifleQual = points
                    } label: {
                        VStack(spacing: 2) {
                            Text(label)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(isSelected ? .white : AppTheme.Colors.textSecondary)
                            Text("\(points) pts")
                                .font(.system(size: 9))
                                .foregroundColor(isSelected ? .white.opacity(0.75) : AppTheme.Colors.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(isSelected ? Color(hex: "#45B7D1") : AppTheme.Colors.backgroundElevated)
                        .cornerRadius(AppTheme.Radius.sm)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.backgroundCard)
        .cornerRadius(AppTheme.Radius.lg)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.lg).stroke(AppTheme.Colors.glassBorder, lineWidth: 1))
    }
}

private struct CGCalcSection: View {
    @ObservedObject var vm: PromotionsViewModel

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            PromoSectionHeader(title: "Coast Guard SWE Inputs", subtitle: "COMDTINST M1000.2C")

            CalcSlider(label: "SWE Raw Score", hint: "Use the official bibliography and rate-specific materials", value: Binding(get: { Double(vm.record.cgSweRaw ?? 0) }, set: { vm.record.cgSweRaw = Int($0) }), range: 0...100, color: "#003087", icon: "doc.text.fill", current: vm.record.cgSweRaw ?? 0, maximum: 100)
            CGPerfFactorSlider(vm: vm)
        }
    }
}

private struct CGPerfFactorSlider: View {
    @ObservedObject var vm: PromotionsViewModel

    var body: some View {
        let factor = vm.record.cgPerfFactor ?? 1.0
        let points = CGSWE.perfFactor(factor)

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Performance Factor", systemImage: "star.fill")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                Spacer()
                Text(String(format: "%.1f -> %.0f pts", factor, points))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: "#45B7D1"))
            }

            Slider(value: Binding(get: { factor }, set: { vm.record.cgPerfFactor = $0 }), in: 1.0...7.0, step: 0.1)
                .tint(Color(hex: "#45B7D1"))
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.backgroundCard)
        .cornerRadius(AppTheme.Radius.lg)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.lg).stroke(AppTheme.Colors.glassBorder, lineWidth: 1))
    }
}

private struct CalcSlider: View {
    let label: String
    let hint: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let color: String
    let icon: String
    let current: Int
    let maximum: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: color))
                    .frame(width: 22, height: 22)
                    .background(Color(hex: color).opacity(0.12))
                    .cornerRadius(4)

                Text(label)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)

                Spacer()

                Text("\(current) / \(maximum)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: color))
            }

            Slider(value: $value, in: range, step: 1)
                .tint(Color(hex: color))

            Text(hint)
                .font(.system(size: 9))
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.backgroundCard)
        .cornerRadius(AppTheme.Radius.lg)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.lg).stroke(AppTheme.Colors.glassBorder, lineWidth: 1))
    }
}

private struct CutoffInputCard: View {
    @ObservedObject var vm: PromotionsViewModel

    var body: some View {
        guard !vm.isBoardSelected else { return AnyView(EmptyView()) }
        return AnyView(
            CalcTextField(label: "\(vm.cutoffLabel)", placeholder: "e.g. 498", icon: "chart.bar.fill") {
                TextField("0", text: Binding(
                    get: {
                        switch vm.config.branch {
                        case .army:
                            return vm.record.armyMosCutoff.map(String.init) ?? ""
                        case .airForce, .spaceForce:
                            return vm.record.wapsCutoffPublished.map(String.init) ?? ""
                        case .navy:
                            return ""
                        case .marines:
                            return vm.record.marineCutScore.map(String.init) ?? ""
                        case .coastGuard:
                            return vm.record.cgCutScore.map(String.init) ?? ""
                        }
                    },
                    set: { value in
                        let number = Int(value)
                        switch vm.config.branch {
                        case .army:
                            vm.record.armyMosCutoff = number
                        case .airForce, .spaceForce:
                            vm.record.wapsCutoffPublished = number
                        case .navy:
                            break
                        case .marines:
                            vm.record.marineCutScore = number
                        case .coastGuard:
                            vm.record.cgCutScore = number
                        }
                    }
                ))
                .keyboardType(.numberPad)
                .foregroundColor(AppTheme.Colors.textPrimary)
            }
        )
    }
}

private struct TimeInServiceCard: View {
    @ObservedObject var vm: PromotionsViewModel

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            NumericStepperCard(label: "Months in Service (TIS)", value: $vm.record.monthsInService, min: 0, max: 360, color: "#4ECDC4")
            NumericStepperCard(label: "Months in Grade (TIG)", value: $vm.record.monthsInGrade, min: 0, max: 120, color: "#4ECDC4")
        }
    }
}

private struct BoardDateCard: View {
    @ObservedObject var vm: PromotionsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Next Board Date", systemImage: "calendar")
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Colors.textSecondary)

            DatePicker("", selection: Binding(get: { vm.record.nextBoardDate ?? Date().addingTimeInterval(90 * 86_400) }, set: { vm.record.nextBoardDate = $0 }), displayedComponents: .date)

            TextEditor(text: Binding(get: { vm.record.boardNotes ?? "" }, set: { vm.record.boardNotes = $0.isEmpty ? nil : $0 }))
                .scrollContentBackground(.hidden)
                .frame(minHeight: 96)
                .padding(AppTheme.Spacing.sm)
                .background(AppTheme.Colors.backgroundElevated)
                .cornerRadius(AppTheme.Radius.sm)
                .foregroundColor(AppTheme.Colors.textPrimary)
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.backgroundCard)
        .cornerRadius(AppTheme.Radius.lg)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.lg).stroke(AppTheme.Colors.glassBorder, lineWidth: 1))
    }
}

struct NumericStepperCard: View {
    let label: String
    @Binding var value: Int
    let min: Int
    let max: Int
    let color: String

    var body: some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(AppTheme.Colors.textTertiary)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            HStack(spacing: 8) {
                Button {
                    if value > min { value -= 1 }
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 12, weight: .bold))
                        .frame(width: 28, height: 28)
                        .background(AppTheme.Colors.backgroundElevated)
                        .cornerRadius(6)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                .buttonStyle(.plain)

                Text("\(value)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .frame(minWidth: 32)

                Button {
                    if value < max { value += 1 }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                        .frame(width: 28, height: 28)
                        .background(Color(hex: color).opacity(0.15))
                        .cornerRadius(6)
                        .foregroundColor(Color(hex: color))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.sm)
        .background(AppTheme.Colors.backgroundCard)
        .cornerRadius(AppTheme.Radius.lg)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.lg).stroke(AppTheme.Colors.glassBorder, lineWidth: 1))
    }
}

private struct NumericDecimalCard: View {
    let label: String
    @Binding var value: Double
    let hint: String
    let color: String

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(AppTheme.Colors.textTertiary)
                .multilineTextAlignment(.center)

            TextField("0.0", text: Binding(get: { String(format: "%.1f", value) }, set: { value = Double($0) ?? 0 }))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.Colors.textPrimary)
                .padding(AppTheme.Spacing.sm)
                .background(AppTheme.Colors.backgroundElevated)
                .cornerRadius(6)

            Text(hint)
                .font(.system(size: 9))
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.sm)
        .background(AppTheme.Colors.backgroundCard)
        .cornerRadius(AppTheme.Radius.lg)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.lg).stroke(AppTheme.Colors.glassBorder, lineWidth: 1))
    }
}

struct CalcTextField<Field: View>: View {
    let label: String
    let placeholder: String
    let icon: String
    let field: () -> Field

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(AppTheme.Colors.textTertiary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.Colors.textTertiary)
                field()
            }

            Spacer()
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.backgroundCard)
        .cornerRadius(AppTheme.Radius.lg)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.lg).stroke(AppTheme.Colors.glassBorder, lineWidth: 1))
    }
}

private struct StatusBanner: View {
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
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.sm).stroke(color.opacity(0.24), lineWidth: 1))
        .cornerRadius(AppTheme.Radius.sm)
    }
}
