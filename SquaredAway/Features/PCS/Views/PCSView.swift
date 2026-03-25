import Charts
import SwiftUI

struct PCSView: View {
    @EnvironmentObject private var authVM: AuthViewModel

    @State private var draft = PCSDraft()
    @State private var pcsId: UUID?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var didLoad = false

    private let pcsService = PCSService.shared

    var body: some View {
        ZStack {
            AppTheme.Colors.backgroundPrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    summaryCard
                    checklistCard
                    logisticsCard
                    detailsCard
                    saveSection
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.lg)
            }
        }
        .navigationTitle("PCS")
        .task {
            guard !didLoad else { return }
            didLoad = true
            await loadPCS()
        }
    }

    private var summaryCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("PCS Planner")
                            .font(AppTheme.Typography.titleMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        Text("Capture your move route, date, and key logistics so the transition stays visible.")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }

                    Spacer()

                    Image("DashboardPCS")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md))
                }

                HStack(spacing: AppTheme.Spacing.md) {
                    PCSMetric(title: "Origin", value: metricValue(draft.originLocation, fallback: "Set origin"))
                    PCSMetric(title: "Destination", value: metricValue(draft.destinationLocation, fallback: "Set destination"))
                }
            }
        }
    }

    private var checklistCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack {
                    Text("Move Checklist")
                        .font(AppTheme.Typography.titleMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    Spacer()
                    Text("\(completedChecklistCount)/3 complete")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }

                CheckboxRow(label: "Shipment booked", isChecked: $draft.shipmentBooked)
                CheckboxRow(label: "Lodging secured", isChecked: $draft.lodgingSecured)
                CheckboxRow(label: "Travel booked", isChecked: $draft.travelBooked)

                if draft.hasMoveDate {
                    Text("Move date: \(formattedDate(draft.moveDate))")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
        }
    }

    private var detailsCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(spacing: AppTheme.Spacing.md) {
                AuthTextField(
                    placeholder: "Origin location",
                    icon: "airplane.departure",
                    text: $draft.originLocation
                )

                AuthTextField(
                    placeholder: "Destination location",
                    icon: "airplane.arrival",
                    text: $draft.destinationLocation
                )

                Toggle(isOn: $draft.hasMoveDate.animation()) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Track move date")
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        Text("Add the known PCS date once orders are locked.")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                }
                .tint(AppTheme.Colors.accentPrimary)

                if draft.hasMoveDate {
                    DatePicker(
                        "Move Date",
                        selection: $draft.moveDate,
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

    private var logisticsCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack {
                    Text("Move Readiness")
                        .font(AppTheme.Typography.titleMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    Spacer()
                    Text("\(completedMoveStepCount)/5 complete")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }

                if moveSteps.allSatisfy({ !$0.isComplete }) {
                    Text("Start with origin and destination, then mark your booked PCS logistics.")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                } else {
                    Chart(moveSteps) { step in
                        BarMark(
                            x: .value("Step", step.title),
                            y: .value("Complete", step.isComplete ? 1 : 0)
                        )
                        .foregroundStyle(step.isComplete ? AppTheme.Colors.accentSecondary.gradient : AppTheme.Colors.glassBorder.gradient)
                        .annotation(position: .top) {
                            Image(systemName: step.isComplete ? "checkmark.circle.fill" : "circle")
                                .font(.caption)
                                .foregroundColor(step.isComplete ? AppTheme.Colors.accentSecondary : AppTheme.Colors.textTertiary)
                        }
                    }
                    .chartYScale(domain: 0...1)
                    .chartYAxis(.hidden)
                    .frame(height: 170)
                }

                Text(moveDateStatusText)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }

    private var saveSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            if let errorMessage {
                PCSStatusBanner(message: errorMessage, color: AppTheme.Colors.error, icon: "exclamationmark.triangle.fill")
            }

            if let successMessage {
                PCSStatusBanner(message: successMessage, color: AppTheme.Colors.success, icon: "checkmark.circle.fill")
            }

            PrimaryButton("Save PCS Plan", isLoading: isLoading) {
                Task { await savePCS() }
            }

            if pcsId != nil {
                Button(role: .destructive) {
                    Task { await deletePCS() }
                } label: {
                    Text("Delete PCS Plan")
                        .font(AppTheme.Typography.bodySmall)
                }
            }
        }
    }

    private var completedChecklistCount: Int {
        [draft.shipmentBooked, draft.lodgingSecured, draft.travelBooked]
            .filter { $0 }
            .count
    }

    private var moveSteps: [PCSMoveStep] {
        [
            PCSMoveStep(title: "Origin", isComplete: !draft.originLocation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty),
            PCSMoveStep(title: "Destination", isComplete: !draft.destinationLocation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty),
            PCSMoveStep(title: "Shipment", isComplete: draft.shipmentBooked),
            PCSMoveStep(title: "Lodging", isComplete: draft.lodgingSecured),
            PCSMoveStep(title: "Travel", isComplete: draft.travelBooked)
        ]
    }

    private var completedMoveStepCount: Int {
        moveSteps.filter(\.isComplete).count
    }

    private var moveDateStatusText: String {
        guard draft.hasMoveDate else {
            return "Move date not locked yet."
        }

        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: Calendar.current.startOfDay(for: draft.moveDate)).day ?? 0
        if days > 0 {
            return "\(days) day\(days == 1 ? "" : "s") until your planned move."
        }
        if days == 0 {
            return "Move day is today."
        }
        return "Move date passed \(abs(days)) day\(abs(days) == 1 ? "" : "s") ago."
    }

    private func loadPCS() async {
        guard let userId = authVM.currentUserId else { return }

        do {
            if let pcs = try await pcsService.fetchPCS(userId: userId) {
                pcsId = pcs.id
                draft = PCSDraft(
                    originLocation: pcs.originLocation,
                    destinationLocation: pcs.destinationLocation,
                    hasMoveDate: pcs.moveDate != nil,
                    moveDate: pcs.moveDate ?? Date(),
                    shipmentBooked: pcs.shipmentBooked,
                    lodgingSecured: pcs.lodgingSecured,
                    travelBooked: pcs.travelBooked,
                    notes: pcs.notes ?? ""
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func savePCS() async {
        guard let userId = authVM.currentUserId else { return }

        isLoading = true
        defer { isLoading = false }

        errorMessage = nil
        successMessage = nil

        do {
            let trimmedNotes = draft.notes.trimmingCharacters(in: .whitespacesAndNewlines)
            let pcs = PCSData(
                id: pcsId ?? UUID(),
                userId: userId,
                originLocation: draft.originLocation.trimmingCharacters(in: .whitespacesAndNewlines),
                destinationLocation: draft.destinationLocation.trimmingCharacters(in: .whitespacesAndNewlines),
                moveDate: draft.hasMoveDate ? draft.moveDate : nil,
                shipmentBooked: draft.shipmentBooked,
                lodgingSecured: draft.lodgingSecured,
                travelBooked: draft.travelBooked,
                notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
                updatedAt: Date()
            )

            try await pcsService.savePCS(pcs)
            pcsId = pcs.id
            successMessage = "PCS plan saved."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deletePCS() async {
        guard let pcsId else { return }

        isLoading = true
        defer { isLoading = false }

        errorMessage = nil
        successMessage = nil

        do {
            try await pcsService.deletePCS(id: pcsId)
            self.pcsId = nil
            draft = PCSDraft()
            successMessage = "PCS plan deleted."
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

private struct PCSMetric: View {
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

private struct PCSMoveStep: Identifiable {
    let id = UUID()
    let title: String
    let isComplete: Bool
}

private struct PCSStatusBanner: View {
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
