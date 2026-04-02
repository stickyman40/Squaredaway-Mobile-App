import SwiftUI

struct PromotionOverviewView: View {
    @ObservedObject var vm: PromotionsViewModel
    @State private var appeared = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppTheme.Spacing.lg) {
                ScoreHeroCard(vm: vm)
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .scaleEffect(appeared ? 1 : 0.96)
                    .opacity(appeared ? 1 : 0)

                EligibilityBanner(vm: vm)
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .opacity(appeared ? 1 : 0)

                VStack(spacing: AppTheme.Spacing.sm) {
                    PromoSectionHeader(title: "Score Breakdown", subtitle: "Edit values in Calculator")
                        .padding(.horizontal, AppTheme.Spacing.md)

                    ForEach(vm.activeComponents) { component in
                        ComponentBar(comp: component, accentHex: vm.config.accentHex)
                            .padding(.horizontal, AppTheme.Spacing.md)
                    }
                }
                .opacity(appeared ? 1 : 0)

                SystemInfoCard(vm: vm)
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .opacity(appeared ? 1 : 0)

                ResourcesCard(vm: vm)
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .opacity(appeared ? 1 : 0)

                Text("For self-tracking only. Verify cutoff scores, cycle details, and eligibility with official publications and your chain.")
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.Spacing.xl)

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

private struct ScoreHeroCard: View {
    @ObservedObject var vm: PromotionsViewModel

    var body: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(spacing: AppTheme.Spacing.lg) {
                RankChipRow(vm: vm)

                HStack(spacing: AppTheme.Spacing.xl) {
                    PromotionScoreRing(
                        score: vm.totalScore,
                        maxScore: vm.maxScore,
                        accentHex: vm.config.accentHex,
                        size: 110,
                        lineWidth: 11
                    )

                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text(vm.config.systemName)
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textTertiary)
                            .lineLimit(2)

                        HStack(spacing: 6) {
                            Circle()
                                .fill(vm.statusColor)
                                .frame(width: 7, height: 7)
                            Text(vm.statusLabel)
                                .font(AppTheme.Typography.titleSmall)
                                .foregroundColor(vm.statusColor)
                        }

                        if let cutoff = vm.cutoffScore {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(vm.cutoffLabel): \(cutoff)")
                                    .font(AppTheme.Typography.caption)
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                let gap = cutoff - vm.totalScore
                                Text(gap > 0 ? "\(gap) pts to go" : "Above cutoff")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(gap > 0 ? AppTheme.Colors.warning : AppTheme.Colors.success)
                            }
                        }

                        if vm.isBoardSelected {
                            HStack(spacing: 4) {
                                Image(systemName: "person.3.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(Color(hex: "#A29BFE"))
                                Text("Board Selected")
                                    .font(AppTheme.Typography.caption)
                                    .foregroundColor(Color(hex: "#A29BFE"))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color(hex: "#A29BFE").opacity(0.10))
                            .cornerRadius(AppTheme.Radius.full)
                        }
                    }

                    Spacer()
                }

                VStack(spacing: 5) {
                    HStack {
                        Text("Promotion Readiness")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textTertiary)
                        Spacer()
                        Text("\(Int(vm.promotionReadinessPercent * 100))%")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(hex: vm.config.accentHex))
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(AppTheme.Colors.glassBorder)
                                .frame(height: 5)

                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: vm.config.accentHex), Color(hex: vm.config.accentHex).opacity(0.7)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(0, geo.size.width * vm.promotionReadinessPercent), height: 5)
                                .animation(AppTheme.Animation.slow, value: vm.promotionReadinessPercent)
                        }
                    }
                    .frame(height: 5)
                }
            }
        }
    }
}

