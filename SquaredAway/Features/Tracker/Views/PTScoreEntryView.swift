import SwiftUI

// MARK: - PTScoreEntryView
// Dynamically renders the correct event inputs for the user's branch.
// Army gets AFT events. Air Force gets PFA events. Marines get PFT. Etc.
// No cross-branch data ever appears.

struct PTScoreEntryView: View {
    let config: BranchPTConfig
    let userId: UUID
    let onSave: (PTScoreRecord) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var eventValues: [String: String] = [:]
    @State private var notes: String = ""
    @State private var isSaving: Bool = false
    @State private var saveSuccess: Bool = false

    private var totalScore: Int {
        config.events.reduce(0) { total, event in
            let raw = Double(eventValues[event.name] ?? "") ?? 0
            // Handle time format mm:ss for run events
            let actualRaw: Double
            if event.unit == "secs", let val = eventValues[event.name] {
                actualRaw = parseTimeInput(val)
            } else {
                actualRaw = Double(eventValues[event.name] ?? "") ?? 0
            }
            return total + event.score(for: actualRaw)
        }
    }

    private var passed: Bool { totalScore >= config.passingScore }
    private var currentTier: PTTier? { PTTier.tier(for: totalScore, tiers: config.tiers) }
    private var scoreProgress: Double { Double(totalScore) / Double(config.maxScore) }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.backgroundPrimary.ignoresSafeArea()

                if saveSuccess {
                    SaveSuccessView(config: config, score: totalScore, tier: currentTier) { dismiss() }
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: AppTheme.Spacing.lg) {

                            // ── Live Score Card ──────────────────
                            LiveScoreCard(
                                config: config,
                                totalScore: totalScore,
                                scoreProgress: scoreProgress,
                                passed: passed,
                                tier: currentTier
                            ).padding(.horizontal, AppTheme.Spacing.md)

                            // ── Event Inputs ─────────────────────
                            GlassCard(padding: AppTheme.Spacing.lg) {
                                VStack(spacing: AppTheme.Spacing.lg) {
                                    Text("Log Your Scores")
                                        .font(AppTheme.Typography.titleSmall).foregroundColor(AppTheme.Colors.textPrimary).frame(maxWidth: .infinity, alignment: .leading)

                                    ForEach(config.events) { event in
                                        EventInputRow(
                                            event: event,
                                            value: Binding(
                                                get: { eventValues[event.name] ?? "" },
                                                set: { eventValues[event.name] = $0 }
                                            )
                                        )
                                    }
                                }
                            }.padding(.horizontal, AppTheme.Spacing.md)

                            // ── Notes ────────────────────────────
                            GlassCard(padding: AppTheme.Spacing.md) {
                                HStack {
                                    Image(systemName: "note.text").foregroundColor(AppTheme.Colors.textTertiary)
                                    TextField("Notes (optional)", text: $notes)
                                        .font(AppTheme.Typography.bodyMedium).foregroundColor(AppTheme.Colors.textPrimary)
                                }
                            }.padding(.horizontal, AppTheme.Spacing.md)

                            // ── Tiers reference ──────────────────
                            TiersReferenceCard(config: config)
                                .padding(.horizontal, AppTheme.Spacing.md)

                            // ── Save button ──────────────────────
                            PrimaryButton("Save PT Score", isLoading: isSaving) {
                                Task { await saveScore() }
                            }.padding(.horizontal, AppTheme.Spacing.md)

                            Text("Scores are for self-tracking only. Official results must be validated through your chain of command.")
                                .font(.system(size: 10)).foregroundColor(AppTheme.Colors.textTertiary).multilineTextAlignment(.center).padding(.horizontal, AppTheme.Spacing.xl)

                            Spacer(minLength: AppTheme.Spacing.xxl)
                        }.padding(.top, AppTheme.Spacing.md)
                    }
                }
            }
            .navigationTitle(config.testName.components(separatedBy: "(").first?.trimmingCharacters(in: .whitespaces) ?? "PT Score")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: { Image(systemName: "xmark").foregroundColor(AppTheme.Colors.textSecondary) }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func saveScore() async {
        isSaving = true
        defer { isSaving = false }

        var scores: [String: Double] = [:]
        for event in config.events {
            let val = eventValues[event.name] ?? ""
            if event.unit == "secs" {
                scores[event.name] = parseTimeInput(val)
            } else {
                scores[event.name] = Double(val) ?? 0
            }
        }

        let record = PTScoreRecord(
            id: UUID(), userId: userId,
            branch: config.branch.rawValue,
            testName: config.testName,
            eventScores: scores,
            totalScore: totalScore,
            passed: passed,
            tierName: currentTier?.name,
            notes: notes.isEmpty ? nil : notes,
            recordedAt: Date()
        )

        do {
            try await PTService.shared.savePTScore(record)
            onSave(record)
            withAnimation(AppTheme.Animation.spring) { saveSuccess = true }
        } catch {
            // Still call onSave with local record even if network fails
            onSave(record)
            withAnimation(AppTheme.Animation.spring) { saveSuccess = true }
        }
    }

    // Parse "mm:ss" → seconds
    private func parseTimeInput(_ input: String) -> Double {
        let parts = input.components(separatedBy: ":")
        if parts.count == 2, let mins = Double(parts[0]), let secs = Double(parts[1]) {
            return mins * 60 + secs
        }
        return Double(input) ?? 0
    }
}

