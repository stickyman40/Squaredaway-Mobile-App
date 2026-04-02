import Foundation
import SwiftUI

@MainActor
final class PromotionsViewModel: ObservableObject {
    enum PromotionTab: String, CaseIterable {
        case overview = "Overview"
        case calculator = "Calculator"
        case roadmap = "Roadmap"
        case improve = "Improve"

        var icon: String {
            switch self {
            case .overview:
                return "chart.pie.fill"
            case .calculator:
                return "slider.horizontal.3"
            case .roadmap:
                return "map.fill"
            case .improve:
                return "arrow.up.circle.fill"
            }
        }
    }

    @Published var branchConfig = BranchPromotionConfig.config(for: .army) {
        didSet {
            if !branchConfig.ranks.contains(where: { $0.id == selectedTargetRank?.id }) {
                selectedTargetRank = branchConfig.ranks.first
            }
        }
    }
    @Published var record = PromotionData.empty(userId: UUID(), branch: .army)
    @Published var selectedTargetRank: PromotionRank?
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var saveSuccess = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published private(set) var configuredForExistingRecord = false
    @Published var activeTab: PromotionTab = .overview

    private let promotionService = PromotionService.shared
    private let reminderService = ReminderService.shared
    private var configuredUserID: UUID?

    var config: BranchPromotionConfig { branchConfig }

    func configure(branch: MilitaryBranch, userId: UUID, currentRank: String) async {
        guard configuredUserID != userId || branchConfig.branch != branch else { return }

        configuredUserID = userId
        branchConfig = BranchPromotionConfig.config(for: branch)
        selectedTargetRank = branchConfig.ranks.first

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            if let loaded = try await promotionService.fetchPromotion(userId: userId) {
                record = loaded
                configuredForExistingRecord = true
            } else {
                configuredForExistingRecord = false
                record = PromotionData.empty(userId: userId, branch: branch, currentPayGrade: currentRank)
            }

            if record.branch != branch {
                record.branch = branch
            }
            if record.currentPayGrade.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                record.currentPayGrade = currentRank
            }

