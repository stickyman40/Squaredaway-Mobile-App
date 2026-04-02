import SwiftUI

struct PromotionHubView: View {
    let branch: MilitaryBranch
    let userId: UUID
    let currentRank: String

    @StateObject private var vm = PromotionsViewModel()

    var body: some View {
        ZStack(alignment: .top) {
            AppTheme.Colors.backgroundPrimary.ignoresSafeArea()

            Circle()
                .fill(Color(hex: vm.config.accentHex).opacity(0.10))
                .frame(width: 400, height: 400)
                .blur(radius: 100)
                .offset(x: 60, y: -80)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                PromotionTabBar(activeTab: $vm.activeTab, accentHex: vm.config.accentHex)
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.top, AppTheme.Spacing.sm)
                    .padding(.bottom, AppTheme.Spacing.xs)

                if vm.isLoading {
                    Spacer()
                    ProgressView("Loading promotions...")
                        .tint(AppTheme.Colors.accentSecondary)
                    Spacer()
                } else {
                    TabView(selection: $vm.activeTab) {
                        PromotionOverviewView(vm: vm)
                            .tag(PromotionsViewModel.PromotionTab.overview)

                        PromotionCalculatorView(vm: vm)
                            .tag(PromotionsViewModel.PromotionTab.calculator)

                        PromotionRoadmapView(vm: vm)
                            .tag(PromotionsViewModel.PromotionTab.roadmap)

                        PromotionImproveView(vm: vm)
                            .tag(PromotionsViewModel.PromotionTab.improve)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(AppTheme.Animation.spring, value: vm.activeTab)
                }
            }
        }
        .navigationTitle("Promotions")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(AppTheme.Colors.backgroundPrimary, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 5) {
                    Image(systemName: branch.icon)
                        .font(.system(size: 11, weight: .semibold))
                    Text(branch.rawValue)
                        .font(AppTheme.Typography.caption)
                }
                .foregroundColor(Color(hex: vm.config.accentHex))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color(hex: vm.config.accentHex).opacity(0.12))
                .cornerRadius(AppTheme.Radius.full)
            }
        }
        .task {
            await vm.configure(branch: branch, userId: userId, currentRank: currentRank)
        }
    }
}

private struct PromotionTabBar: View {
    @Binding var activeTab: PromotionsViewModel.PromotionTab
    let accentHex: String

    var body: some View {
        HStack(spacing: 4) {
            ForEach(PromotionsViewModel.PromotionTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(AppTheme.Animation.spring) {
                        activeTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 16, weight: activeTab == tab ? .bold : .regular))
                        Text(tab.rawValue)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(activeTab == tab ? Color(hex: accentHex) : AppTheme.Colors.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(activeTab == tab ? Color(hex: accentHex).opacity(0.10) : .clear)
                    .cornerRadius(AppTheme.Radius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                            .stroke(activeTab == tab ? Color(hex: accentHex).opacity(0.25) : .clear, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(AppTheme.Colors.backgroundCard)
        .cornerRadius(AppTheme.Radius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                .stroke(AppTheme.Colors.glassBorder, lineWidth: 1)
        )
    }
}

struct PromoSectionHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(AppTheme.Colors.textTertiary)
                .tracking(1.2)

            if let subtitle {
                Text(subtitle)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct PromotionScoreRing: View {
    let score: Int
    let maxScore: Int
    let accentHex: String
    var size: CGFloat = 100
    var lineWidth: CGFloat = 10

    private var progress: Double {
        guard maxScore > 0 else { return 0 }
        return min(1.0, Double(score) / Double(maxScore))
    }

    private var ringColor: Color {
        if progress >= 0.85 { return AppTheme.Colors.success }
        if progress >= 0.6 { return AppTheme.Colors.warning }
        return AppTheme.Colors.error
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(ringColor.opacity(0.08))
                .frame(width: size + 16, height: size + 16)
                .blur(radius: 8)

            Circle()
                .stroke(AppTheme.Colors.glassBorder, lineWidth: lineWidth)
                .frame(width: size, height: size)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(ringColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(AppTheme.Animation.slow, value: progress)

            VStack(spacing: 2) {
                Text("\(score)")
                    .font(.system(size: size * 0.28, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text("/ \(maxScore)")
                    .font(.system(size: size * 0.12))
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
        }
    }
}

struct ComponentBar: View {
    let comp: ScoreComponent
    let accentHex: String

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: comp.icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: comp.color))
                    .frame(width: 24, height: 24)
                    .background(Color(hex: comp.color).opacity(0.12))
                    .cornerRadius(4)

                Text(comp.name)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)

                Spacer()

                Text("\(comp.fmt) / \(comp.fmtMax)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(comp.progress >= 1 ? AppTheme.Colors.success : Color(hex: comp.color))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(hex: comp.color).opacity(0.12))
                        .frame(height: 6)

                    Capsule()
                        .fill(comp.progress >= 1 ? AppTheme.Colors.success : Color(hex: comp.color))
                        .frame(width: max(0, geo.size.width * comp.progress), height: 6)
                        .animation(AppTheme.Animation.slow, value: comp.progress)
                }
            }
            .frame(height: 6)
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.backgroundCard)
        .cornerRadius(AppTheme.Radius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                .stroke(AppTheme.Colors.glassBorder, lineWidth: 1)
        )
    }
}
