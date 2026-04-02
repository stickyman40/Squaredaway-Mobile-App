import SwiftUI

struct PromotionRoadmapView: View {
    @ObservedObject var vm: PromotionsViewModel
    @State private var appeared = false
    @State private var expandedRankID: String?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppTheme.Spacing.lg) {
                EligibilityTimelineCard(vm: vm)
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .opacity(appeared ? 1 : 0)

                VStack(spacing: 0) {
                    PromoSectionHeader(title: "Career Ladder", subtitle: "\(vm.config.branch.rawValue) enlisted progression")
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.bottom, AppTheme.Spacing.sm)

                    ForEach(Array(vm.config.ranks.enumerated()), id: \.element.id) { index, rank in
                        RankLadderRow(
                            rank: rank,
                            index: index,
                            isFirst: index == 0,
                            isLast: index == vm.config.ranks.count - 1,
                            isCurrent: rank.payGrade == vm.record.currentPayGrade,
                            isTarget: rank.id == vm.selectedTargetRank?.id,
                            isAchieved: gradeNumber(vm.record.currentPayGrade) > gradeNumber(rank.payGrade),
                            isExpanded: expandedRankID == rank.id,
                            accentHex: vm.config.accentHex,
                            monthsInService: vm.record.monthsInService,
                            monthsInGrade: vm.record.monthsInGrade
                        ) {
                            withAnimation(AppTheme.Animation.spring) {
                                expandedRankID = expandedRankID == rank.id ? nil : rank.id
                            }
                        }
                    }
                }
                .opacity(appeared ? 1 : 0)

                if let target = vm.selectedTargetRank {
                    TargetRankDetailCard(rank: target, vm: vm)
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .opacity(appeared ? 1 : 0)
                }

                Spacer(minLength: AppTheme.Spacing.xxl)
            }
            .padding(.top, AppTheme.Spacing.md)
        }
        .onAppear {
            withAnimation(AppTheme.Animation.standard.delay(0.1)) {
                appeared = true
            }
            expandedRankID = vm.selectedTargetRank?.id
        }
    }

    private func gradeNumber(_ grade: String) -> Int {
        Int(grade.dropFirst()) ?? 0
    }
}

private struct EligibilityTimelineCard: View {
    @ObservedObject var vm: PromotionsViewModel

    var body: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(spacing: AppTheme.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Promotion Readiness")
                            .font(AppTheme.Typography.titleSmall)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        if let rank = vm.selectedTargetRank {
                            Text("Target: \(rank.abbreviation.components(separatedBy: "/").first ?? rank.abbreviation) · \(rank.payGrade)")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.textTertiary)
                        }
                    }

                    Spacer()

                    ZStack {
                        Circle()
                            .stroke(AppTheme.Colors.glassBorder, lineWidth: 4)
                            .frame(width: 52, height: 52)
                        Circle()
                            .trim(from: 0, to: vm.promotionReadinessPercent)
                            .stroke(Color(hex: vm.config.accentHex), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .frame(width: 52, height: 52)
                            .rotationEffect(.degrees(-90))
                        Text("\(Int(vm.promotionReadinessPercent * 100))%")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                    }
                }

                Divider().background(AppTheme.Colors.glassBorder)

                HStack(spacing: AppTheme.Spacing.sm) {
                    ReadinessPillar(label: "Time in Service", current: vm.record.monthsInService, required: vm.selectedTargetRank?.minTISMonths ?? 0, color: vm.config.accentHex)
                    ReadinessPillar(label: "Time in Grade", current: vm.record.monthsInGrade, required: vm.selectedTargetRank?.minTIGMonths ?? 0, color: vm.config.accentHex)

                    if vm.isBoardSelected {
                        VStack(spacing: 4) {
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 18))
                                .foregroundColor(Color(hex: "#A29BFE"))
                            Text("Board")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                            Text("Selected")
                                .font(.system(size: 9))
                                .foregroundColor(AppTheme.Colors.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.sm)
                        .background(Color(hex: "#A29BFE").opacity(0.08))
                        .cornerRadius(AppTheme.Radius.md)
                    } else {
                        ReadinessPillar(label: "Score", current: vm.totalScore, required: vm.cutoffScore ?? vm.maxScore, color: vm.config.accentHex)
                    }
                }

                if vm.missingTISMonths > 0 || vm.missingTIGMonths > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.badge.exclamationmark")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.Colors.warning)

                        VStack(alignment: .leading, spacing: 2) {
                            if vm.missingTISMonths > 0 {
                                Text("Need \(vm.missingTISMonths) more months TIS")
                                    .font(AppTheme.Typography.caption)
                                    .foregroundColor(AppTheme.Colors.warning)
                            }
                            if vm.missingTIGMonths > 0 {
                                Text("Need \(vm.missingTIGMonths) more months TIG")
                                    .font(AppTheme.Typography.caption)
                                    .foregroundColor(AppTheme.Colors.warning)
                            }
                        }

                        Spacer()
                    }
                    .padding(AppTheme.Spacing.sm)
                    .background(AppTheme.Colors.warning.opacity(0.07))
                    .cornerRadius(AppTheme.Radius.sm)
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.Colors.success)
                        Text(vm.isBoardSelected ? "Time requirements met — focus on record quality." : "Time requirements met — now close the score gap.")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.success)
                        Spacer()
                    }
                    .padding(AppTheme.Spacing.sm)
                    .background(AppTheme.Colors.success.opacity(0.07))
                    .cornerRadius(AppTheme.Radius.sm)
                }
            }
        }
    }
}

