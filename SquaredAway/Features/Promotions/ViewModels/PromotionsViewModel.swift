import Foundation

@MainActor
final class PromotionsViewModel: ObservableObject {
    @Published var branchConfig = BranchPromotionConfig.config(for: .army)
    @Published var record = PromotionData(
        id: UUID(),
        userId: UUID(),
        currentRank: "",
        targetRank: "",
        pointsCurrent: 0,
        pointsRequired: 0,
        boardDate: nil,
        notes: nil,
        updatedAt: Date()
    )
    @Published var selectedTargetRank: PromotionRank?
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published private(set) var configuredForExistingRecord = false

    private let promotionService = PromotionService.shared
    private var configuredUserID: UUID?

    func configure(branch: MilitaryBranch, userId: UUID, currentRank: String) async {
        guard configuredUserID != userId || branchConfig.branch != branch else { return }

        configuredUserID = userId
        branchConfig = BranchPromotionConfig.config(for: branch)
        selectedTargetRank = branchConfig.rankStructure.first

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            if let loaded = try await promotionService.fetchPromotion(userId: userId) {
                record = loaded
                configuredForExistingRecord = true
                if record.branch == nil {
                    record.branch = branch
                }
                if record.currentRank.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    record.currentRank = currentRank
                }
            } else {
                configuredForExistingRecord = false
                record = PromotionData(
                    id: UUID(),
                    userId: userId,
                    currentRank: currentRank,
                    targetRank: "",
                    pointsCurrent: 0,
                    pointsRequired: 0,
                    boardDate: nil,
                    notes: nil,
                    updatedAt: Date(),
                    branch: branch
                )
            }

            selectedTargetRank = branchConfig.rankStructure.first(where: { $0.payGrade == record.targetRank }) ?? branchConfig.rankStructure.first
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var computedTotalScore: Int {
        switch branchConfig.branch {
        case .army:
            let milEd = record.armyMilEdPoints ?? 0
            let civEd = record.armyCivEdPoints ?? 0
            let awards = record.armyAwardsPoints ?? 0
            let training = record.armyMilTrgPoints ?? 0
            let acft = record.armyAcftPoints ?? 0
            let weapons = record.armyWeaponsPoints ?? 0
            return milEd + civEd + awards + training + acft + weapons
        case .airForce, .spaceForce:
            let skt = Double(record.wapsSktScore ?? 0) * 1.5
            let pfe = Double(record.wapsPfeScore ?? 0)
            let epr = Double(record.wapsEprScore ?? 0)
            let decorations = Double(record.wapsDecorationsPoints ?? 0)
            let afadcons = Double(record.wapsAfadconsPoints ?? 0)
            let tis = Double(record.wapsTisPoints ?? 0)
            let tig = Double(record.wapsTigPoints ?? 0)
            return Int(skt + pfe + epr + decorations + afadcons + tis + tig)
        case .navy:
            let pma = NavyFMSPoints.pmaPoints(pma: record.navyPmaScore ?? 0)
            let exam = Double(record.navyExamScore ?? 0)
            let sipg = record.navySipgPoints ?? 0
            let pna = record.navyPnaPoints ?? 0
            let awards = Double(record.navyAwardsPoints ?? 0)
            return Int(pma + exam + sipg + pna + awards)
        case .marines:
            return MarineCompositePoints.proPoints(avgMark: record.marineProMark ?? 0)
                + MarineCompositePoints.conPoints(avgMark: record.marineConMark ?? 0)
                + MarineCompositePoints.PFT.compositePoints(raw: record.marinePftScore ?? 0)
                + MarineCompositePoints.CFT.compositePoints(raw: record.marineCftScore ?? 0)
                + ((record.marineRifleScore ?? 0) * 10)
                + MarineCompositePoints.MCI.points(creditsEarned: record.marineMciPoints ?? 0)
        case .coastGuard:
            return Int(CGSWEPoints.finalScore(sweRaw: record.cgSweScore ?? 0, evalAvg: record.cgPerfFactor ?? 0))
        }
    }

    var maxPossibleScore: Int {
        switch branchConfig.branch {
        case .army:
            return 800
        case .airForce, .spaceForce:
            return 250
        case .navy:
            return 198
        case .marines:
            return 1000
        case .coastGuard:
            return 170
        }
    }

    var scoreProgress: Double {
        guard maxPossibleScore > 0 else { return 0 }
        return min(1.0, Double(computedTotalScore) / Double(maxPossibleScore))
    }

    var cutoffScore: Int? {
        switch branchConfig.branch {
        case .army:
            return record.armyCurrentCutoff
        case .airForce, .spaceForce:
            return record.wapsCutoffScore
        case .navy:
            return nil
        case .marines:
            return record.marineCuttingScore
        case .coastGuard:
            return record.cgAdvancementCut
        }
    }

