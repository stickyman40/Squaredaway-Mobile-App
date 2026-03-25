import Charts
import SwiftUI

struct TrackerView: View {
    @EnvironmentObject private var authVM: AuthViewModel

    @State private var draft = TrackerDraft()
    @State private var trackerId: UUID?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var didLoad = false

    private let trackerService = TrackerService.shared

    var body: some View {
        ZStack {
            AppTheme.Colors.backgroundPrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    summaryCard
                    readinessCard
                    progressCard
                    detailsCard
                    saveSection
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.lg)
            }
        }
        .navigationTitle("Tracker")
        .task {
            guard !didLoad else { return }
            didLoad = true
            await loadTracker()
        }
    }

    private var summaryCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Assignment Tracker")
                            .font(AppTheme.Typography.titleMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        Text("Keep your current duty station, status, and next milestone visible in one place.")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }

                    Spacer()

                    Image("DashboardTracker")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md))
                }

                HStack(spacing: AppTheme.Spacing.md) {
                    TrackerMetric(title: "Duty Station", value: metricValue(draft.currentDutyStation, fallback: "Add location"))
                    TrackerMetric(title: "Status", value: metricValue(draft.dutyStatus, fallback: "Add status"))
                }
            }
        }
    }

    private var readinessCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack {
                    Text("Mission Pulse")
                        .font(AppTheme.Typography.titleMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    Spacer()
                    Text(readinessLabel)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(readinessColor)
                }

                Text(metricValue(draft.nextMilestone, fallback: "Set your next milestone to keep this tracker useful."))
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)

                if draft.hasReportDate {
                    Text("Report date: \(formattedDate(draft.reportDate))")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
            }
        }
    }

    private var detailsCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(spacing: AppTheme.Spacing.md) {
                AuthTextField(
                    placeholder: "Current duty station",
                    icon: "mappin.and.ellipse",
                    text: $draft.currentDutyStation,
                    autocapitalization: .words,
                    autocorrectionDisabled: false
                )

                AuthTextField(
                    placeholder: "Duty status",
                    icon: "person.text.rectangle",
                    text: $draft.dutyStatus,
                    autocapitalization: .words,
                    autocorrectionDisabled: false
                )

                AuthTextField(
                    placeholder: "Next milestone",
                    icon: "flag.checkered",
                    text: $draft.nextMilestone,
                    autocapitalization: .sentences,
                    autocorrectionDisabled: false
                )

                Toggle(isOn: $draft.hasReportDate.animation()) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Track report date")
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        Text("Use this when you already have a hard date to work toward.")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                }
                .tint(AppTheme.Colors.accentPrimary)

                if draft.hasReportDate {
                    DatePicker(
                        "Report Date",
                        selection: $draft.reportDate,
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

    private var progressCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack {
                    Text("Readiness Progress")
                        .font(AppTheme.Typography.titleMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    Spacer()
                    Text("\(completedCheckpointCount)/4 complete")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }

                if missionCheckpoints.allSatisfy({ !$0.isComplete }) {
                    Text("Add assignment details to see mission progress.")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                } else {
                    Chart(missionCheckpoints) { checkpoint in
                        BarMark(
                            x: .value("Checkpoint", checkpoint.title),
                            y: .value("Complete", checkpoint.isComplete ? 1 : 0)
                        )
                        .foregroundStyle(checkpoint.isComplete ? AppTheme.Colors.success.gradient : AppTheme.Colors.glassBorder.gradient)
                        .annotation(position: .top) {
                            Image(systemName: checkpoint.isComplete ? "checkmark.circle.fill" : "circle")
                                .font(.caption)
                                .foregroundColor(checkpoint.isComplete ? AppTheme.Colors.success : AppTheme.Colors.textTertiary)
                        }
                    }
                    .chartYScale(domain: 0...1)
                    .chartYAxis(.hidden)
                    .frame(height: 170)
                }

                Text(reportDateStatusText)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }

    private var saveSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            if let errorMessage {
                TrackerStatusBanner(message: errorMessage, color: AppTheme.Colors.error, icon: "exclamationmark.triangle.fill")
            }

            if let successMessage {
                TrackerStatusBanner(message: successMessage, color: AppTheme.Colors.success, icon: "checkmark.circle.fill")
            }

            PrimaryButton("Save Tracker", isLoading: isLoading) {
                Task { await saveTracker() }
            }

            if trackerId != nil {
                Button(role: .destructive) {
                    Task { await deleteTracker() }
                } label: {
                    Text("Delete Tracker")
                        .font(AppTheme.Typography.bodySmall)
                }
            }
        }
    }

    private var readinessLabel: String {
        if draft.currentDutyStation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Needs setup"
        }
        if draft.nextMilestone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "In progress"
        }
        return "On track"
    }

    private var readinessColor: Color {
        switch readinessLabel {
        case "On track":
            return AppTheme.Colors.success
        case "In progress":
            return AppTheme.Colors.warning
        default:
            return AppTheme.Colors.textTertiary
        }
    }

    private var missionCheckpoints: [TrackerCheckpoint] {
        [
            TrackerCheckpoint(title: "Station", isComplete: !draft.currentDutyStation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty),
            TrackerCheckpoint(title: "Status", isComplete: !draft.dutyStatus.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty),
            TrackerCheckpoint(title: "Milestone", isComplete: !draft.nextMilestone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty),
            TrackerCheckpoint(title: "Report Date", isComplete: draft.hasReportDate)
        ]
    }

    private var completedCheckpointCount: Int {
        missionCheckpoints.filter(\.isComplete).count
    }

    private var reportDateStatusText: String {
        guard draft.hasReportDate else {
            return "No report date set yet."
        }

        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: Calendar.current.startOfDay(for: draft.reportDate)).day ?? 0
        if days > 0 {
            return "\(days) day\(days == 1 ? "" : "s") until report date."
        }
        if days == 0 {
            return "Report date is today."
        }
        return "Report date passed \(abs(days)) day\(abs(days) == 1 ? "" : "s") ago."
    }

    private func loadTracker() async {
        guard let userId = authVM.currentUserId else { return }

        do {
            if let tracker = try await trackerService.fetchTracker(userId: userId) {
                trackerId = tracker.id
                draft = TrackerDraft(
                    currentDutyStation: tracker.currentDutyStation,
                    dutyStatus: tracker.dutyStatus,
                    nextMilestone: tracker.nextMilestone,
                    hasReportDate: tracker.reportDate != nil,
                    reportDate: tracker.reportDate ?? Date(),
                    notes: tracker.notes ?? ""
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func saveTracker() async {
        guard let userId = authVM.currentUserId else { return }

        isLoading = true
        defer { isLoading = false }

        errorMessage = nil
        successMessage = nil

        do {
            let tracker = TrackerData(
                id: trackerId ?? UUID(),
                userId: userId,
                currentDutyStation: draft.currentDutyStation.trimmingCharacters(in: .whitespacesAndNewlines),
                dutyStatus: draft.dutyStatus.trimmingCharacters(in: .whitespacesAndNewlines),
                nextMilestone: draft.nextMilestone.trimmingCharacters(in: .whitespacesAndNewlines),
                reportDate: draft.hasReportDate ? draft.reportDate : nil,
                notes: draft.notes.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
                updatedAt: Date()
            )

            try await trackerService.saveTracker(tracker)
            trackerId = tracker.id
            successMessage = "Tracker saved."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteTracker() async {
        guard let trackerId else { return }

        isLoading = true
        defer { isLoading = false }

        errorMessage = nil
        successMessage = nil

        do {
            try await trackerService.deleteTracker(id: trackerId)
            self.trackerId = nil
            draft = TrackerDraft()
            successMessage = "Tracker deleted."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func metricValue(_ value: String, fallback: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : trimmed
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

private struct TrackerMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.textTertiary)
            Text(value)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.sm)
        .background(AppTheme.Colors.backgroundElevated)
        .cornerRadius(AppTheme.Radius.md)
    }
}

private struct TrackerCheckpoint: Identifiable {
    let id = UUID()
    let title: String
    let isComplete: Bool
}

private struct TrackerStatusBanner: View {
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

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