private struct ReadinessPillar: View {
    let label: String
    let current: Int
    let required: Int
    let color: String

    private var progress: Double {
        guard required > 0 else { return 1 }
        return min(1.0, Double(current) / Double(required))
    }

    private var isMet: Bool {
        current >= required
    }

    var body: some View {
        VStack(spacing: 5) {
            ZStack {
                Circle()
                    .stroke(AppTheme.Colors.glassBorder, lineWidth: 3)
                    .frame(width: 40, height: 40)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(isMet ? AppTheme.Colors.success : Color(hex: color), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                    .animation(AppTheme.Animation.slow, value: progress)
                Image(systemName: isMet ? "checkmark" : "clock")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(isMet ? AppTheme.Colors.success : Color(hex: color))
            }

            Text("\(current)/\(required)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.Colors.textPrimary)

            Text(label)
                .font(.system(size: 9))
                .foregroundColor(AppTheme.Colors.textTertiary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background(isMet ? AppTheme.Colors.success.opacity(0.06) : Color(hex: color).opacity(0.06))
        .cornerRadius(AppTheme.Radius.md)
    }
}

private struct RankLadderRow: View {
    let rank: PromotionRank
    let index: Int
    let isFirst: Bool
    let isLast: Bool
    let isCurrent: Bool
    let isTarget: Bool
    let isAchieved: Bool
    let isExpanded: Bool
    let accentHex: String
    let monthsInService: Int
    let monthsInGrade: Int
    let onTap: () -> Void

    private var rowColor: Color {
        if isAchieved { return AppTheme.Colors.success }
        if isCurrent { return Color(hex: accentHex) }
        if isTarget { return Color(hex: "#FFD700") }
        return AppTheme.Colors.textTertiary.opacity(0.3)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(spacing: 0) {
                if !isFirst {
                    Rectangle()
                        .fill(isAchieved ? AppTheme.Colors.success.opacity(0.4) : AppTheme.Colors.glassBorder)
                        .frame(width: 2, height: 16)
                }

                ZStack {
                    Circle()
                        .fill(rowColor.opacity(isAchieved || isCurrent || isTarget ? 0.15 : 0.06))
                        .frame(width: 36, height: 36)

                    if isAchieved {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(AppTheme.Colors.success)
                    } else if isCurrent {
                        ZStack {
                            Circle()
                                .fill(Color(hex: accentHex))
                                .frame(width: 24, height: 24)
                            Text(rank.payGrade.dropFirst())
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                        }
                    } else {
                        Text(rank.payGrade.dropFirst())
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(isTarget ? Color(hex: "#FFD700") : AppTheme.Colors.textTertiary)
                    }
                }

                if !isLast {
                    Rectangle()
                        .fill(isAchieved ? AppTheme.Colors.success.opacity(0.4) : AppTheme.Colors.glassBorder)
                        .frame(width: 2)
                        .frame(minHeight: isExpanded ? 4 : 0)
                }
            }
            .frame(width: 52)
            .padding(.leading, AppTheme.Spacing.md)

            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Text(rank.payGrade)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(AppTheme.Colors.textTertiary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(rowColor.opacity(0.12))
                                    .cornerRadius(AppTheme.Radius.sm)

                                Text(rank.abbreviation)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(isCurrent || isTarget ? AppTheme.Colors.textPrimary : AppTheme.Colors.textSecondary)

                                if isCurrent {
                                    Text("CURRENT")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(Color(hex: accentHex))
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(Color(hex: accentHex).opacity(0.12))
                                        .cornerRadius(AppTheme.Radius.sm)
                                }

                                if isTarget {
                                    Text("TARGET")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(Color(hex: "#FFD700"))
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(Color(hex: "#FFD700").opacity(0.12))
                                        .cornerRadius(AppTheme.Radius.sm)
                                }
                            }

                            Text(rank.title)
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.textTertiary)
                        }

                        Spacer()

                        if rank.isBoardSelected {
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 11))
                                .foregroundColor(Color(hex: "#A29BFE"))
                        } else if let maxScore = rank.maxScore {
                            Text("\(maxScore) max")
                                .font(.system(size: 10))
                                .foregroundColor(AppTheme.Colors.textTertiary)
                        }

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                    .padding(.top, 8)

                    if isExpanded {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                            Divider()
                                .background(AppTheme.Colors.glassBorder)
                                .padding(.top, 8)

                            HStack(spacing: AppTheme.Spacing.sm) {
                                RequirementChip(label: "Min TIS", value: "\(rank.minTISMonths) mo", met: monthsInService >= rank.minTISMonths)
                                RequirementChip(label: "Min TIG", value: "\(rank.minTIGMonths) mo", met: monthsInGrade >= rank.minTIGMonths)
                                if rank.isBoardSelected {
                                    RequirementChip(label: "Method", value: "Board", met: nil)
                                } else if let maxScore = rank.maxScore {
                                    RequirementChip(label: "Max Score", value: "\(maxScore)", met: nil)
                                }
                            }

                            if !rank.notes.isEmpty {
                                HStack(alignment: .top, spacing: 6) {
                                    Image(systemName: "lightbulb.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(Color(hex: "#FFD700"))
                                    Text(rank.notes)
                                        .font(AppTheme.Typography.caption)
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                }
                                .padding(AppTheme.Spacing.sm)
                                .background(Color(hex: "#FFD700").opacity(0.05))
                                .cornerRadius(AppTheme.Radius.sm)
                            }
                        }
                        .padding(.bottom, 8)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.trailing, AppTheme.Spacing.md)
                .background((isCurrent || isTarget) ? rowColor.opacity(0.04) : .clear)
                .cornerRadius(AppTheme.Radius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                        .stroke((isCurrent || isTarget) ? rowColor.opacity(0.15) : .clear, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .padding(.trailing, AppTheme.Spacing.md)
            .padding(.vertical, 4)
        }
    }
}

private struct RequirementChip: View {
    let label: String
    let value: String
    let met: Bool?

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(met == true ? AppTheme.Colors.success : met == false ? AppTheme.Colors.warning : AppTheme.Colors.textPrimary)
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(met == true ? AppTheme.Colors.success.opacity(0.08) : met == false ? AppTheme.Colors.warning.opacity(0.08) : AppTheme.Colors.backgroundElevated)
        .cornerRadius(AppTheme.Radius.sm)
    }
}

