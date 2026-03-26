import SwiftUI

struct PromotionsView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @StateObject private var vm = PromotionsViewModel()
    private let reminderService = ReminderService.shared

    var body: some View {
        ZStack {
            AppTheme.Colors.backgroundPrimary.ignoresSafeArea()

            VStack {
                Circle()
                    .fill(Color(hex: vm.branchConfig.accentColor).opacity(0.10))
                    .frame(width: 360, height: 360)
                    .blur(radius: 90)
                    .offset(x: 90, y: -50)
                Spacer()
            }

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    headerCard
                    targetRankSection
                    summaryCard
                    branchDetailSection
                    boardInfoCard
                    tipsSection
                    resourcesSection
                    saveSection
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.lg)
            }
        }
        .navigationTitle("Promotions")
        .task {
            guard let userId = authVM.currentUserId else { return }
            await vm.configure(
                branch: authVM.lockedBranch ?? authVM.currentProfile?.branch ?? .army,
                userId: userId,
                currentRank: authVM.currentProfile?.rank ?? ""
            )
        }
    }

    private var headerCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(vm.branchConfig.branch.rawValue)
                            .font(AppTheme.Typography.titleMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        Text(vm.branchConfig.systemName)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        Text("Ref: \(vm.branchConfig.officialReference)")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }

                    Spacer()

                    Image(systemName: authVM.lockedBranch?.icon ?? vm.branchConfig.branch.icon)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(Color(hex: vm.branchConfig.accentColor))
                }

                Text(vm.branchConfig.systemDescription)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)

                if let lockedBranch = authVM.lockedBranch {
                    BranchLockedBanner(branch: lockedBranch)
                } else if let branch = authVM.currentProfile?.branch?.rawValue,
                          let rank = authVM.currentProfile?.rank,
                          !rank.isEmpty {
                    BranchBadge(branch: branch, rank: rank)
                }
            }
        }
    }

    private var targetRankSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Target Rank")
                .font(AppTheme.Typography.label)
                .foregroundColor(AppTheme.Colors.textTertiary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.xs) {
                    ForEach(vm.branchConfig.rankStructure) { rank in
                        Button {
                            vm.selectedTargetRank = rank
                            vm.record.targetRank = rank.payGrade
                        } label: {
                            VStack(spacing: 2) {
                                Text(rank.abbreviation)
                                    .font(AppTheme.Typography.label)
                                Text(rank.payGrade)
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .foregroundColor(vm.selectedTargetRank?.id == rank.id ? .white : AppTheme.Colors.textSecondary)
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.vertical, AppTheme.Spacing.sm)
                            .background(vm.selectedTargetRank?.id == rank.id ? Color(hex: vm.branchConfig.accentColor) : AppTheme.Colors.backgroundCard)
                            .cornerRadius(AppTheme.Radius.full)
                            .overlay(
                                Capsule()
                                    .stroke(
                                        vm.selectedTargetRank?.id == rank.id ? Color.clear : AppTheme.Colors.glassBorder,
                                        lineWidth: 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if let selected = vm.selectedTargetRank {
                GlassCard(padding: AppTheme.Spacing.md) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text(selected.title)
                            .font(AppTheme.Typography.titleSmall)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        Text("Minimum TIS \(selected.minTIS) mo · Minimum TIG \(selected.minTIG) mo")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textTertiary)
                        Text(selected.notes)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
            }
        }
    }

    private var summaryCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack {
                    Text("Points Progress")
                        .font(AppTheme.Typography.titleSmall)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    Spacer()
                    Text("\(Int((vm.scoreProgress * 100).rounded()))% ready")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }

                HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(vm.scoreLabel.uppercased())
                            .font(AppTheme.Typography.label)
                            .foregroundColor(AppTheme.Colors.textTertiary)

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(vm.computedTotalScore)")
                                .font(.system(size: 42, weight: .bold))
                                .foregroundColor(scoreColor)
                            Text("/ \(vm.maxPossibleScore)")
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Colors.textTertiary)
                        }

                        if let cutoff = vm.cutoffScore {
                            HStack(spacing: 4) {
                                Image(systemName: vm.isAboveCutoff == true ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                    .foregroundColor(vm.isAboveCutoff == true ? AppTheme.Colors.success : AppTheme.Colors.warning)
                                Text("\(vm.cutoffLabel): \(cutoff)")
                                    .font(AppTheme.Typography.bodySmall)
                                    .foregroundColor(vm.isAboveCutoff == true ? AppTheme.Colors.success : AppTheme.Colors.warning)
                            }
                        }
                    }

                    Spacer()

                    ZStack {
                        Circle()
                            .stroke(AppTheme.Colors.glassBorder, lineWidth: 8)
                            .frame(width: 92, height: 92)

                        Circle()
                            .trim(from: 0, to: vm.scoreProgress)
                            .stroke(scoreColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 92, height: 92)
                            .rotationEffect(.degrees(-90))

                        Text("\(Int((vm.scoreProgress * 100).rounded()))%")
                            .font(AppTheme.Typography.titleSmall)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                    }
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(AppTheme.Colors.backgroundElevated)
                            .frame(height: 12)

                        Capsule()
                            .fill(scoreColor)
                            .frame(width: geometry.size.width * vm.scoreProgress, height: 12)
                    }
                }
                .frame(height: 12)

                HStack {
                    MetricPill(title: "Current", value: "\(vm.computedTotalScore)")
                    MetricPill(title: "Target", value: vm.selectedTargetRank?.abbreviation ?? "Not set")
                    MetricPill(title: "Cutoff", value: vm.cutoffScore.map(String.init) ?? "N/A")
                }
            }
        }
    }

    @ViewBuilder
    private var branchDetailSection: some View {
        switch vm.branchConfig.branch {
        case .army:
            armySection
        case .airForce, .spaceForce:
            wapsSection
        case .navy:
            navySection
        case .marines:
            marinesSection
        case .coastGuard:
            coastGuardSection
        }
    }

    private var armySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Army Points Breakdown")
                .font(AppTheme.Typography.label)
                .foregroundColor(AppTheme.Colors.textTertiary)

            ForEach(vm.armyBreakdown, id: \.label) { item in
                PointsRow(label: item.label, current: item.current, max: item.max, accentColor: vm.branchConfig.accentColor)
            }

            GlassCard(padding: AppTheme.Spacing.lg) {
                VStack(spacing: AppTheme.Spacing.md) {
                    AuthTextField(
                        placeholder: "Current rank",
                        icon: "chevron.up.2",
                        text: Binding(
                            get: { vm.record.currentRank },
                            set: { vm.record.currentRank = $0 }
                        ),
                        autocapitalization: .characters
                    )

                    AuthTextField(
                        placeholder: "MOS",
                        icon: "tag.fill",
                        text: Binding(
                            get: { vm.record.armyMos ?? "" },
                            set: { vm.record.armyMos = $0 }
                        ),
                        autocapitalization: .characters
                    )

                    ArmySlider(label: "Military Education", value: Binding(get: { Double(vm.record.armyMilEdPoints ?? 0) }, set: { vm.record.armyMilEdPoints = Int($0) }), range: 0...220, color: "#45B7D1")
                    ArmySlider(label: "Civilian Education", value: Binding(get: { Double(vm.record.armyCivEdPoints ?? 0) }, set: { vm.record.armyCivEdPoints = Int($0) }), range: 0...100, color: "#96CEB4")
                    ArmySlider(label: "Awards", value: Binding(get: { Double(vm.record.armyAwardsPoints ?? 0) }, set: { vm.record.armyAwardsPoints = Int($0) }), range: 0...125, color: "#FFD700")
                    ArmySlider(label: "Military Training", value: Binding(get: { Double(vm.record.armyMilTrgPoints ?? 0) }, set: { vm.record.armyMilTrgPoints = Int($0) }), range: 0...100, color: "#FF9F0A")
                    ArmySlider(label: "Current Cutoff", value: Binding(get: { Double(vm.record.armyCurrentCutoff ?? 0) }, set: { vm.record.armyCurrentCutoff = Int($0) }), range: 0...800, color: vm.branchConfig.accentColor)

                    segmentedPoints(
                        title: "ACFT Points",
                        selected: vm.record.armyAcftPoints ?? 0,
                        values: [0, 30, 40, 45, 50, 55, 60],
                        color: "#A29BFE"
                    ) { vm.record.armyAcftPoints = $0 }

                    segmentedPoints(
                        title: "Weapons Points",
                        selected: vm.record.armyWeaponsPoints ?? 0,
                        values: [0, 10, 14, 20],
                        color: "#FF6B6B"
                    ) { vm.record.armyWeaponsPoints = $0 }
                }
            }
        }
    }

    private var wapsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("\(vm.branchConfig.branch.rawValue) WAPS Breakdown")
                .font(AppTheme.Typography.label)
                .foregroundColor(AppTheme.Colors.textTertiary)

            ForEach(vm.wapsBreakdown, id: \.label) { item in
                DoublePointsRow(label: item.label, current: item.current, max: item.max, accentColor: vm.branchConfig.accentColor)
            }

            GlassCard(padding: AppTheme.Spacing.lg) {
                VStack(spacing: AppTheme.Spacing.md) {
                    AuthTextField(
                        placeholder: "Current rank",
                        icon: "chevron.up.2",
                        text: Binding(get: { vm.record.currentRank }, set: { vm.record.currentRank = $0 }),
                        autocapitalization: .characters
                    )

                    ArmySlider(label: "SKT Score", value: Binding(get: { Double(vm.record.wapsSktScore ?? 0) }, set: { vm.record.wapsSktScore = Int($0) }), range: 0...100, color: "#45B7D1")
                    ArmySlider(label: "PFE Score", value: Binding(get: { Double(vm.record.wapsPfeScore ?? 0) }, set: { vm.record.wapsPfeScore = Int($0) }), range: 0...100, color: "#96CEB4")
                    ArmySlider(label: "EPR Points", value: Binding(get: { Double(vm.record.wapsEprScore ?? 0) }, set: { vm.record.wapsEprScore = Int($0) }), range: 0...135, color: "#FFD700")
                    ArmySlider(label: "Decorations", value: Binding(get: { Double(vm.record.wapsDecorationsPoints ?? 0) }, set: { vm.record.wapsDecorationsPoints = Int($0) }), range: 0...25, color: "#FF9F0A")
                    ArmySlider(label: "AFADCONS", value: Binding(get: { Double(vm.record.wapsAfadconsPoints ?? 0) }, set: { vm.record.wapsAfadconsPoints = Int($0) }), range: 0...25, color: vm.branchConfig.accentColor)

                    HStack(spacing: AppTheme.Spacing.md) {
                        numericField(title: "TIS", value: Binding(get: { vm.record.wapsTisPoints }, set: { vm.record.wapsTisPoints = $0 }))
                        numericField(title: "TIG", value: Binding(get: { vm.record.wapsTigPoints }, set: { vm.record.wapsTigPoints = $0 }))
                        numericField(title: "Cutoff", value: Binding(get: { vm.record.wapsCutoffScore }, set: { vm.record.wapsCutoffScore = $0 }))
                    }
                }
            }
        }
    }

    private var navySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Navy Final Multiple Score")
                .font(AppTheme.Typography.label)
                .foregroundColor(AppTheme.Colors.textTertiary)

            ForEach(vm.navyBreakdown, id: \.label) { item in
                DoublePointsRow(label: item.label, current: item.current, max: item.max, accentColor: vm.branchConfig.accentColor)
            }

            GlassCard(padding: AppTheme.Spacing.lg) {
                VStack(spacing: AppTheme.Spacing.md) {
                    AuthTextField(
                        placeholder: "Current rank",
                        icon: "chevron.up.2",
                        text: Binding(get: { vm.record.currentRank }, set: { vm.record.currentRank = $0 }),
                        autocapitalization: .characters
                    )

                    HStack(spacing: AppTheme.Spacing.md) {
                        decimalField(title: "PMA", value: Binding(get: { vm.record.navyPmaScore }, set: { vm.record.navyPmaScore = $0 }))
                        numericField(title: "Exam", value: Binding(get: { vm.record.navyExamScore }, set: { vm.record.navyExamScore = $0 }))
                    }

                    HStack(spacing: AppTheme.Spacing.md) {
                        decimalField(title: "SIPG", value: Binding(get: { vm.record.navySipgPoints }, set: { vm.record.navySipgPoints = $0 }))
                        decimalField(title: "PNA", value: Binding(get: { vm.record.navyPnaPoints }, set: { vm.record.navyPnaPoints = $0 }))
                        numericField(title: "Awards", value: Binding(get: { vm.record.navyAwardsPoints }, set: { vm.record.navyAwardsPoints = $0 }))
                    }

                    DatePicker(
                        "Cycle Exam Date",
                        selection: Binding(
                            get: { vm.record.navyCycleExamDate ?? Date() },
                            set: { vm.record.navyCycleExamDate = $0 }
                        ),
                        displayedComponents: .date
                    )
                    .tint(AppTheme.Colors.accentSecondary)
                }
            }
        }
    }

    private var marinesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Marine Composite Score")
                .font(AppTheme.Typography.label)
                .foregroundColor(AppTheme.Colors.textTertiary)

            ForEach(vm.marineBreakdown, id: \.label) { item in
                PointsRow(label: item.label, current: item.current, max: item.max, accentColor: vm.branchConfig.accentColor)
            }

            GlassCard(padding: AppTheme.Spacing.lg) {
                VStack(spacing: AppTheme.Spacing.md) {
                    AuthTextField(
                        placeholder: "Current rank",
                        icon: "chevron.up.2",
                        text: Binding(get: { vm.record.currentRank }, set: { vm.record.currentRank = $0 }),
                        autocapitalization: .characters
                    )

                    decimalField(title: "PRO Mark", value: Binding(get: { vm.record.marineProMark }, set: { vm.record.marineProMark = $0 }))
                    decimalField(title: "CON Mark", value: Binding(get: { vm.record.marineConMark }, set: { vm.record.marineConMark = $0 }))
                    ArmySlider(label: "PFT", value: Binding(get: { Double(vm.record.marinePftScore ?? 0) }, set: { vm.record.marinePftScore = Int($0) }), range: 0...300, color: "#96CEB4")
                    ArmySlider(label: "CFT", value: Binding(get: { Double(vm.record.marineCftScore ?? 0) }, set: { vm.record.marineCftScore = Int($0) }), range: 0...300, color: "#FFD700")

                    segmentedPoints(
                        title: "Rifle Qualification",
                        selected: vm.record.marineRifleScore ?? 0,
                        values: [0, 3, 4, 5],
                        color: vm.branchConfig.accentColor
                    ) { vm.record.marineRifleScore = $0 }

                    HStack(spacing: AppTheme.Spacing.md) {
                        numericField(title: "MCI", value: Binding(get: { vm.record.marineMciPoints }, set: { vm.record.marineMciPoints = $0 }))
                        numericField(title: "Cutting", value: Binding(get: { vm.record.marineCuttingScore }, set: { vm.record.marineCuttingScore = $0 }))
                    }
                }
            }
        }
    }

    private var coastGuardSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Coast Guard SWE")
                .font(AppTheme.Typography.label)
                .foregroundColor(AppTheme.Colors.textTertiary)

            ForEach(vm.cgBreakdown, id: \.label) { item in
                DoublePointsRow(label: item.label, current: item.current, max: item.max, accentColor: vm.branchConfig.accentColor)
            }

            GlassCard(padding: AppTheme.Spacing.lg) {
                VStack(spacing: AppTheme.Spacing.md) {
                    AuthTextField(
                        placeholder: "Current rank",
                        icon: "chevron.up.2",
                        text: Binding(get: { vm.record.currentRank }, set: { vm.record.currentRank = $0 }),
                        autocapitalization: .characters
                    )

                    ArmySlider(label: "SWE Score", value: Binding(get: { Double(vm.record.cgSweScore ?? 0) }, set: { vm.record.cgSweScore = Int($0) }), range: 0...100, color: vm.branchConfig.accentColor)
                    decimalField(title: "Performance Factor", value: Binding(get: { vm.record.cgPerfFactor }, set: { vm.record.cgPerfFactor = $0 }))
                    numericField(title: "Advancement Cut", value: Binding(get: { vm.record.cgAdvancementCut }, set: { vm.record.cgAdvancementCut = $0 }))
                }
            }
        }
    }

    private var boardInfoCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("Board / Cycle Planning")
                    .font(AppTheme.Typography.titleSmall)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                DatePicker(
                    "Next board or cycle date",
                    selection: Binding(
                        get: { vm.record.nextBoardDate ?? vm.record.boardDate ?? Date() },
                        set: {
                            vm.record.nextBoardDate = $0
                            vm.record.boardDate = $0
                        }
                    ),
                    displayedComponents: .date
                )
                .tint(AppTheme.Colors.accentSecondary)

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("Notes")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textTertiary)

                    TextEditor(
                        text: Binding(
                            get: { vm.record.notes ?? "" },
                            set: { vm.record.notes = $0.isEmpty ? nil : $0 }
                        )
                    )
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 120)
                    .padding(AppTheme.Spacing.sm)
                    .background(AppTheme.Colors.backgroundCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                            .stroke(AppTheme.Colors.glassBorder, lineWidth: 1)
                    )
                    .cornerRadius(AppTheme.Radius.md)
                }
            }
        }
    }

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Promotion Tips")
                .font(AppTheme.Typography.label)
                .foregroundColor(AppTheme.Colors.textTertiary)

            ForEach(vm.branchConfig.boardTips) { tip in
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Circle()
                            .fill(Color(hex: tip.priorityColor))
                            .frame(width: 8, height: 8)
                        Text(tip.title)
                            .font(AppTheme.Typography.titleSmall)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                    }
                    Text(tip.body)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                .padding(AppTheme.Spacing.md)
                .background(Color(hex: tip.priorityColor).opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                        .stroke(Color(hex: tip.priorityColor).opacity(0.18), lineWidth: 1)
                )
                .cornerRadius(AppTheme.Radius.md)
            }
        }
    }

    private var resourcesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Official Resources")
                .font(AppTheme.Typography.label)
                .foregroundColor(AppTheme.Colors.textTertiary)

            ForEach(vm.branchConfig.resources) { resource in
                if let url = URL(string: resource.url) {
                    Link(destination: url) {
                        HStack(spacing: AppTheme.Spacing.md) {
                            Image(systemName: resource.icon)
                                .foregroundColor(Color(hex: vm.branchConfig.accentColor))
                                .frame(width: 32, height: 32)
                                .background(Color(hex: vm.branchConfig.accentColor).opacity(0.12))
                                .cornerRadius(AppTheme.Radius.sm)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(resource.title)
                                    .font(AppTheme.Typography.bodyMedium)
                                    .foregroundColor(AppTheme.Colors.textPrimary)
                                Text(resource.subtitle)
                                    .font(AppTheme.Typography.caption)
                                    .foregroundColor(AppTheme.Colors.textTertiary)
                            }

                            Spacer()

                            Image(systemName: "arrow.up.right")
                                .foregroundColor(AppTheme.Colors.textTertiary)
                        }
                        .padding(AppTheme.Spacing.md)
                        .background(AppTheme.Colors.backgroundCard)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                                .stroke(AppTheme.Colors.glassBorder, lineWidth: 1)
                        )
                        .cornerRadius(AppTheme.Radius.md)
                    }
                }
            }
        }
    }

    private var saveSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            if let errorMessage = vm.errorMessage {
                StatusBanner(message: errorMessage, color: AppTheme.Colors.error, icon: "exclamationmark.triangle.fill")
            }

            if let successMessage = vm.successMessage {
                StatusBanner(message: successMessage, color: AppTheme.Colors.success, icon: "checkmark.circle.fill")
            }

            PrimaryButton("Save Promotion Tracker", isLoading: vm.isSaving) {
                Task {
                    await vm.save()
                    if let boardDate = vm.record.nextBoardDate ?? vm.record.boardDate,
                       vm.errorMessage == nil {
                        let granted = try? await reminderService.requestAuthorization()
                        if granted == true {
                            try? await reminderService.scheduleBoardDateReminders(
                                promotionID: vm.record.id,
                                targetRank: vm.selectedTargetRank?.abbreviation ?? vm.record.targetRank,
                                boardDate: boardDate
                            )
                        }
                    }
                }
            }

            if vm.configuredForExistingRecord {
                Button(role: .destructive) {
                    Task {
                        try? await reminderService.removeBoardDateReminders(promotionID: vm.record.id)
                        await vm.delete()
                    }
                } label: {
                    Text("Delete Promotion Tracker")
                        .font(AppTheme.Typography.bodySmall)
                }
            }
        }
    }

    private var scoreColor: Color {
        if let above = vm.isAboveCutoff {
            return above ? AppTheme.Colors.success : AppTheme.Colors.warning
        }
        if vm.scoreProgress >= 0.8 {
            return AppTheme.Colors.success
        }
        if vm.scoreProgress >= 0.45 {
            return AppTheme.Colors.warning
        }
        return AppTheme.Colors.accentSecondary
    }
    
    private func numericField(title: String, value: Binding<Int?>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.textTertiary)
            TextField(
                "0",
                text: Binding(
                    get: { value.wrappedValue.map(String.init) ?? "" },
                    set: { value.wrappedValue = Int($0) }
                )
            )
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .padding(AppTheme.Spacing.sm)
            .background(AppTheme.Colors.backgroundElevated)
            .foregroundColor(AppTheme.Colors.textPrimary)
            .cornerRadius(AppTheme.Radius.sm)
        }
        .frame(maxWidth: .infinity)
    }

    private func decimalField(title: String, value: Binding<Double?>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.textTertiary)
            TextField(
                "0.0",
                text: Binding(
                    get: {
                        guard let value = value.wrappedValue else { return "" }
                        return String(format: value.rounded() == value ? "%.0f" : "%.1f", value)
                    },
                    set: { value.wrappedValue = Double($0) }
                )
            )
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.center)
            .padding(AppTheme.Spacing.sm)
            .background(AppTheme.Colors.backgroundElevated)
            .foregroundColor(AppTheme.Colors.textPrimary)
            .cornerRadius(AppTheme.Radius.sm)
        }
        .frame(maxWidth: .infinity)
    }

    private func segmentedPoints(title: String, selected: Int, values: [Int], color: String, onSelect: @escaping (Int) -> Void) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(title)
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Colors.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.xs) {
                    ForEach(values, id: \.self) { value in
                        Button {
                            onSelect(value)
                        } label: {
                            Text("\(value)")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(selected == value ? .white : AppTheme.Colors.textSecondary)
                                .padding(.horizontal, AppTheme.Spacing.sm)
                                .padding(.vertical, AppTheme.Spacing.xs)
                                .background(selected == value ? Color(hex: color) : AppTheme.Colors.backgroundElevated)
                                .cornerRadius(AppTheme.Radius.full)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private struct ArmySlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let color: String

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(label)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                Spacer()
                Text("\(Int(value)) / \(Int(range.upperBound))")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(Color(hex: color))
            }
            Slider(value: $value, in: range, step: 1)
                .tint(Color(hex: color))
        }
    }
}

