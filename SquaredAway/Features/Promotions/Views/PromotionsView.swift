import Charts
import SwiftUI

struct PromotionsView: View {
    @EnvironmentObject private var authVM: AuthViewModel

    @State private var draft = PromotionDraft()
    @State private var promotionId: UUID?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var didLoad = false

    private let promotionService = PromotionService.shared
    private let reminderService = ReminderService.shared

    var body: some View {
        ZStack {
            AppTheme.Colors.backgroundPrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    summaryCard
                    progressCard
                    chartCard
                    detailsCard
                    saveSection
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.lg)
            }
        }
        .navigationTitle("Promotions")
        .task {
            guard !didLoad else { return }
            didLoad = true
            await loadPromotion()
        }
    }

    private var summaryCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Promotion Tracker")
                            .font(AppTheme.Typography.titleMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        Text("Capture your current rank, target rank, and points needed to stay board-ready.")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.accentSecondary)
                }

                if let branch = authVM.currentProfile?.branch?.rawValue,
                   let rank = authVM.currentProfile?.rank,
                   !rank.isEmpty {
                    BranchBadge(branch: branch, rank: rank)
                }
            }
        }
    }

    private var progressCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack {
                    Text("Points Progress")
                        .font(AppTheme.Typography.titleSmall)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    Spacer()
                    Text(progressText)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(AppTheme.Colors.backgroundElevated)
                            .frame(height: 12)

                        Capsule()
                            .fill(AppTheme.Gradients.primaryButton)
                            .frame(width: geometry.size.width * progressFraction, height: 12)
                    }
                }
                .frame(height: 12)

                HStack {
                    MetricPill(title: "Current", value: draft.pointsCurrent.isEmpty ? "0" : draft.pointsCurrent)
                    MetricPill(title: "Required", value: draft.pointsRequired.isEmpty ? "0" : draft.pointsRequired)
                    MetricPill(title: "Remaining", value: String(pointsRemaining))
                }
            }
        }
    }

    private var detailsCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(spacing: AppTheme.Spacing.md) {
                AuthTextField(
                    placeholder: "Current rank",
                    icon: "chevron.up.2",
                    text: $draft.currentRank
                )

                AuthTextField(
                    placeholder: "Target rank",
                    icon: "flag.fill",
                    text: $draft.targetRank
                )

                HStack(spacing: AppTheme.Spacing.md) {
                    AuthTextField(
                        placeholder: "Current points",
                        icon: "number.circle.fill",
                        text: $draft.pointsCurrent,
                        keyboardType: .numberPad
                    )

                    AuthTextField(
                        placeholder: "Points required",
                        icon: "target",
                        text: $draft.pointsRequired,
                        keyboardType: .numberPad
                    )
                }

                Toggle(isOn: $draft.hasBoardDate.animation()) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Board date scheduled")
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        Text("Track an upcoming board or promotion review date.")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                }
                .tint(AppTheme.Colors.accentPrimary)

                if draft.hasBoardDate {
                    DatePicker(
                        "Board Date",
                        selection: $draft.boardDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .tint(AppTheme.Colors.accentSecondary)
                    .padding(.horizontal, AppTheme.Spacing.xs)
                    .background(AppTheme.Colors.backgroundElevated)
                    .cornerRadius(AppTheme.Radius.lg)
                }

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("Notes")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textTertiary)

                    TextEditor(text: $draft.notes)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 140)
                        .padding(AppTheme.Spacing.sm)
                        .background(AppTheme.Colors.backgroundCard)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                                .stroke(AppTheme.Colors.glassBorder, lineWidth: 1)
                        )
                        .cornerRadius(AppTheme.Radius.md)
                }
            }
        }
    }

    private var chartCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("Rank Progress")
                    .font(AppTheme.Typography.titleMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                if pointsRequiredValue == 0 {
                    Text("Set your required points to see a chart.")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                } else {
                    Chart(progressBars) { bar in
                        BarMark(
                            x: .value("Type", bar.label),
                            y: .value("Points", bar.value)
                        )
                        .foregroundStyle(bar.color.gradient)
                        .annotation(position: .top) {
                            Text("\(Int(bar.value))")
                                .font(.caption2)
                                .foregroundColor(AppTheme.Colors.textTertiary)
                        }
                    }
                    .frame(height: 180)
                }
            }
        }
    }

    private var saveSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            if let errorMessage {
                StatusBanner(message: errorMessage, color: AppTheme.Colors.error, icon: "exclamationmark.triangle.fill")
            }

            if let successMessage {
                StatusBanner(message: successMessage, color: AppTheme.Colors.success, icon: "checkmark.circle.fill")
            }

            PrimaryButton("Save Promotion Tracker", isLoading: isLoading) {
                Task { await savePromotion() }
            }

            if promotionId != nil {
                Button(role: .destructive) {
                    Task { await deletePromotion() }
                } label: {
                    Text("Delete Promotion Tracker")
                        .font(AppTheme.Typography.bodySmall)
                }
            }
        }
    }

    private var pointsCurrentValue: Int {
        Int(draft.pointsCurrent) ?? 0
    }

    private var pointsRequiredValue: Int {
        Int(draft.pointsRequired) ?? 0
    }

    private var pointsRemaining: Int {
        max(pointsRequiredValue - pointsCurrentValue, 0)
    }

    private var progressFraction: CGFloat {
        guard pointsRequiredValue > 0 else { return 0 }
        return min(CGFloat(pointsCurrentValue) / CGFloat(pointsRequiredValue), 1)
    }

    private var progressText: String {
        if pointsRequiredValue == 0 {
            return "Set your required points"
        }
        return "\(Int(progressFraction * 100))% complete"
    }

    private var progressBars: [PromotionBarPoint] {
        [
            PromotionBarPoint(label: "Current", value: Double(pointsCurrentValue), color: AppTheme.Colors.accentSecondary),
            PromotionBarPoint(label: "Remaining", value: Double(pointsRemaining), color: AppTheme.Colors.warning),
            PromotionBarPoint(label: "Required", value: Double(pointsRequiredValue), color: AppTheme.Colors.success)
        ]
    }

    private func loadPromotion() async {
        guard let userId = authVM.currentUserId else { return }

        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer { isLoading = false }

        do {
            let promotion = try await promotionService.fetchPromotion(userId: userId)
            if let promotion {
                promotionId = promotion.id
                draft = PromotionDraft(
                    currentRank: promotion.currentRank,
                    targetRank: promotion.targetRank,
                    pointsCurrent: String(promotion.pointsCurrent),
                    pointsRequired: String(promotion.pointsRequired),
                    hasBoardDate: promotion.boardDate != nil,
                    boardDate: promotion.boardDate ?? Date(),
                    notes: promotion.notes ?? ""
                )
            } else {
                draft.currentRank = authVM.currentProfile?.rank ?? ""
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func savePromotion() async {
        guard validateDraft() else { return }
        guard let userId = authVM.currentUserId else {
            errorMessage = "Session unavailable. Please sign in again."
            return
        }

        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer { isLoading = false }

        let promotion = PromotionData(
            id: promotionId ?? UUID(),
            userId: userId,
            currentRank: draft.currentRank.trimmingCharacters(in: .whitespacesAndNewlines),
            targetRank: draft.targetRank.trimmingCharacters(in: .whitespacesAndNewlines),
            pointsCurrent: pointsCurrentValue,
            pointsRequired: pointsRequiredValue,
            boardDate: draft.hasBoardDate ? draft.boardDate : nil,
            notes: draft.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : draft.notes.trimmingCharacters(in: .whitespacesAndNewlines),
            updatedAt: Date()
        )

        do {
            try await promotionService.savePromotion(promotion)
            promotionId = promotion.id
            if ReminderPreferences.boardReminderEnabled(),
               let boardDate = promotion.boardDate {
                let granted = try await reminderService.requestAuthorization()
                if granted {
                    try await reminderService.scheduleBoardDateReminders(
                        promotionID: promotion.id,
                        targetRank: promotion.targetRank,
                        boardDate: boardDate
                    )
                }
            } else {
                try? await reminderService.removeBoardDateReminders(promotionID: promotion.id)
            }

            successMessage = "Promotion tracker saved."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deletePromotion() async {
        guard let promotionId else { return }

        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer { isLoading = false }

        do {
            try await promotionService.deletePromotion(id: promotionId)
            try? await reminderService.removeBoardDateReminders(promotionID: promotionId)
            self.promotionId = nil
            draft = PromotionDraft(currentRank: authVM.currentProfile?.rank ?? "")
            successMessage = "Promotion tracker deleted."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func validateDraft() -> Bool {
        if draft.currentRank.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Current rank is required."
            return false
        }

        if draft.targetRank.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Target rank is required."
            return false
        }

        guard Int(draft.pointsCurrent) != nil else {
            errorMessage = "Current points must be a whole number."
            return false
        }

        guard Int(draft.pointsRequired) != nil, pointsRequiredValue > 0 else {
            errorMessage = "Points required must be greater than zero."
            return false
        }

        return true
    }
}

private struct PromotionBarPoint: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let color: Color
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
