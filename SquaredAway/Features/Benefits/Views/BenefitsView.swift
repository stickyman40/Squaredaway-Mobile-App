import Charts
import SwiftUI

struct BenefitsView: View {
    @EnvironmentObject private var authVM: AuthViewModel

    @State private var draft = BenefitsDraft()
    @State private var benefitsId: UUID?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var didLoad = false

    private let benefitsService = BenefitsService.shared

    var body: some View {
        ZStack {
            AppTheme.Colors.backgroundPrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    summaryCard
                    checklistCard
                    readinessChartCard
                    notesCard
                    saveSection
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.lg)
            }
        }
        .navigationTitle("Benefits")
        .task {
            guard !didLoad else { return }
            didLoad = true
            await loadBenefits()
        }
    }

    private var summaryCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Benefits Readiness")
                            .font(AppTheme.Typography.titleMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        Text("Track the core programs you want squared away across health, education, retirement, and family support.")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }

                    Spacer()

                    Image("DashboardBenefits")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md))
                }

                Text("\(completedBenefitsCount) of 4 benefits marked ready")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }

    private var checklistCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("Coverage Checklist")
                    .font(AppTheme.Typography.titleMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                CheckboxRow(label: "VA health enrollment handled", isChecked: $draft.vaHealthEnrolled)
                CheckboxRow(label: "GI Bill / education benefit ready", isChecked: $draft.giBillReady)
                CheckboxRow(label: "TSP contributions active", isChecked: $draft.tspContributing)
                CheckboxRow(label: "Family support plan prepared", isChecked: $draft.familySupportPlan)
            }
        }
    }

    private var notesCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("Notes")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textTertiary)

                TextEditor(text: $draft.notes)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 180)
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

    private var readinessChartCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack {
                    Text("Coverage Progress")
                        .font(AppTheme.Typography.titleMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    Spacer()
                    Text("\(completedBenefitsCount)/4 ready")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }

                if benefitItems.allSatisfy({ !$0.isComplete }) {
                    Text("Mark benefits as you set them up to build a readiness snapshot.")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                } else {
                    Chart(benefitItems) { item in
                        BarMark(
                            x: .value("Benefit", item.title),
                            y: .value("Ready", item.isComplete ? 1 : 0)
                        )
                        .foregroundStyle(item.isComplete ? AppTheme.Colors.success.gradient : AppTheme.Colors.glassBorder.gradient)
                        .annotation(position: .top) {
                            Image(systemName: item.isComplete ? "checkmark.circle.fill" : "circle")
                                .font(.caption)
                                .foregroundColor(item.isComplete ? AppTheme.Colors.success : AppTheme.Colors.textTertiary)
                        }
                    }
                    .chartYScale(domain: 0...1)
                    .chartYAxis(.hidden)
                    .frame(height: 170)
                }

                Text(nextBenefitsFocus)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }

    private var saveSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            if let errorMessage {
                BenefitsStatusBanner(message: errorMessage, color: AppTheme.Colors.error, icon: "exclamationmark.triangle.fill")
            }

            if let successMessage {
                BenefitsStatusBanner(message: successMessage, color: AppTheme.Colors.success, icon: "checkmark.circle.fill")
            }

            PrimaryButton("Save Benefits", isLoading: isLoading) {
                Task { await saveBenefits() }
            }

            if benefitsId != nil {
                Button(role: .destructive) {
                    Task { await deleteBenefits() }
                } label: {
                    Text("Delete Benefits Snapshot")
                        .font(AppTheme.Typography.bodySmall)
                }
            }
        }
    }

    private var completedBenefitsCount: Int {
        [draft.vaHealthEnrolled, draft.giBillReady, draft.tspContributing, draft.familySupportPlan]
            .filter { $0 }
            .count
    }

    private var benefitItems: [BenefitProgressItem] {
        [
            BenefitProgressItem(title: "VA Health", isComplete: draft.vaHealthEnrolled),
            BenefitProgressItem(title: "GI Bill", isComplete: draft.giBillReady),
            BenefitProgressItem(title: "TSP", isComplete: draft.tspContributing),
            BenefitProgressItem(title: "Family Plan", isComplete: draft.familySupportPlan)
        ]
    }

    private var nextBenefitsFocus: String {
        if !draft.vaHealthEnrolled {
            return "Next focus: confirm health coverage or enrollment status."
        }
        if !draft.giBillReady {
            return "Next focus: verify GI Bill or education benefit readiness."
        }
        if !draft.tspContributing {
            return "Next focus: review retirement contributions."
        }
        if !draft.familySupportPlan {
            return "Next focus: finalize your family support plan."
        }
        return "All tracked benefits are marked ready."
    }

    private func loadBenefits() async {
        guard let userId = authVM.currentUserId else { return }

        do {
            if let benefits = try await benefitsService.fetchBenefits(userId: userId) {
                benefitsId = benefits.id
                draft = BenefitsDraft(
                    vaHealthEnrolled: benefits.vaHealthEnrolled,
                    giBillReady: benefits.giBillReady,
                    tspContributing: benefits.tspContributing,
                    familySupportPlan: benefits.familySupportPlan,
                    notes: benefits.notes ?? ""
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func saveBenefits() async {
        guard let userId = authVM.currentUserId else { return }

        isLoading = true
        defer { isLoading = false }

        errorMessage = nil
        successMessage = nil

        do {
            let trimmedNotes = draft.notes.trimmingCharacters(in: .whitespacesAndNewlines)
            let benefits = BenefitsData(
                id: benefitsId ?? UUID(),
                userId: userId,
                vaHealthEnrolled: draft.vaHealthEnrolled,
                giBillReady: draft.giBillReady,
                tspContributing: draft.tspContributing,
                familySupportPlan: draft.familySupportPlan,
                notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
                updatedAt: Date()
            )

            try await benefitsService.saveBenefits(benefits)
            benefitsId = benefits.id
            successMessage = "Benefits snapshot saved."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteBenefits() async {
        guard let benefitsId else { return }

        isLoading = true
        defer { isLoading = false }

        errorMessage = nil
        successMessage = nil

        do {
            try await benefitsService.deleteBenefits(id: benefitsId)
            self.benefitsId = nil
            draft = BenefitsDraft()
            successMessage = "Benefits snapshot deleted."
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct BenefitProgressItem: Identifiable {
    let id = UUID()
    let title: String
    let isComplete: Bool
}

private struct BenefitsStatusBanner: View {
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