private struct MetricPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.textTertiary)
            Text(value)
                .font(AppTheme.Typography.titleSmall)
                .foregroundColor(AppTheme.Colors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.sm)
        .background(AppTheme.Colors.backgroundElevated)
        .cornerRadius(AppTheme.Radius.md)
    }
}

private struct PointsRow: View {
    let label: String
    let current: Int
    let max: Int
    let accentColor: String

    private var progress: Double {
        guard max > 0 else { return 0 }
        return min(Double(current) / Double(max), 1)
    }

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(AppTheme.Colors.glassBorder)
                            .frame(height: 4)
                        Capsule()
                            .fill(Color(hex: accentColor))
                            .frame(width: geometry.size.width * progress, height: 4)
                    }
                }
                .frame(height: 4)
            }

            Text("\(current)/\(max)")
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(Color(hex: accentColor))
                .frame(width: 72, alignment: .trailing)
        }
        .padding(AppTheme.Spacing.sm)
        .background(AppTheme.Colors.backgroundCard)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                .stroke(AppTheme.Colors.glassBorder, lineWidth: 1)
        )
        .cornerRadius(AppTheme.Radius.md)
    }
}

private struct DoublePointsRow: View {
    let label: String
    let current: Double
    let max: Double
    let accentColor: String

    private var progress: Double {
        guard max > 0 else { return 0 }
        return min(current / max, 1)
    }

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(AppTheme.Colors.glassBorder)
                            .frame(height: 4)
                        Capsule()
                            .fill(Color(hex: accentColor))
                            .frame(width: geometry.size.width * progress, height: 4)
                    }
                }
                .frame(height: 4)
            }

            Text(String(format: "%.0f/%.0f", current, max))
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(Color(hex: accentColor))
                .frame(width: 72, alignment: .trailing)
        }
        .padding(AppTheme.Spacing.sm)
        .background(AppTheme.Colors.backgroundCard)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                .stroke(AppTheme.Colors.glassBorder, lineWidth: 1)
        )
        .cornerRadius(AppTheme.Radius.md)
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
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                .stroke(color.opacity(0.24), lineWidth: 1)
        )
        .cornerRadius(AppTheme.Radius.sm)
    }
}

#Preview {
    NavigationStack {
        PromotionsView()
            .environmentObject(AuthViewModel())
            .preferredColorScheme(.dark)
    }
}