// MARK: - Live Score Card
private struct LiveScoreCard: View {
    let config: BranchPTConfig
    let totalScore: Int
    let scoreProgress: Double
    let passed: Bool
    let tier: PTTier?

    var body: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            HStack(spacing: AppTheme.Spacing.xl) {
                // Score ring
                ZStack {
                    Circle().stroke(AppTheme.Colors.glassBorder, lineWidth: 8).frame(width: 80, height: 80)
                    Circle().trim(from: 0, to: scoreProgress)
                        .stroke(tier.map { Color(hex: $0.color) } ?? AppTheme.Colors.accentSecondary,
                                style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 80, height: 80).rotationEffect(.degrees(-90))
                        .animation(AppTheme.Animation.slow, value: scoreProgress)
                    VStack(spacing: 1) {
                        Text("\(totalScore)").font(.system(size: 22, weight: .bold, design: .rounded)).foregroundColor(AppTheme.Colors.textPrimary)
                        Text("/ \(config.maxScore)").font(.system(size: 9)).foregroundColor(AppTheme.Colors.textTertiary)
                    }
                }

                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    if let tier {
                        HStack(spacing: 6) {
                            Image(systemName: tier.badge).foregroundColor(Color(hex: tier.color))
                            Text(tier.name).font(AppTheme.Typography.titleMedium).foregroundColor(Color(hex: tier.color))
                        }
                    }
                    HStack(spacing: 4) {
                        Image(systemName: passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(passed ? AppTheme.Colors.success : AppTheme.Colors.error)
                        Text(passed ? "Passing" : "Not passing (need \(config.passingScore))")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(passed ? AppTheme.Colors.success : AppTheme.Colors.error)
                    }
                    // Next tier hint
                    if let next = config.tiers.filter({ $0.minScore > totalScore }).min(by: { $0.minScore < $1.minScore }) {
                        Text("\(next.minScore - totalScore) pts to \(next.name)")
                            .font(AppTheme.Typography.caption).foregroundColor(AppTheme.Colors.textTertiary)
                    }
                }
                Spacer()
            }
        }
    }
}

// MARK: - Event Input Row
private struct EventInputRow: View {
    let event: PTEvent
    @Binding var value: String