    var isAboveCutoff: Bool? {
        guard let cutoffScore else { return nil }
        return computedTotalScore >= cutoffScore
    }

    var cutoffLabel: String {
        switch branchConfig.branch {
        case .army:
            return "MOS Cutoff"
        case .airForce, .spaceForce:
            return "WAPS Cutoff"
        case .navy:
            return "Cycle Prep"
        case .marines:
            return "Cutting Score"
        case .coastGuard:
            return "Advancement Cut"
        }
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

    var armyBreakdown: [(label: String, current: Int, max: Int)] {
        [
            ("Military Education", record.armyMilEdPoints ?? 0, ArmyPromotionPoints.MilEd.maxTotal),
            ("Civilian Education", record.armyCivEdPoints ?? 0, ArmyPromotionPoints.CivEd.maxTotal),
            ("Awards", record.armyAwardsPoints ?? 0, ArmyPromotionPoints.Awards.maxTotal),
            ("Military Training", record.armyMilTrgPoints ?? 0, ArmyPromotionPoints.MilTrg.maxTotal),
            ("ACFT", record.armyAcftPoints ?? 0, ArmyPromotionPoints.ACFT.maxTotal),
            ("Weapons", record.armyWeaponsPoints ?? 0, ArmyPromotionPoints.Weapons.maxTotal)
        ]
    }

    var wapsBreakdown: [(label: String, current: Double, max: Double)] {
        [
            ("SKT", Double(record.wapsSktScore ?? 0) * 1.5, 150),
            ("PFE", Double(record.wapsPfeScore ?? 0), 100),
            ("EPR", Double(record.wapsEprScore ?? 0), 135),
            ("Decorations", Double(record.wapsDecorationsPoints ?? 0), 25),
            ("AFADCONS", Double(record.wapsAfadconsPoints ?? 0), 25),
            ("TIS/TIG", Double((record.wapsTisPoints ?? 0) + (record.wapsTigPoints ?? 0)), 20)
        ]
    }

    var navyBreakdown: [(label: String, current: Double, max: Double)] {
        [
            ("PMA", NavyFMSPoints.pmaPoints(pma: record.navyPmaScore ?? 0), 86),
            ("Exam", Double(record.navyExamScore ?? 0), 80),
            ("SIPG", record.navySipgPoints ?? 0, 5.5),
            ("PNA", record.navyPnaPoints ?? 0, 1.5),
            ("Awards", Double(record.navyAwardsPoints ?? 0), 25)
        ]
    }

    var marineBreakdown: [(label: String, current: Int, max: Int)] {
        [
            ("PRO", MarineCompositePoints.proPoints(avgMark: record.marineProMark ?? 0), 500),
            ("CON", MarineCompositePoints.conPoints(avgMark: record.marineConMark ?? 0), 500),
            ("PFT", MarineCompositePoints.PFT.compositePoints(raw: record.marinePftScore ?? 0), 250),
            ("CFT", MarineCompositePoints.CFT.compositePoints(raw: record.marineCftScore ?? 0), 250),
            ("Rifle", (record.marineRifleScore ?? 0) * 10, 50),
            ("MCI", MarineCompositePoints.MCI.points(creditsEarned: record.marineMciPoints ?? 0), 100)
        ]
    }

    var cgBreakdown: [(label: String, current: Double, max: Double)] {
        [
            ("SWE", Double(record.cgSweScore ?? 0), 100),
            ("Performance Factor", (record.cgPerfFactor ?? 0) * 10, 70)
        ]
    }

    func save() async {
        isSaving = true
        errorMessage = nil
        successMessage = nil
        defer { isSaving = false }

        do {
            record.branch = branchConfig.branch
            record.targetRank = selectedTargetRank?.payGrade ?? record.targetRank
            record.pointsCurrent = computedTotalScore
            record.pointsRequired = cutoffScore ?? maxPossibleScore
            record.boardDate = record.nextBoardDate ?? record.boardDate

            try await promotionService.savePromotion(record)
            configuredForExistingRecord = true
            successMessage = "Promotion tracker saved."
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
            if let userId = configuredUserID {
                configuredForExistingRecord = false
                record = PromotionData(
                    id: UUID(),
                    userId: userId,
                    currentRank: record.currentRank,
                    targetRank: "",
                    pointsCurrent: 0,
                    pointsRequired: 0,
                    boardDate: nil,
                    notes: nil,
                    updatedAt: Date(),
                    branch: branchConfig.branch
                )
            }
            successMessage = "Promotion tracker deleted."
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