private struct TargetRankDetailCard: View {
    let rank: PromotionRank
    @ObservedObject var vm: PromotionsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "#FFD700").opacity(0.12))
                        .frame(width: 44, height: 44)
                    Text(rank.payGrade)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: "#FFD700"))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(rank.abbreviation) — \(rank.title)")
                        .font(AppTheme.Typography.titleSmall)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    Text("Your target rank")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }

                Spacer()
            }

            Divider().background(AppTheme.Colors.glassBorder)

            VStack(alignment: .leading, spacing: 6) {
                Text("How you get promoted to \(rank.abbreviation.components(separatedBy: "/").first ?? rank.abbreviation):")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)

                if rank.isBoardSelected {
                    BoardSystemExplainer()
                } else {
                    PointsSystemExplainer(rank: rank, vm: vm)
                }
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(AppTheme.Colors.backgroundCard)
        .cornerRadius(AppTheme.Radius.xl)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.xl).stroke(Color(hex: "#FFD700").opacity(0.2), lineWidth: 1))
    }
}

private struct PointsSystemExplainer: View {
    let rank: PromotionRank
    @ObservedObject var vm: PromotionsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ExplainerRow(number: 1, color: vm.config.accentHex, text: "Meet minimum TIS (\(rank.minTISMonths) months) and TIG (\(rank.minTIGMonths) months)")
            ExplainerRow(number: 2, color: vm.config.accentHex, text: "Build your \(vm.config.systemName) score in the Calculator tab")
            ExplainerRow(number: 3, color: vm.config.accentHex, text: "Beat the current \(vm.cutoffLabel) for your career field or rate")
        }
        .padding(AppTheme.Spacing.sm)
        .background(Color(hex: vm.config.accentHex).opacity(0.05))
        .cornerRadius(AppTheme.Radius.sm)
    }
}

private struct BoardSystemExplainer: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ExplainerRow(number: 1, color: "#A29BFE", text: "Meet minimum time requirements and receive a recommendation")
            ExplainerRow(number: 2, color: "#A29BFE", text: "A centralized board reviews your whole service record")
            ExplainerRow(number: 3, color: "#A29BFE", text: "Evaluation trends, leadership, and professional development matter most")

            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(Color(hex: "#FFD700"))
                    .font(.system(size: 11))
                Text("Start preparing for board-selected ranks years in advance, not months.")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color(hex: "#FFD700"))
            }
        }
        .padding(AppTheme.Spacing.sm)
        .background(Color(hex: "#A29BFE").opacity(0.05))
        .cornerRadius(AppTheme.Radius.sm)
    }
}

private struct ExplainerRow: View {
    let number: Int
    let color: String
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "\(number).circle.fill")
                .foregroundColor(Color(hex: color))
                .font(.system(size: 13))
            Text(text)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
    }
}
