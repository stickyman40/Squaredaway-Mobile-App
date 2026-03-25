import Charts
import SwiftUI

struct PayView: View {
    @EnvironmentObject private var authVM: AuthViewModel

    @State private var draft = PayDraft()
    @State private var payDataId: UUID?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var didLoad = false

    private let payService = PayService.shared

    var body: some View {
        ZStack {
            AppTheme.Colors.backgroundPrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    summaryCard
                    chartCard
                    payDetailsCard
                    saveSection
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.lg)
            }
        }
        .navigationTitle("Pay")
        .task {
            guard !didLoad else { return }
            didLoad = true
            await loadPayData()
        }
    }

    private var summaryCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Compensation Snapshot")
                            .font(AppTheme.Typography.titleMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        Text("Track monthly base pay, BAH, and BAS in one place.")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "dollarsign.circle")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.accentSecondary)
                }

                HStack(spacing: AppTheme.Spacing.md) {
                    PayMetric(title: "Grade", value: draft.payGrade.isEmpty ? "--" : draft.payGrade)
                    PayMetric(title: "Monthly Total", value: currency(totalMonthlyPay))
                    PayMetric(title: "Base Pay", value: currency(basePayValue))
                }
            }
        }
    }

    private var payDetailsCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(spacing: AppTheme.Spacing.md) {
                AuthTextField(
                    placeholder: "Pay grade",
                    icon: "chevron.up.square.fill",
                    text: $draft.payGrade,
                    autocapitalization: .characters
                )

                HStack(spacing: AppTheme.Spacing.md) {
                    AuthTextField(
                        placeholder: "Base pay",
                        icon: "dollarsign",
                        text: $draft.basePay,
                        keyboardType: .decimalPad
                    )

                    AuthTextField(
                        placeholder: "BAH",
                        icon: "house.fill",
                        text: $draft.bah,
                        keyboardType: .decimalPad
                    )
                }

                AuthTextField(
                    placeholder: "BAS",
                    icon: "fork.knife.circle.fill",
                    text: $draft.bas,
                    keyboardType: .decimalPad
                )

                HStack(spacing: AppTheme.Spacing.md) {
                    BreakdownRow(title: "Base pay", value: currency(basePayValue))
                    BreakdownRow(title: "BAH", value: currency(bahValue))
                    BreakdownRow(title: "BAS", value: currency(basValue))
                }

                BreakdownHighlight(title: "Estimated monthly total", value: currency(totalMonthlyPay))
            }
        }
    }

    private var chartCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("Monthly Breakdown")
                    .font(AppTheme.Typography.titleMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                if payChartPoints.allSatisfy({ $0.value == 0 }) {
                    Text("Enter pay values to see the compensation chart.")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                } else {
                    Chart(payChartPoints) { point in
                        BarMark(
                            x: .value("Component", point.label),
                            y: .value("Amount", point.value)
                        )
                        .foregroundStyle(point.color.gradient)
                        .annotation(position: .top) {
                            Text(currency(point.value))
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
                PayStatusBanner(message: errorMessage, color: AppTheme.Colors.error, icon: "exclamationmark.triangle.fill")
            }

            if let successMessage {
                PayStatusBanner(message: successMessage, color: AppTheme.Colors.success, icon: "checkmark.circle.fill")
            }

            PrimaryButton("Save Pay Details", isLoading: isLoading) {
                Task { await savePayData() }
            }

            if payDataId != nil {
                Button(role: .destructive) {
                    Task { await deletePayData() }
                } label: {
                    Text("Delete Pay Details")
                        .font(AppTheme.Typography.bodySmall)
                }
            }
        }
    }

    private var basePayValue: Double {
        Double(draft.basePay) ?? 0
    }

    private var bahValue: Double {
        Double(draft.bah) ?? 0
    }

    private var basValue: Double {
        Double(draft.bas) ?? 0
    }

    private var totalMonthlyPay: Double {
        basePayValue + bahValue + basValue
    }

    private var payChartPoints: [PayChartPoint] {
        [
            PayChartPoint(label: "Base", value: basePayValue, color: AppTheme.Colors.accentSecondary),
            PayChartPoint(label: "BAH", value: bahValue, color: AppTheme.Colors.success),
            PayChartPoint(label: "BAS", value: basValue, color: AppTheme.Colors.warning)
        ]
    }

    private func loadPayData() async {
        guard let userId = authVM.currentUserId else { return }

        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer { isLoading = false }

        do {
            let payData = try await payService.fetchPayData(userId: userId)
            if let payData {
                payDataId = payData.id
                draft = PayDraft(
                    payGrade: payData.payGrade,
                    basePay: decimalString(payData.basePay),
                    bah: decimalString(payData.bah),
                    bas: decimalString(payData.bas)
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func savePayData() async {
        guard validateDraft() else { return }
        guard let userId = authVM.currentUserId else {
            errorMessage = "Session unavailable. Please sign in again."
            return
        }

        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer { isLoading = false }

        let payData = PayData(
            id: payDataId ?? UUID(),
            userId: userId,
            payGrade: draft.payGrade.trimmingCharacters(in: .whitespacesAndNewlines),
            basePay: basePayValue,
            bah: bahValue,
            bas: basValue,
            updatedAt: Date()
        )

        do {
            try await payService.savePayData(payData)
            payDataId = payData.id
            successMessage = "Pay details saved."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deletePayData() async {
        guard let payDataId else { return }

        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer { isLoading = false }

        do {
            try await payService.deletePayData(id: payDataId)
            self.payDataId = nil
            draft = PayDraft()
            successMessage = "Pay details deleted."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func validateDraft() -> Bool {
        if draft.payGrade.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Pay grade is required."
            return false
        }

        guard Double(draft.basePay) != nil, basePayValue >= 0 else {
            errorMessage = "Base pay must be numeric."
            return false
        }

        guard Double(draft.bah) != nil, bahValue >= 0 else {
            errorMessage = "BAH must be numeric."
            return false
        }

        guard Double(draft.bas) != nil, basValue >= 0 else {
            errorMessage = "BAS must be numeric."
            return false
        }

        return true
    }

    private func currency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    private func decimalString(_ value: Double) -> String {
        if value.rounded() == value {
            return "\(Int(value))"
        }
        return String(format: "%.2f", value)
    }
}

private struct PayChartPoint: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let color: Color
}

private struct PayMetric: View {
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
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.sm)
        .background(AppTheme.Colors.backgroundElevated)
        .cornerRadius(AppTheme.Radius.md)
    }
}

private struct BreakdownRow: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.textTertiary)
            Text(value)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct BreakdownHighlight: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.textTertiary)
            Text(value)
                .font(AppTheme.Typography.displayMedium)
                .foregroundColor(AppTheme.Colors.accentSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
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

private struct PayStatusBanner: View {
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
        PayView()
            .environmentObject(AuthViewModel())
            .preferredColorScheme(.dark)
    }
}
