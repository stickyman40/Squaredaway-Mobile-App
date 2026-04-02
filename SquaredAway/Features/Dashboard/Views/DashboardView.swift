import Charts
import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @State private var promotionsSummary = "Track points, target rank, and board readiness."
    @State private var fitnessSummary = "Track workouts, PT scores, splits, and your training calendar."
    @State private var chowSummary = "Track meals, calories, and chow habits."
    @State private var fuelSummary = "Scan chow items, compare scores, and save solid picks."
    @State private var paySummary = "Keep pay-grade and allowance details organized."
    @State private var trackerSummary = "Track assignment details and next milestones."
    @State private var pcsSummary = "Keep PCS logistics and move checkpoints together."
    @State private var benefitsSummary = "Track education, health, retirement, and family benefits."
    @State private var unreadNotifications = 0
    @State private var fitnessLogs: [FitnessLog] = []
    @State private var nutritionLogs: [NutritionLog] = []
    @State private var fuelScans: [FuelScan] = []
    @State private var promotionData: PromotionData?
    @State private var payData: PayData?
    @State private var trackerData: TrackerData?
    @State private var pcsData: PCSData?
    @State private var benefitsData: BenefitsData?

    private let promotionService = PromotionService.shared
    private let fitnessService = FitnessService.shared
    private let nutritionService = NutritionService.shared
    private let barcodeService = BarcodeService.shared
    private let payService = PayService.shared
    private let trackerService = TrackerService.shared
    private let pcsService = PCSService.shared
    private let benefitsService = BenefitsService.shared
    private let notificationService = NotificationService.shared

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.backgroundPrimary.ignoresSafeArea()

                VStack {
                    Circle()
                        .fill(AppTheme.Colors.accentPrimary.opacity(0.12))
                        .frame(width: 360, height: 360)
                        .blur(radius: 90)
                        .offset(x: -110, y: -180)
                    Spacer()
                }

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                        header
                        moduleGrid
                        missionCard
                        readinessOverviewCard
                        todayFocusCard
                        readinessTrendsCard
                        acquisitionCard
                        actionsCard
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.lg)
                }
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink {
                        NotificationsView()
                            .environmentObject(authVM)
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell.fill")
                                .foregroundColor(AppTheme.Colors.accentSecondary)

                            if unreadNotifications > 0 {
                                Text("\(min(unreadNotifications, 9))")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(4)
                                    .background(AppTheme.Colors.error)
                                    .clipShape(Circle())
                                    .offset(x: 8, y: -8)
                            }
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        AppSettingsView()
                            .environmentObject(authVM)
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(AppTheme.Colors.accentSecondary)
                    }
                }
            }
            .task {
                await authVM.refreshProfile()
                await loadSummaries()
            }
            .onAppear {
                Task { await loadSummaries() }
            }
        }
    }

    private var readinessTrendsCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("Weekly Trends")
                    .font(AppTheme.Typography.titleMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                if fitnessLogs.isEmpty && nutritionLogs.isEmpty && promotionData == nil && payData == nil {
                    Text("Log workouts, meals, promotions, or pay details to unlock trend charts.")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                } else {
                    if !fitnessWeeklyPoints.isEmpty {
                        TrendChartSection(
                            title: "Fitness Minutes",
                            subtitle: "Last 7 days",
                            color: AppTheme.Colors.accentSecondary
                        ) {
                            Chart(fitnessWeeklyPoints) { point in
                                BarMark(
                                    x: .value("Day", point.date, unit: .day),
                                    y: .value("Minutes", point.value)
                                )
                                .foregroundStyle(AppTheme.Colors.accentSecondary.gradient)
                                .cornerRadius(4)
                            }
                            .chartXAxis {
                                AxisMarks(values: .stride(by: .day)) { value in
                                    AxisValueLabel(format: .dateTime.weekday(.narrow))
                                }
                            }
                        }
                    }

                    if !nutritionWeeklyPoints.isEmpty {
                        TrendChartSection(
                            title: "Chow Calories",
                            subtitle: "Last 7 days",
                            color: AppTheme.Colors.warning
                        ) {
                            Chart(nutritionWeeklyPoints) { point in
                                AreaMark(
                                    x: .value("Day", point.date, unit: .day),
                                    y: .value("Calories", point.value)
                                )
                                .foregroundStyle(AppTheme.Colors.warning.opacity(0.18))

                                LineMark(
                                    x: .value("Day", point.date, unit: .day),
                                    y: .value("Calories", point.value)
                                )
                                .foregroundStyle(AppTheme.Colors.warning)
                                .interpolationMethod(.catmullRom)

                                PointMark(
                                    x: .value("Day", point.date, unit: .day),
                                    y: .value("Calories", point.value)
                                )
                                .foregroundStyle(AppTheme.Colors.warning)
                            }
                            .chartXAxis {
                                AxisMarks(values: .stride(by: .day)) { value in
                                    AxisValueLabel(format: .dateTime.weekday(.narrow))
                                }
                            }
                        }
                    }

                    if !payBreakdownPoints.isEmpty {
                        TrendChartSection(
                            title: "Pay Breakdown",
                            subtitle: payData?.payGrade ?? "Current monthly estimate",
                            color: AppTheme.Colors.success
                        ) {
                            Chart(payBreakdownPoints) { point in
                                BarMark(
                                    x: .value("Component", point.label),
                                    y: .value("Amount", point.value)
                                )
                                .foregroundStyle(AppTheme.Colors.success.gradient)
                                .annotation(position: .top) {
                                    Text(currency(point.value))
                                        .font(.caption2)
                                        .foregroundColor(AppTheme.Colors.textTertiary)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text(greeting)
                .font(AppTheme.Typography.displayMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)

            Text("Your readiness snapshot is live. Modules are front and center so you can jump straight into the next priority.")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)

            if let profile = authVM.currentProfile,
               let branch = profile.branch?.rawValue,
               let rank = profile.rank,
               !rank.isEmpty {
                BranchBadge(branch: branch, rank: rank)
            }
        }
    }

    private var missionCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Mission Readiness")
                            .font(AppTheme.Typography.titleMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        Text(missionReadinessSubtitle)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(readinessScore)%")
                            .font(AppTheme.Typography.titleLarge)
                            .foregroundColor(AppTheme.Colors.accentSecondary)
                        Text(missionReadinessStatus)
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(missionReadinessColor)
                    }
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(AppTheme.Colors.backgroundElevated)
                            .frame(height: 12)

                        Capsule()
                            .fill(AppTheme.Gradients.primaryButton)
                            .frame(width: max(geometry.size.width * (Double(readinessScore) / 100.0), readinessScore == 0 ? 0 : 20), height: 12)
                    }
                }
                .frame(height: 12)

                HStack(spacing: AppTheme.Spacing.md) {
                    DashboardSummaryTile(title: "Active Modules", value: "\(activeModulesCount)/7", detail: "Tracked now")
                    DashboardSummaryTile(title: "Inbox", value: unreadNotifications == 0 ? "Clear" : "\(unreadNotifications)", detail: unreadNotifications == 1 ? "Unread item" : "Unread items")
                    DashboardSummaryTile(title: "Found Via", value: authVM.currentProfile?.discoverySource?.rawValue ?? "Unknown", detail: "Acquisition")
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.Spacing.md) {
                    MetricTile(title: "Fitness Goal", value: authVM.currentProfile?.fitnessGoal?.rawValue ?? "Set in onboarding")
                    MetricTile(title: "MOS / AFSC", value: authVM.currentProfile?.mos ?? "Add later")
                    MetricTile(title: "Profile Since", value: memberSinceText)
                    MetricTile(title: "Weight / Height", value: bodyStatsSummary)
                }

                if let discoveryNotes = authVM.currentProfile?.discoveryNotes,
                   !discoveryNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Acquisition notes: \(discoveryNotes)")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
        }
    }

    private var readinessOverviewCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Operational Overview")
                            .font(AppTheme.Typography.titleMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        Text("A quick read on how complete your main readiness modules are right now.")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }

                    Spacer()

                    Text("\(readinessScore)%")
                        .font(AppTheme.Typography.titleMedium)
                        .foregroundColor(AppTheme.Colors.accentSecondary)
                }

                HStack(spacing: AppTheme.Spacing.md) {
                    MetricTile(title: "Readiness Score", value: "\(readinessScore)%")
                    MetricTile(title: "Coverage", value: "\(activeModulesCount)/7 modules")
                    MetricTile(title: "Inbox", value: unreadNotifications == 0 ? "Clear" : "\(unreadNotifications) unread")
                }

                ForEach(moduleStatuses) { status in
                    ModuleStatusRow(status: status)
                }
            }
        }
    }

    private var acquisitionCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Acquisition Snapshot")
                            .font(AppTheme.Typography.titleMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        Text("Keep a visible record of how this account found the app and any context worth remembering.")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "megaphone.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.warning)
                }

                HStack(spacing: AppTheme.Spacing.md) {
                    MetricTile(title: "Found Via", value: authVM.currentProfile?.discoverySource?.rawValue ?? "Not captured")
                    MetricTile(title: "Member Since", value: memberSinceText)
                }

                Text(acquisitionNotesText)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }

    private var todayFocusCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("Today Focus")
                    .font(AppTheme.Typography.titleMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                if shouldShowAllCaughtUpMessage {
                    Text("You’re in a good place. Open any module to keep your readiness data current.")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                } else {
                    if trackerData == nil {
                        NavigationLink {
                            TrackerView()
                                .environmentObject(authVM)
                        } label: {
                            FocusNavigationRow(
                                title: "Set up Tracker",
                                subtitle: "Add your duty station, status, and next milestone."
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    if pcsCompletion < 0.6 {
                        NavigationLink {
                            PCSView()
                                .environmentObject(authVM)
                        } label: {
                            FocusNavigationRow(
                                title: "Finish PCS logistics",
                                subtitle: "Confirm route details and mark shipment, lodging, and travel progress."
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    if benefitsCompletion < 0.75 {
                        NavigationLink {
                            BenefitsView()
                                .environmentObject(authVM)
                        } label: {
                            FocusNavigationRow(
                                title: "Review Benefits",
                                subtitle: "Update health, education, retirement, and family-support readiness."
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    if chowCompletion < 0.34 {
                        NavigationLink {
                            NutritionView()
                                .environmentObject(authVM)
                        } label: {
                            FocusNavigationRow(
                                title: "Log Chow",
                                subtitle: "Capture your meals today to keep calories and macros current."
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    if fitnessCompletion < 0.25 {
                        NavigationLink {
                            PTDashboardView()
                                .environmentObject(authVM)
                        } label: {
                            FocusNavigationRow(
                                title: "Open Fitness",
                                subtitle: "Log workouts, follow your split, and keep your fitness plan current."
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var moduleGrid: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Modules")
                    .font(AppTheme.Typography.titleMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Text("Organized shortcuts into the core readiness areas you’ll use most.")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.Spacing.md) {
                NavigationLink {
                    PromotionsView()
                        .environmentObject(authVM)
                } label: {
                    ModuleCard(
                        title: "Promotions",
                        subtitle: promotionsSummary,
                        assetImage: "DashboardPromotions",
                        badgeText: progressBadgeText(for: promotionCompletion)
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    PTDashboardView()
                        .environmentObject(authVM)
                } label: {
                    ModuleCard(
                        title: "Fitness",
                        subtitle: fitnessSummary,
                        assetImage: "DashboardFitness",
                        badgeText: progressBadgeText(for: fitnessCompletion)
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    NutritionView()
                        .environmentObject(authVM)
                } label: {
                    ModuleCard(
                        title: "Chow",
                        subtitle: chowSummary,
                        assetImage: "DashboardChow",
                        badgeText: progressBadgeText(for: chowCompletion)
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    FuelCheckHomeView()
                        .environmentObject(authVM)
                } label: {
                    ModuleCard(
                        title: "Fuel Check",
                        subtitle: fuelSummary,
                        assetImage: "DashboardChow",
                        badgeText: progressBadgeText(for: fuelCompletion),
                        accessibilityIdentifier: "dashboard-module-fuel-check"
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    PayView()
                        .environmentObject(authVM)
                } label: {
                    ModuleCard(
                        title: "Pay",
                        subtitle: paySummary,
                        assetImage: "DashboardPay",
                        badgeText: progressBadgeText(for: payCompletion)
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    TrackerView()
                        .environmentObject(authVM)
                } label: {
                    ModuleCard(
                        title: "Tracker",
                        subtitle: trackerSummary,
                        assetImage: "DashboardTracker",
                        badgeText: progressBadgeText(for: trackerCompletion)
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    PCSView()
                        .environmentObject(authVM)
                } label: {
                    ModuleCard(
                        title: "PCS",
                        subtitle: pcsSummary,
                        assetImage: "DashboardPCS",
                        badgeText: progressBadgeText(for: pcsCompletion)
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    BenefitsView()
                        .environmentObject(authVM)
                } label: {
                    ModuleCard(
                        title: "Benefits",
                        subtitle: benefitsSummary,
                        assetImage: "DashboardBenefits",
                        badgeText: progressBadgeText(for: benefitsCompletion)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var actionsCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("Quick Actions")
                    .font(AppTheme.Typography.titleMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text(authVM.currentUserEmail.isEmpty ? "No active email on file." : authVM.currentUserEmail)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)

                Text("Active modules: \(activeModulesCount) tracked")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textTertiary)

                PrimaryButton("Refresh Profile") {
                    Task {
                        await authVM.refreshProfile()
                        await loadSummaries()
                    }
                }

                NavigationLink {
                    NotificationsView()
                        .environmentObject(authVM)
                } label: {
                    Text(unreadNotifications == 0 ? "Notifications Inbox" : "Notifications Inbox (\(unreadNotifications))")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.accentSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                NavigationLink {
                    AppSettingsView()
                        .environmentObject(authVM)
                } label: {
                    Text("Open Settings")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.accentSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                SecondaryButton(title: "Sign Out") {
                    Task { await authVM.signOut() }
                }
            }
        }
    }

    private var greeting: String {
        let firstName = authVM.currentProfile?.firstName.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return firstName.isEmpty ? "Welcome Back" : "Welcome Back, \(firstName)"
    }

    private var memberSinceText: String {
        guard let createdAt = authVM.currentProfile?.createdAt else { return "Recently" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: createdAt)
    }

    private var bodyStatsSummary: String {
        let height = measurement(authVM.currentProfile?.heightCm, unit: "cm")
        let weight = measurement(authVM.currentProfile?.weightKg, unit: "kg")
        return "\(weight) · \(height)"
    }

    private var activeModulesCount: Int {
        [
            promotionData != nil,
            !fitnessLogs.isEmpty,
            !nutritionLogs.isEmpty,
            payData != nil,
            trackerData != nil,
            pcsData != nil,
            benefitsData != nil
        ]
        .filter { $0 }
        .count
    }

    private var missionReadinessStatus: String {
        if readinessScore >= 80 {
            return "Mission Ready"
        }
        if readinessScore >= 50 {
            return "Building Momentum"
        }
        return "Needs Attention"
    }

    private var missionReadinessSubtitle: String {
        switch missionReadinessStatus {
        case "Mission Ready":
            return "Your core readiness areas are in strong shape and organized at the top of the dashboard."
        case "Building Momentum":
            return "Your readiness foundation is taking shape. Focus on the highlighted modules to keep moving."
        default:
            return "A few core areas still need setup. Start with the top module shortcuts to get squared away faster."
        }
    }

    private var missionReadinessColor: Color {
        color(for: Double(readinessScore) / 100.0)
    }

    private var shouldShowAllCaughtUpMessage: Bool {
        trackerData != nil &&
        pcsCompletion >= 0.6 &&
        benefitsCompletion >= 0.75 &&
        chowCompletion >= 0.34 &&
        fitnessCompletion >= 0.25
    }

    private var readinessScore: Int {
        let components = [
            promotionCompletion,
            fitnessCompletion,
            chowCompletion,
            payCompletion,
            trackerCompletion,
            pcsCompletion,
            benefitsCompletion
        ]

        let average = components.reduce(0, +) / Double(components.count)
        return Int((average * 100).rounded())
    }

    private var acquisitionNotesText: String {
        let notes = authVM.currentProfile?.discoveryNotes?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !notes.isEmpty {
            return notes
        }
        return "Add acquisition notes in Settings if you want to capture more detail about the referral, campaign, or community that brought this user in."
    }

    private var moduleStatuses: [DashboardModuleStatus] {
        [
            DashboardModuleStatus(
                title: "Promotions",
                detail: promotionData == nil ? "Promotion tracker not started yet." : promotionsSummary,
                progressText: "\(Int((promotionCompletion * 100).rounded()))%",
                color: color(for: promotionCompletion)
            ),
            DashboardModuleStatus(
                title: "Fitness",
                detail: fitnessSummary,
                progressText: "\(Int((fitnessCompletion * 100).rounded()))%",
                color: color(for: fitnessCompletion)
            ),
            DashboardModuleStatus(
                title: "Chow",
                detail: chowSummary,
                progressText: "\(Int((chowCompletion * 100).rounded()))%",
                color: color(for: chowCompletion)
            ),
            DashboardModuleStatus(
                title: "Tracker",
                detail: trackerSummary,
                progressText: "\(Int((trackerCompletion * 100).rounded()))%",
                color: color(for: trackerCompletion)
            ),
            DashboardModuleStatus(
                title: "PCS",
                detail: pcsSummary,
                progressText: "\(Int((pcsCompletion * 100).rounded()))%",
                color: color(for: pcsCompletion)
            ),
            DashboardModuleStatus(
                title: "Benefits",
                detail: benefitsSummary,
                progressText: "\(Int((benefitsCompletion * 100).rounded()))%",
                color: color(for: benefitsCompletion)
            )
        ]
    }

    private var promotionCompletion: Double {
        guard let promotionData else { return 0 }
        let target = BranchPromotionConfig.config(for: promotionData.branch).ranks.first { $0.payGrade == promotionData.targetPayGrade }
        let current = PromotionScoring.totalScore(for: promotionData, branch: promotionData.branch, targetPayGrade: target?.payGrade ?? promotionData.targetPayGrade)
        let required = PromotionScoring.cutoffScore(for: promotionData, branch: promotionData.branch)
            ?? PromotionScoring.maxScore(for: promotionData, branch: promotionData.branch, targetPayGrade: target?.payGrade ?? promotionData.targetPayGrade)
        guard required > 0 else { return 0 }
        return min(Double(current) / Double(required), 1)
    }

    private var fitnessCompletion: Double {
        min(Double(fitnessLogs.count) / 4.0, 1)
    }

    private var chowCompletion: Double {
        let todayNutrition = nutritionLogs.filter { Calendar.current.isDateInToday($0.loggedAt) }
        return min(Double(todayNutrition.count) / 3.0, 1)
    }

    private var fuelCompletion: Double {
        let todayFuelScans = fuelScans.filter { Calendar.current.isDateInToday($0.scannedAt) }
        return min(Double(todayFuelScans.count) / 2.0, 1)
    }

    private var payCompletion: Double {
        payData == nil ? 0 : 1
    }

    private var trackerCompletion: Double {
        guard let trackerData else { return 0 }
        let checks = [
            !trackerData.currentDutyStation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !trackerData.dutyStatus.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !trackerData.nextMilestone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            trackerData.reportDate != nil
        ]
        return Double(checks.filter { $0 }.count) / Double(checks.count)
    }

    private var pcsCompletion: Double {
        guard let pcsData else { return 0 }
        let checks = [
            !pcsData.originLocation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !pcsData.destinationLocation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            pcsData.shipmentBooked,
            pcsData.lodgingSecured,
            pcsData.travelBooked
        ]
        return Double(checks.filter { $0 }.count) / Double(checks.count)
    }

    private var benefitsCompletion: Double {
        guard let benefitsData else { return 0 }
        let checks = [
            benefitsData.vaHealthEnrolled,
            benefitsData.giBillReady,
            benefitsData.tspContributing,
            benefitsData.familySupportPlan
        ]
        return Double(checks.filter { $0 }.count) / Double(checks.count)
    }

    private func color(for progress: Double) -> Color {
        if progress >= 0.8 {
            return AppTheme.Colors.success
        }
        if progress >= 0.4 {
            return AppTheme.Colors.warning
        }
        return AppTheme.Colors.textTertiary
    }

    private func progressBadgeText(for progress: Double) -> String {
        if progress >= 0.8 {
            return "Ready"
        }
        if progress > 0 {
            return "Active"
        }
        return "Start"
    }

    private func measurement(_ value: Double?, unit: String) -> String {
        guard let value else { return "Not set" }
        if value.rounded() == value {
            return "\(Int(value)) \(unit)"
        }
        return String(format: "%.1f %@", value, unit)
    }

    private func loadSummaries() async {
        guard let userId = authVM.currentUserId else { return }

        async let promotion = try? promotionService.fetchPromotion(userId: userId)
        async let fitnessLogs = try? fitnessService.fetchLogs(userId: userId)
        async let nutritionLogs = try? nutritionService.fetchLogs(userId: userId)
        async let fuelScans = try? barcodeService.recentScans(userId: userId, limit: 12)
        async let payData = try? payService.fetchPayData(userId: userId)
        async let trackerData = try? trackerService.fetchTracker(userId: userId)
        async let pcsData = try? pcsService.fetchPCS(userId: userId)
        async let benefitsData = try? benefitsService.fetchBenefits(userId: userId)
        async let unreadNotifications = try? notificationService.unreadCount(userId: userId)

        let loadedPromotion = await promotion
        let loadedFitness = await fitnessLogs ?? []
        let loadedNutrition = await nutritionLogs ?? []
        let loadedFuelScans = await fuelScans ?? []
        let loadedPay = await payData
        let loadedTracker = await trackerData
        let loadedPCS = await pcsData
        let loadedBenefits = await benefitsData
        let loadedUnreadNotifications = await unreadNotifications ?? 0

        promotionData = loadedPromotion
        self.fitnessLogs = loadedFitness
        self.nutritionLogs = loadedNutrition
        self.fuelScans = loadedFuelScans
        self.payData = loadedPay
        self.trackerData = loadedTracker
        self.pcsData = loadedPCS
        self.benefitsData = loadedBenefits
        self.unreadNotifications = loadedUnreadNotifications

        if let loadedPromotion {
            let target = BranchPromotionConfig.config(for: loadedPromotion.branch).ranks.first { $0.payGrade == loadedPromotion.targetPayGrade }
            let current = PromotionScoring.totalScore(for: loadedPromotion, branch: loadedPromotion.branch, targetPayGrade: target?.payGrade ?? loadedPromotion.targetPayGrade)
            let required = PromotionScoring.cutoffScore(for: loadedPromotion, branch: loadedPromotion.branch)
                ?? PromotionScoring.maxScore(for: loadedPromotion, branch: loadedPromotion.branch, targetPayGrade: target?.payGrade ?? loadedPromotion.targetPayGrade)
            let targetLabel = target?.abbreviation ?? loadedPromotion.targetPayGrade
            if required > 0, !targetLabel.isEmpty {
                promotionsSummary = "\(current)/\(required) pts toward \(targetLabel)"
            } else {
                promotionsSummary = "Track points, target rank, and board readiness."
            }
        } else {
            promotionsSummary = "Track points, target rank, and board readiness."
        }

        if loadedFitness.isEmpty {
            fitnessSummary = "Track workouts, PT scores, splits, and your training calendar."
        } else {
            let minutes = loadedFitness.reduce(0) { $0 + max($1.duration / 60, 0) }
            fitnessSummary = "\(loadedFitness.count) legacy sessions logged, \(minutes) min total"
        }

        let todayNutrition = loadedNutrition.filter { Calendar.current.isDateInToday($0.loggedAt) }
        if todayNutrition.isEmpty {
            chowSummary = "Track meals, calories, and chow habits."
        } else {
            let calories = todayNutrition.reduce(0) { $0 + $1.calories }
            chowSummary = "\(todayNutrition.count) meals today, \(calories) cal"
        }

        if loadedFuelScans.isEmpty {
            fuelSummary = "Scan chow items, compare scores, and save solid picks."
        } else {
            let todayScans = loadedFuelScans.filter { Calendar.current.isDateInToday($0.scannedAt) }.count
            let loggedScans = loadedFuelScans.filter(\.wasLogged).count
            fuelSummary = todayScans > 0
                ? "\(todayScans) scans today · \(loggedScans) logged recently"
                : "\(loadedFuelScans.count) recent scans · \(loggedScans) logged"
        }

        if let loadedPay {
            let total = loadedPay.basePay + loadedPay.bah + loadedPay.bas
            paySummary = "\(loadedPay.payGrade) · \(currency(total))/mo"
        } else {
            paySummary = "Keep pay-grade and allowance details organized."
        }

        if let loadedTracker {
            let dutyStation = loadedTracker.currentDutyStation.trimmingCharacters(in: .whitespacesAndNewlines)
            let milestone = loadedTracker.nextMilestone.trimmingCharacters(in: .whitespacesAndNewlines)
            trackerSummary = [
                dutyStation.isEmpty ? nil : dutyStation,
                milestone.isEmpty ? nil : milestone
            ]
            .compactMap { $0 }
            .joined(separator: " · ")

            if trackerSummary.isEmpty {
                trackerSummary = "Track assignment details and next milestones."
            }
        } else {
            trackerSummary = "Track assignment details and next milestones."
        }

        if let loadedPCS {
            let completed = [loadedPCS.shipmentBooked, loadedPCS.lodgingSecured, loadedPCS.travelBooked]
                .filter { $0 }
                .count
            let destination = loadedPCS.destinationLocation.trimmingCharacters(in: .whitespacesAndNewlines)
            if destination.isEmpty {
                pcsSummary = "\(completed)/3 move items complete"
            } else {
                pcsSummary = "\(destination) · \(completed)/3 ready"
            }
        } else {
            pcsSummary = "Keep PCS logistics and move checkpoints together."
        }

        if let loadedBenefits {
            let completed = [
                loadedBenefits.vaHealthEnrolled,
                loadedBenefits.giBillReady,
                loadedBenefits.tspContributing,
                loadedBenefits.familySupportPlan
            ]
            .filter { $0 }
            .count
            benefitsSummary = "\(completed)/4 benefits squared away"
        } else {
            benefitsSummary = "Track education, health, retirement, and family benefits."
        }
    }

    private func currency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }

    private var fitnessWeeklyPoints: [DashboardDailyPoint] {
        weeklyPoints(from: fitnessLogs) { Double($0.duration / 60) }
    }

    private var nutritionWeeklyPoints: [DashboardDailyPoint] {
        weeklyPoints(from: nutritionLogs) { Double($0.calories) }
    }

    private var payBreakdownPoints: [DashboardCategoryPoint] {
        guard let payData else { return [] }
        return [
            DashboardCategoryPoint(label: "Base", value: payData.basePay),
            DashboardCategoryPoint(label: "BAH", value: payData.bah),
            DashboardCategoryPoint(label: "BAS", value: payData.bas)
        ]
    }

    private func weeklyPoints<T>(from items: [T], value: (T) -> Double) -> [DashboardDailyPoint] where T: Identifiable {
        let calendar = Calendar.current
        let dates = (0..<7).compactMap { offset in
            calendar.startOfDay(for: calendar.date(byAdding: .day, value: -6 + offset, to: Date()) ?? Date())
        }

        return dates.map { date in
            let total = items.reduce(0.0) { partial, item in
                let itemDate: Date
                switch item {
                case let fitness as FitnessLog:
                    itemDate = fitness.loggedAt
                case let nutrition as NutritionLog:
                    itemDate = nutrition.loggedAt
                default:
                    itemDate = date
                }

                guard calendar.isDate(itemDate, inSameDayAs: date) else {
                    return partial
                }
                return partial + value(item)
            }
            return DashboardDailyPoint(date: date, value: total)
        }
    }
}

private struct DashboardDailyPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

private struct DashboardCategoryPoint: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
}

private struct TrendChartSection<Content: View>: View {
    let title: String
    let subtitle: String
    let color: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppTheme.Typography.titleSmall)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    Text(subtitle)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
                Spacer()
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
            }

            content()
                .frame(height: 160)
        }
    }
}

private struct DashboardModuleStatus: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let progressText: String
    let color: Color
}

private struct ModuleStatusRow: View {
    let status: DashboardModuleStatus

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
            Circle()
                .fill(status.color)
                .frame(width: 10, height: 10)
                .padding(.top, 5)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(status.title)
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    Spacer()
                    Text(status.progressText)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(status.color)
                }

                Text(status.detail)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
        .padding(AppTheme.Spacing.sm)
        .background(AppTheme.Colors.backgroundElevated)
        .cornerRadius(AppTheme.Radius.md)
    }
}

private struct FocusNavigationRow: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTheme.Typography.titleSmall)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Text(subtitle)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }

            Spacer()

            Image(systemName: "arrow.right.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(AppTheme.Colors.accentSecondary)
        }
        .padding(AppTheme.Spacing.sm)
        .background(AppTheme.Colors.backgroundElevated)
        .cornerRadius(AppTheme.Radius.md)
    }
}

private struct MetricTile: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.textTertiary)

            Text(value)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.backgroundElevated)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                .stroke(AppTheme.Colors.glassBorder, lineWidth: 1)
        )
        .cornerRadius(AppTheme.Radius.md)
    }
}

private struct ModuleCard: View {
    let title: String
    let subtitle: String
    let assetImage: String
    let badgeText: String
    var isComingSoon = false
    var accessibilityIdentifier: String?

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                HStack(alignment: .top) {
                    Image(assetImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 68, height: 68)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md))

                    Spacer()

                    Text(isComingSoon ? "Next" : badgeText)
                        .font(AppTheme.Typography.label)
                        .foregroundColor(AppTheme.Colors.accentSecondary)
                        .padding(.horizontal, AppTheme.Spacing.sm)
                        .padding(.vertical, 6)
                        .background(AppTheme.Colors.accentPrimary.opacity(0.12))
                        .overlay(
                            Capsule()
                                .stroke(AppTheme.Colors.accentPrimary.opacity(0.18), lineWidth: 1)
                        )
                        .clipShape(Capsule())
                }

                Text(title)
                    .font(AppTheme.Typography.titleSmall)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text(subtitle)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 168, alignment: .topLeading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(accessibilityIdentifier ?? "")
    }
}

private struct DashboardSummaryTile: View {
    let title: String
    let value: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.textTertiary)
            Text(value)
                .font(AppTheme.Typography.titleSmall)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .lineLimit(2)
            Text(detail)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.sm)
        .background(AppTheme.Colors.backgroundElevated)
        .cornerRadius(AppTheme.Radius.md)
    }
}

#Preview {
    DashboardView()
        .environmentObject(AuthViewModel())
        .preferredColorScheme(.dark)
}