    private var pts: Int {
        let raw: Double
        if event.unit == "secs" {
            let parts = value.components(separatedBy: ":")
            if parts.count == 2, let m = Double(parts[0]), let s = Double(parts[1]) { raw = m * 60 + s }
            else { raw = Double(value) ?? 0 }
        } else { raw = Double(value) ?? 0 }
        return event.score(for: raw)
    }
    private var ptsPct: Double { Double(pts) / Double(event.pointsMax) }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: event.icon)
                    .font(.system(size: 13)).foregroundColor(AppTheme.Colors.accentSecondary)
                    .frame(width: 28, height: 28).background(AppTheme.Colors.accentPrimary.opacity(0.1)).cornerRadius(AppTheme.Radius.sm)

                VStack(alignment: .leading, spacing: 2) {
                    Text(event.name).font(AppTheme.Typography.bodyMedium).foregroundColor(AppTheme.Colors.textPrimary)
                    Text(event.description).font(AppTheme.Typography.caption).foregroundColor(AppTheme.Colors.textTertiary).lineLimit(2)
                }
                Spacer()

                // Input field
                TextField(event.unit == "secs" ? "mm:ss" : event.unit, text: $value)
                    .keyboardType(event.unit == "secs" ? .default : .decimalPad)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .frame(width: 72)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .background(AppTheme.Colors.backgroundElevated)
                    .cornerRadius(AppTheme.Radius.sm)
            }

            // Points bar
            if !value.isEmpty {
                HStack(spacing: AppTheme.Spacing.sm) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(AppTheme.Colors.glassBorder).frame(height: 4)
                            Capsule()
                                .fill(ptsPct >= 0.8 ? AppTheme.Colors.success : ptsPct >= 0.5 ? AppTheme.Colors.warning : AppTheme.Colors.error)
                                .frame(width: geo.size.width * ptsPct, height: 4)
                                .animation(AppTheme.Animation.standard, value: ptsPct)
                        }
                    }.frame(height: 4)
                    Text("\(pts)/\(event.pointsMax) pts").font(AppTheme.Typography.caption).foregroundColor(AppTheme.Colors.textTertiary).frame(width: 70, alignment: .trailing)
                }
                .transition(.opacity)
            }
        }
    }
}

// MARK: - Tiers Reference Card
private struct TiersReferenceCard: View {
    let config: BranchPTConfig
    var body: some View {
        GlassCard(padding: AppTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("Score Tiers").font(AppTheme.Typography.label).foregroundColor(AppTheme.Colors.textTertiary).textCase(.uppercase).tracking(1)
                ForEach(config.tiers.reversed()) { tier in
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: tier.badge).foregroundColor(Color(hex: tier.color))
                        Text(tier.name).font(AppTheme.Typography.bodySmall).foregroundColor(AppTheme.Colors.textPrimary)
                        Spacer()
                        Text("\(tier.minScore)+").font(AppTheme.Typography.bodySmall).foregroundColor(Color(hex: tier.color))
                    }
                }
            }
        }
    }
}

// MARK: - Save Success View
private struct SaveSuccessView: View {
    let config: BranchPTConfig; let score: Int; let tier: PTTier?; let onDone: () -> Void
    @State private var appeared = false
    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer()
            ZStack {
                Circle().fill(Color(hex: tier?.color ?? "#34C759").opacity(0.12)).frame(width: 120, height: 120)
                Image(systemName: tier?.badge ?? "checkmark.circle.fill")
                    .font(.system(size: 60)).foregroundColor(Color(hex: tier?.color ?? "#34C759"))
                    .scaleEffect(appeared ? 1 : 0.3).opacity(appeared ? 1 : 0)
            }
            VStack(spacing: AppTheme.Spacing.sm) {
                Text("Score Saved!").font(AppTheme.Typography.displayMedium).foregroundColor(AppTheme.Colors.textPrimary)
                Text("\(score) / \(config.maxScore) · \(tier?.name ?? "Logged")")
                    .font(AppTheme.Typography.titleSmall).foregroundColor(Color(hex: tier?.color ?? "#34C759"))
            }.opacity(appeared ? 1 : 0)
            PrimaryButton("Done") { onDone() }.padding(.horizontal, AppTheme.Spacing.xl)
            Spacer()
        }
        .onAppear { withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1)) { appeared = true } }
    }
}
