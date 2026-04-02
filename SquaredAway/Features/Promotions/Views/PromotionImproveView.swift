import SwiftUI

struct PromotionImproveView: View {
    @ObservedObject var vm: PromotionsViewModel
    @State private var appeared = false
    @State private var expandedTipID: String?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppTheme.Spacing.lg) {
                GapSummaryCard(vm: vm)
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .opacity(appeared ? 1 : 0)

                if !vm.improvementActions.isEmpty {
                    VStack(spacing: AppTheme.Spacing.sm) {
                        PromoSectionHeader(title: "Priority Actions", subtitle: "Ranked by likely points impact")
                            .padding(.horizontal, AppTheme.Spacing.md)

                        ForEach(Array(vm.improvementActions.enumerated()), id: \.element.id) { index, action in
                            ImprovementActionCard(action: action, rank: index + 1)
                                .padding(.horizontal, AppTheme.Spacing.md)
                        }
                    }
                    .opacity(appeared ? 1 : 0)
                }

                VStack(spacing: AppTheme.Spacing.sm) {
                    PromoSectionHeader(title: "Pro Tips", subtitle: "\(vm.config.branch.rawValue) guidance")
                        .padding(.horizontal, AppTheme.Spacing.md)

                    ForEach(vm.config.tips) { tip in
                        TipCard(tip: tip, isExpanded: expandedTipID == tip.id) {
                            withAnimation(AppTheme.Animation.spring) {
                                expandedTipID = expandedTipID == tip.id ? nil : tip.id
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.md)
                    }
                }
                .opacity(appeared ? 1 : 0)

                if vm.isBoardSelected {
                    BoardPrepSection()
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
        }
    }
}

private struct GapSummaryCard: View {
    @ObservedObject var vm: PromotionsViewModel

    var body: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(spacing: AppTheme.Spacing.md) {
                HStack(spacing: AppTheme.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.Colors.backgroundElevated)
                            .frame(width: 64, height: 64)
                        VStack(spacing: 1) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Color(hex: vm.config.accentHex))
                            Text("Improve")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(AppTheme.Colors.textTertiary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        if vm.isBoardSelected {
                            Text("Board-Selected Rank")
                                .font(AppTheme.Typography.titleSmall)
                                .foregroundColor(AppTheme.Colors.textPrimary)
                            Text("No hard cutoff applies here. Focus on evaluation quality, leadership visibility, and complete record prep.")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        } else if let cutoff = vm.cutoffScore {
                            let gap = cutoff - vm.totalScore
                            if gap > 0 {
                                Text("\(gap) points to cutoff")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(AppTheme.Colors.warning)
                                Text("You need \(gap) more points to reach the current \(vm.cutoffLabel.lowercased()) of \(cutoff).")
                                    .font(AppTheme.Typography.caption)
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            } else {
                                Text("Above cutoff by \(abs(gap)) pts")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(AppTheme.Colors.success)
                                Text("You are currently above the latest cutoff. Focus on maintaining the categories you can still improve.")
                                    .font(AppTheme.Typography.caption)
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        } else {
                            Text("Add your \(vm.cutoffLabel)")
                                .font(AppTheme.Typography.titleSmall)
                                .foregroundColor(AppTheme.Colors.textPrimary)
                            Text("Enter the latest published cutoff in Calculator to see the exact gap and ranked actions.")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    Spacer()
                }

                if !vm.isBoardSelected {
                    let potential = vm.improvementActions.reduce(0) { total, action in
                        total + (Int(action.pointsGain.filter(\.isNumber).prefix(3)) ?? 0)
                    }
                    if potential > 0 {
                        Divider().background(AppTheme.Colors.glassBorder)
                        HStack {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 11))
                                .foregroundColor(Color(hex: "#FFD700"))
                            Text("You likely have \(potential)+ points available across the actions below")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                            Spacer()
                        }
                    }
                }
            }
        }
    }
}

private struct ImprovementActionCard: View {
    let action: ImprovementAction
    let rank: Int
    @State private var expanded = false