            selectedTargetRank = branchConfig.ranks.first(where: { $0.payGrade == record.targetPayGrade }) ?? branchConfig.ranks.first
            if record.targetPayGrade.isEmpty {
                record.targetPayGrade = selectedTargetRank?.payGrade ?? ""
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var totalScore: Int {
        PromotionScoring.totalScore(for: record, branch: branchConfig.branch, targetPayGrade: selectedTargetRank?.payGrade ?? record.targetPayGrade)
    }

    var computedTotalScore: Int { totalScore }

    var maxScore: Int {
        PromotionScoring.maxScore(for: record, branch: branchConfig.branch, targetPayGrade: selectedTargetRank?.payGrade ?? record.targetPayGrade)
    }

    var maxPossibleScore: Int { maxScore }

    var scoreProgress: Double {
        guard maxScore > 0 else { return 0 }
        return min(1.0, Double(totalScore) / Double(maxScore))
    }

    var activeComponents: [ScoreComponent] {
        PromotionScoring.components(for: record, branch: branchConfig.branch, targetPayGrade: selectedTargetRank?.payGrade ?? record.targetPayGrade)
    }

    var cutoffScore: Int? {
        PromotionScoring.cutoffScore(for: record, branch: branchConfig.branch)
    }

    var cutoffLabel: String {
        PromotionScoring.cutoffLabel(for: branchConfig.branch)
    }

    var isAboveCutoff: Bool? {
        guard let cutoffScore else { return nil }
        return totalScore >= cutoffScore
    }

    var isBoardSelected: Bool {
        selectedTargetRank?.isBoardSelected ?? false
    }

    var scoreLabel: String {
        switch branchConfig.branch {
        case .army:
            return "Promotion Points"
        case .airForce, .spaceForce:
            return "WAPS Score"
        case .navy:
            return "Final Multiple Score"
        case .marines:
            return "Composite Score"
        case .coastGuard:
            return "Final Exam Score"
        }
    }

    var statusLabel: String {
        if isBoardSelected {
            return "Board Selected"
        }
        guard let cutoff = cutoffScore else {
            return "Enter your scores"
        }
        let gap = cutoff - totalScore
        if gap <= 0 {
            return "Above cutoff"
        }
        if gap <= 20 {
            return "\(gap) pts to cutoff"
        }
        return "\(gap) pts needed"
    }

    var statusColor: Color {
        if isBoardSelected {
            return Color(hex: "#A29BFE")
        }
        guard let cutoff = cutoffScore else {
            return AppTheme.Colors.textTertiary
        }
        return totalScore >= cutoff ? AppTheme.Colors.success : AppTheme.Colors.warning
    }

    var missingTISMonths: Int {
        guard let rank = selectedTargetRank else { return 0 }
        return max(0, rank.minTISMonths - record.monthsInService)
    }

    var missingTIGMonths: Int {
        guard let rank = selectedTargetRank else { return 0 }
        return max(0, rank.minTIGMonths - record.monthsInGrade)
    }

    var promotionReadinessPercent: Double {
        guard let rank = selectedTargetRank else { return 0 }
        var factors: [Double] = [
            rank.minTISMonths > 0 ? min(1.0, Double(record.monthsInService) / Double(rank.minTISMonths)) : 1,
            rank.minTIGMonths > 0 ? min(1.0, Double(record.monthsInGrade) / Double(rank.minTIGMonths)) : 1
        ]
        if !isBoardSelected {
            factors.append(scoreProgress)
        }
        return factors.reduce(0, +) / Double(factors.count)
    }

    var currentRankDef: PromotionRank? {
        branchConfig.ranks.first { $0.payGrade == record.currentPayGrade }
    }

    var improvementActions: [ImprovementAction] {
        let gaps = activeComponents.sorted { $0.gapToMax > $1.gapToMax }
        return Array(gaps.prefix(5).filter { $0.gapToMax > 0 }.map(actionForComponent).prefix(4))
    }

    var armyBreakdown: [(label: String, current: Int, max: Int)] {
        activeComponents.map { ($0.name, Int($0.current.rounded()), Int($0.maximum.rounded())) }
    }

    var wapsBreakdown: [(label: String, current: Double, max: Double)] {
        activeComponents.map { ($0.name, $0.current, $0.maximum) }
    }

    var navyBreakdown: [(label: String, current: Double, max: Double)] {
        activeComponents.map { ($0.name, $0.current, $0.maximum) }
    }

    var marineBreakdown: [(label: String, current: Int, max: Int)] {
        activeComponents.map { ($0.name, Int($0.current.rounded()), Int($0.maximum.rounded())) }
    }

    var cgBreakdown: [(label: String, current: Double, max: Double)] {
        activeComponents.map { ($0.name, $0.current, $0.maximum) }
    }

    func save() async {
        isSaving = true
        errorMessage = nil
        successMessage = nil
        defer { isSaving = false }

        do {
            record.branch = branchConfig.branch
            record.targetPayGrade = selectedTargetRank?.payGrade ?? record.targetPayGrade
            record.updatedAt = Date()

            try await promotionService.savePromotion(record)
            configuredForExistingRecord = true

            if ReminderPreferences.boardReminderEnabled(), let boardDate = record.nextBoardDate {
                let granted = try await reminderService.requestAuthorization()
                if granted {
                    try await reminderService.scheduleBoardDateReminders(
                        promotionID: record.id,
                        targetRank: selectedTargetRank?.abbreviation ?? record.targetPayGrade,
                        boardDate: boardDate
                    )
                }
            }

            withAnimation(AppTheme.Animation.spring) {
                saveSuccess = true
            }
            successMessage = "Promotion tracker saved."
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            saveSuccess = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete() async {
        isSaving = true
        errorMessage = nil
        successMessage = nil
        defer { isSaving = false }

        do {
            try await promotionService.deletePromotion(id: record.id)
            await reminderService.removeAllBoardDateReminders()
            if let userId = configuredUserID {
                let currentPayGrade = record.currentPayGrade
                configuredForExistingRecord = false
                record = PromotionData.empty(userId: userId, branch: branchConfig.branch, currentPayGrade: currentPayGrade)
                selectedTargetRank = branchConfig.ranks.first
            }
            successMessage = "Promotion tracker deleted."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func actionForComponent(_ component: ScoreComponent) -> ImprovementAction {
        switch component.name {
        case "Military Education":
            return ImprovementAction(title: "Complete the next resident PME opportunity", detail: "Resident military education is one of the largest controllable Army point builders. If a course slot is available, prioritize it.", pointsGain: "Up to 78 pts", effort: .medium, timeframe: "1-6 months", category: .education, link: "https://www.hrc.army.mil")
        case "Civilian Education":
            return ImprovementAction(title: "Keep building civilian education", detail: "Civilian education compounds over time and can meaningfully shrink a cutoff gap.", pointsGain: "Up to 100 pts", effort: .high, timeframe: "1-24 months", category: .education, link: nil)
        case "Awards":
            return ImprovementAction(title: "Audit missing awards and recognition", detail: "Awards are often earned but not fully reflected. Make sure every approved item is on your record.", pointsGain: "Up to 40 pts", effort: .low, timeframe: "1-4 weeks", category: .awards, link: nil)
        case "Military Training":
            return ImprovementAction(title: "Target a training-based points jump", detail: "ASI, DLPT, and MOS-related training can add meaningful points faster than waiting on time-based categories.", pointsGain: "Up to 20 pts", effort: .medium, timeframe: "1-6 months", category: .training, link: nil)
        case "AFT Score", "PFT Score", "CFT Score":
            return ImprovementAction(title: "Train the exact scored events", detail: component.tip, pointsGain: "High potential", effort: .medium, timeframe: "6-12 weeks", category: .fitness, link: nil)
        case "Weapons Qual", "Rifle Qual":
            return ImprovementAction(title: "Prepare early for the next qualification", detail: component.tip, pointsGain: "Fast fixed gain", effort: .low, timeframe: "1-4 weeks", category: .fitness, link: nil)
        case "SKT", "PFE", "Advancement Exam", "SWE Raw Score":
            return ImprovementAction(title: "Run a focused study block", detail: component.tip, pointsGain: "Large cycle gain", effort: .medium, timeframe: "4-10 weeks", category: .testing, link: nil)
        case "EPR Rating", "PMA (EVALs)", "PRO Marks", "CON Marks", "Performance Factor":
            return ImprovementAction(title: "Improve the next evaluation cycle", detail: component.tip, pointsGain: "Long-term leverage", effort: .high, timeframe: "Next eval cycle", category: .leadership, link: nil)
        case "AFADCONS", "MCI Credits":
            return ImprovementAction(title: "Capture smaller monthly wins", detail: component.tip, pointsGain: "Steady gain", effort: .low, timeframe: "Ongoing", category: .education, link: nil)
        case "SIPG Bonus", "PNA Points", "TIS + TIG":
            return ImprovementAction(title: "Focus on controllable categories first", detail: component.tip, pointsGain: "Supportive category", effort: .low, timeframe: "Ongoing", category: .time, link: nil)
        default:
            return ImprovementAction(title: "Improve \(component.name)", detail: component.tip, pointsGain: "Up to \(Int(component.gapToMax.rounded())) pts", effort: .medium, timeframe: "Varies", category: .training, link: nil)
        }
    }
}