private struct RankChipRow: View {
    @ObservedObject var vm: PromotionsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Target Rank")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(AppTheme.Colors.textTertiary)
                .tracking(1)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(vm.config.ranks) { rank in
                        let isSelected = vm.selectedTargetRank?.id == rank.id
                        Button {
                            withAnimation(AppTheme.Animation.spring) {
                                vm.selectedTargetRank = rank
                                vm.record.targetPayGrade = rank.payGrade
                            }
                        } label: {
                            VStack(spacing: 2) {
                                Text(rank.abbreviation.components(separatedBy: "/").first ?? rank.abbreviation)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(isSelected ? .white : AppTheme.Colors.textSecondary)
                                Text(rank.payGrade)
                                    .font(.system(size: 9))
                                    .foregroundColor(isSelected ? .white.opacity(0.75) : AppTheme.Colors.textTertiary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(isSelected ? Color(hex: vm.config.accentHex) : AppTheme.Colors.backgroundElevated)
                            .cornerRadius(AppTheme.Radius.full)
                            .overlay(
                                Capsule()
                                    .stroke(isSelected ? .clear : AppTheme.Colors.glassBorder, lineWidth: 1)
                            )
                            .overlay(alignment: .topTrailing) {
                                if rank.isBoardSelected {
                                    Image(systemName: "person.3.fill")
                                        .font(.system(size: 7))
                                        .foregroundColor(isSelected ? .white.opacity(0.7) : AppTheme.Colors.textTertiary)
                                        .offset(x: 2, y: -2)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if let rank = vm.selectedTargetRank {
                HStack(spacing: 6) {
                    Text(rank.title)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    Text("·")
                        .foregroundColor(AppTheme.Colors.textTertiary)
                    Text("Min \(rank.minTISMonths)mo TIS · \(rank.minTIGMonths)mo TIG")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
            }
        }
    }
}

private struct EligibilityBanner: View {
    @ObservedObject var vm: PromotionsViewModel

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            EligPill(label: "TIS", value: "\(vm.record.monthsInService) mo", needed: vm.missingTISMonths > 0 ? "\(vm.missingTISMonths) mo needed" : nil, met: vm.missingTISMonths == 0)
            EligPill(label: "TIG", value: "\(vm.record.monthsInGrade) mo", needed: vm.missingTIGMonths > 0 ? "\(vm.missingTIGMonths) mo needed" : nil, met: vm.missingTIGMonths == 0)

            if vm.isBoardSelected {
                EligPill(label: "Selection", value: "Board", needed: nil, met: true)
            } else if let cutoff = vm.cutoffScore {
                EligPill(label: "Score", value: "\(vm.totalScore)", needed: vm.totalScore < cutoff ? "\(cutoff - vm.totalScore) pts short" : nil, met: vm.totalScore >= cutoff)
            } else {
                EligPill(label: "Score", value: "\(vm.totalScore)", needed: "Set cutoff in Calculator", met: false)
            }
        }
    }
}

private struct EligPill: View {
    let label: String
    let value: String
    let needed: String?
    let met: Bool

    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: met ? "checkmark.circle.fill" : "clock.fill")
                .font(.system(size: 14))
                .foregroundColor(met ? AppTheme.Colors.success : AppTheme.Colors.warning)

            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.Colors.textPrimary)

            Text(label)
                .font(.system(size: 10))
                .foregroundColor(AppTheme.Colors.textTertiary)

            if let needed {
                Text(needed)
                    .font(.system(size: 9))
                    .foregroundColor(AppTheme.Colors.warning)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background(met ? AppTheme.Colors.success.opacity(0.07) : AppTheme.Colors.warning.opacity(0.07))
        .cornerRadius(AppTheme.Radius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                .stroke(met ? AppTheme.Colors.success.opacity(0.2) : AppTheme.Colors.warning.opacity(0.2), lineWidth: 1)
        )
    }
}

private struct SystemInfoCard: View {
    @ObservedObject var vm: PromotionsViewModel
    @State private var expanded = false

    var body: some View {
        Button {
            withAnimation(AppTheme.Animation.spring) {
                expanded.toggle()
            }
        } label: {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(Color(hex: vm.config.accentHex))
                        Text("How \(vm.config.branch.rawValue) Promotions Work")
                            .font(AppTheme.Typography.titleSmall)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                    }
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }

                if expanded {
                    Text(vm.config.systemSummary)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .multilineTextAlignment(.leading)
                        .transition(.opacity.combined(with: .move(edge: .top)))

                    HStack(spacing: 4) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 10))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                        Text("Ref: \(vm.config.officialRef)")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                }
            }
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.Colors.backgroundCard)
            .cornerRadius(AppTheme.Radius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                    .stroke(AppTheme.Colors.glassBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct ResourcesCard: View {
    @ObservedObject var vm: PromotionsViewModel

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            PromoSectionHeader(title: "Official Resources")

            ForEach(vm.config.officialLinks) { link in
                if let url = URL(string: link.url) {
                    Link(destination: url) {
                        HStack(spacing: AppTheme.Spacing.md) {
                            Image(systemName: link.icon)
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: vm.config.accentHex))
                                .frame(width: 32, height: 32)
                                .background(Color(hex: vm.config.accentHex).opacity(0.10))
                                .cornerRadius(AppTheme.Radius.sm)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(link.title)
                                    .font(AppTheme.Typography.bodyMedium)
                                    .foregroundColor(AppTheme.Colors.textPrimary)
                                Text(link.subtitle)
                                    .font(AppTheme.Typography.caption)
                                    .foregroundColor(AppTheme.Colors.textTertiary)
                            }

                            Spacer()

                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 10))
                                .foregroundColor(AppTheme.Colors.textTertiary)
                        }
                        .padding(AppTheme.Spacing.md)
                        .background(AppTheme.Colors.backgroundCard)
                        .cornerRadius(AppTheme.Radius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                                .stroke(AppTheme.Colors.glassBorder, lineWidth: 1)
                        )
                    }
                }
            }
        }
    }
}