    var body: some View {
        Button {
            withAnimation(AppTheme.Animation.spring) {
                expanded.toggle()
            }
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: AppTheme.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(rank == 1 ? Color(hex: "#FFD700").opacity(0.15) : AppTheme.Colors.backgroundElevated)
                            .frame(width: 32, height: 32)
                        Text("\(rank)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(rank == 1 ? Color(hex: "#FFD700") : AppTheme.Colors.textTertiary)
                    }

                    Image(systemName: action.category.icon)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: action.category.color))
                        .frame(width: 30, height: 30)
                        .background(Color(hex: action.category.color).opacity(0.12))
                        .cornerRadius(AppTheme.Radius.sm)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(action.title)
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .multilineTextAlignment(.leading)

                        HStack(spacing: 6) {
                            Text(action.pointsGain)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(AppTheme.Colors.success)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppTheme.Colors.success.opacity(0.12))
                                .cornerRadius(AppTheme.Radius.sm)

                            Text(action.effort.label)
                                .font(.system(size: 10))
                                .foregroundColor(Color(hex: action.effort.color))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(hex: action.effort.color).opacity(0.10))
                                .cornerRadius(AppTheme.Radius.sm)

                            Text(action.timeframe)
                                .font(.system(size: 10))
                                .foregroundColor(AppTheme.Colors.textTertiary)
                        }
                    }

                    Spacer()

                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
                .padding(AppTheme.Spacing.md)

                if expanded {
                    VStack(alignment: .leading, spacing: 8) {
                        Divider()
                            .background(AppTheme.Colors.glassBorder)
                            .padding(.horizontal, AppTheme.Spacing.md)

                        Text(action.detail)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.bottom, AppTheme.Spacing.sm)

                        if let link = action.link, let url = URL(string: link) {
                            Link("Open official resource", destination: url)
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(Color(hex: action.category.color))
                                .padding(.horizontal, AppTheme.Spacing.md)
                                .padding(.bottom, AppTheme.Spacing.md)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .background(AppTheme.Colors.backgroundCard)
            .cornerRadius(AppTheme.Radius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                    .stroke(rank == 1 ? Color(hex: "#FFD700").opacity(0.25) : AppTheme.Colors.glassBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct TipCard: View {
    let tip: PromotionTip
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: AppTheme.Spacing.md) {
                    Circle()
                        .fill(Color(hex: tip.impact.color))
                        .frame(width: 8, height: 8)

                    Text(tip.title)
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(tip.impact.label)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(Color(hex: tip.impact.color))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: tip.impact.color).opacity(0.10))
                        .cornerRadius(AppTheme.Radius.sm)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
                .padding(AppTheme.Spacing.md)

                if isExpanded {
                    VStack(alignment: .leading, spacing: 0) {
                        Divider()
                            .background(AppTheme.Colors.glassBorder)
                            .padding(.horizontal, AppTheme.Spacing.md)
                        Text(tip.body)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(AppTheme.Spacing.md)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .background(AppTheme.Colors.backgroundCard)
            .cornerRadius(AppTheme.Radius.lg)
            .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.lg).stroke(AppTheme.Colors.glassBorder, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

private struct BoardPrepSection: View {
    private let boardTips: [(String, String, String, String)] = [
        ("doc.text.fill", "#45B7D1", "Evaluation trends matter", "Boards look for consistent record quality and strong narratives over time."),
        ("person.fill.checkmark", "#96CEB4", "Leadership roles matter more", "Visible billet leadership and documented results tend to separate similar records."),
        ("graduationcap.fill", "#FFD700", "PME completion should be early", "Complete required professional military education before the board window gets tight."),
        ("calendar.badge.checkmark", "#FF9F0A", "Prepare years out", "Board-selected ranks reward long-term record building, not last-minute fixes."),
        ("person.3.fill", "#A29BFE", "Seek senior mentorship", "Feedback from members who have seen boards up close can reveal blind spots in your record.")
    ]

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            PromoSectionHeader(title: "Board Preparation", subtitle: "Whole-record focus for senior enlisted boards")

            ForEach(boardTips, id: \.2) { icon, color, title, body in
                HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: color))
                        .frame(width: 32, height: 32)
                        .background(Color(hex: color).opacity(0.12))
                        .cornerRadius(AppTheme.Radius.sm)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        Text(body)
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(AppTheme.Spacing.md)
                .background(AppTheme.Colors.backgroundCard)
                .cornerRadius(AppTheme.Radius.lg)
                .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.lg).stroke(AppTheme.Colors.glassBorder, lineWidth: 1))
            }
        }
    }
}
