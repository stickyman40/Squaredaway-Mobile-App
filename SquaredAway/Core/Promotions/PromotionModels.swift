import Foundation

enum PromotionSystemType: String, Codable, Hashable {
    case armyPoints
    case waps
    case navyFMS
    case marineComposite
    case coastGuardSWE
    case selectionBoard
}

struct BranchPromotionConfig {
    let branch: MilitaryBranch
    let accentHex: String
    let systemName: String
    let systemSummary: String
    let officialRef: String
    let ranks: [PromotionRank]
    let officialLinks: [OfficialLink]
    let tips: [PromotionTip]

    static func config(for branch: MilitaryBranch) -> BranchPromotionConfig {
        switch branch {
        case .army:
            return .army
        case .airForce:
            return .airForce
        case .navy:
            return .navy
        case .marines:
            return .marines
        case .spaceForce:
            return .spaceForce
        case .coastGuard:
            return .coastGuard
        }
    }

    var accentColor: String { accentHex }
    var systemDescription: String { systemSummary }
    var officialReference: String { officialRef }
    var rankStructure: [PromotionRank] { ranks }
    var resources: [PromotionResource] {
        officialLinks.map {
            PromotionResource(title: $0.title, subtitle: $0.subtitle, url: $0.url, icon: $0.icon)
        }
    }
    var boardTips: [PromotionBoardTip] {
        tips.map {
            PromotionBoardTip(title: $0.title, body: $0.body, priority: $0.impact.priority)
        }
    }
}

struct PromotionRank: Identifiable, Hashable {
    let payGrade: String
    let abbreviation: String
    let title: String
    let minTISMonths: Int
    let minTIGMonths: Int
    let systemType: PromotionSystemType
    let maxScore: Int?
    let isBoardSelected: Bool
    let notes: String

    var id: String { "\(payGrade)-\(abbreviation)" }
    var minTIS: Int { minTISMonths }
    var minTIG: Int { minTIGMonths }
    var maxPoints: Int? { maxScore }
}

struct ScoreComponent: Identifiable {
    let id = UUID()
    let name: String
    let current: Double
    let maximum: Double
    let color: String
    let icon: String
    let tip: String

    var progress: Double {
        guard maximum > 0 else { return 0 }
        return min(1.0, current / maximum)
    }

    var gapToMax: Double {
        max(0, maximum - current)
    }

    var fmt: String {
        current.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(current))" : String(format: "%.1f", current)
    }

    var fmtMax: String {
        maximum.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(maximum))" : String(format: "%.1f", maximum)
    }
}

struct ImprovementAction: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let pointsGain: String
    let effort: EffortLevel
    let timeframe: String
    let category: ActionCategory
    let link: String?

    enum EffortLevel {
        case low
        case medium
        case high

        var label: String {
            switch self {
            case .low:
                return "Quick win"
            case .medium:
                return "Moderate"
            case .high:
                return "Long-term"
            }
        }

        var color: String {
            switch self {
            case .low:
                return "#34C759"
            case .medium:
                return "#FF9F0A"
            case .high:
                return "#FF453A"
            }
        }
    }

    enum ActionCategory: String {
        case education
        case fitness
        case awards
        case training
        case testing
        case leadership
        case time

        var icon: String {
            switch self {
            case .education:
                return "graduationcap.fill"
            case .fitness:
                return "figure.run"
            case .awards:
                return "rosette"
            case .training:
                return "wrench.and.screwdriver.fill"
            case .testing:
                return "doc.text.magnifyingglass"
            case .leadership:
                return "person.fill.checkmark"
            case .time:
                return "clock.fill"
            }
        }

        var color: String {
            switch self {
            case .education:
                return "#45B7D1"
            case .fitness:
                return "#FF6B6B"
            case .awards:
                return "#FFD700"
            case .training:
                return "#96CEB4"
            case .testing:
                return "#A29BFE"
            case .leadership:
                return "#FF9F0A"
            case .time:
                return "#4ECDC4"
            }
        }
    }
}

struct OfficialLink: Identifiable, Hashable {
    let title: String
    let subtitle: String
    let url: String
    let icon: String

    var id: String { title }
}

typealias PromotionResource = OfficialLink

struct PromotionTip: Identifiable, Hashable {
    let title: String
    let body: String
    let impact: TipImpact

    var id: String { title }

    enum TipImpact: String {
        case critical
        case high
        case medium

        var color: String {
            switch self {
            case .critical:
                return "#FF453A"
            case .high:
                return "#FF9F0A"
            case .medium:
                return "#45B7D1"
            }
        }

        var label: String {
            rawValue.capitalized
        }

        var priority: PromotionBoardTip.TipPriority {
            switch self {
            case .critical:
                return .critical
            case .high:
                return .high
            case .medium:
                return .medium
            }
        }
    }
}

struct PromotionBoardTip: Identifiable, Hashable {
    enum TipPriority {
        case critical
        case high
        case medium
    }

    let title: String
    let body: String
    let priority: TipPriority

    var id: String { title }

    var priorityColor: String {
        switch priority {
        case .critical:
            return "#FF453A"
        case .high:
            return "#FF9F0A"
        case .medium:
            return "#45B7D1"
        }
    }
}

enum ArmyPoints {
    static let total = 800

    enum Max {
        static let milEd = 220
        static let civEd = 100
        static let awards = 125
        static let milTrg = 100
        static let aft = 60
        static let weapons = 20
    }
}

enum ArmyPromotionPoints {
    enum MilEd { static let maxTotal = ArmyPoints.Max.milEd }
    enum CivEd { static let maxTotal = ArmyPoints.Max.civEd }
    enum Awards { static let maxTotal = ArmyPoints.Max.awards }
    enum MilTrg { static let maxTotal = ArmyPoints.Max.milTrg }
    enum AFT { static let maxTotal = ArmyPoints.Max.aft }
    enum Weapons { static let maxTotal = ArmyPoints.Max.weapons }
}

enum WAPSPoints {
    static func sktWeighted(_ raw: Int, grade: String) -> Double {
        let factor: Double = (grade == "E-7" || grade == "E-8") ? 2.0 : 1.5
        return Double(raw) * factor
    }

    static func eprPts(_ rating: Int, grade: String) -> Int {
        let seniorTier = grade == "E-7" || grade == "E-8"
        switch rating {
        case 5:
            return seniorTier ? 126 : 135
        case 4:
            return seniorTier ? 105 : 108
        case 3:
            return seniorTier ? 84 : 81
        case 2:
            return seniorTier ? 63 : 54
        case 1:
            return seniorTier ? 42 : 27
        default:
            return 0
        }
    }

    static func tisPts(_ years: Int, grade: String) -> Double {
        let cap: Double
        switch grade {
        case "E-5":
            cap = 5
        case "E-6":
            cap = 7
        case "E-7":
            cap = 9
        default:
            cap = 10
        }
        return min(cap, Double(years) * 0.5)
    }

    static func tigPts(_ months: Int, grade: String) -> Double {
        let cap: Double
        switch grade {
        case "E-5":
            cap = 3
        case "E-6":
            cap = 5
        case "E-7":
            cap = 7.5
        default:
            cap = 8
        }
        return min(cap, Double(months) * 0.08)
    }

    static func maxForGrade(_ grade: String) -> Int {
        let factor = (grade == "E-7" || grade == "E-8") ? 2.0 : 1.5
        let eprMax = Double(eprPts(5, grade: grade))
        let total = (factor * 100) + 100 + eprMax + 25 + 25 + tisPts(999, grade: grade) + tigPts(999, grade: grade)
        return Int(total.rounded())
    }
}

enum NavyFMS {
    static func pmaPoints(_ pma: Double) -> Double {
        max(0, ((pma * 10) - 10) * 2)
    }

    static func sipgPts(_ years: Double) -> Double {
        min(5.5, years * 0.5)
    }

    static func pnaPts(_ attempts: Int) -> Double {
        min(1.5, Double(max(0, min(3, attempts))) * 0.5)
    }

    static let pmaMax: Double = 80
    static let examMax: Double = 80
    static let awardsMax: Double = 15
}

enum NavyFMSPoints {
    static func pmaPoints(pma: Double) -> Double {
        NavyFMS.pmaPoints(pma)
    }
}

enum MarineComposite {
    static let maxTotal = 2_150
    static let rifleMax = 50
    static let mciMax = 100

    static func proPts(_ mark: Double) -> Int {
        Int(mark * 100)
    }

    static func conPts(_ mark: Double) -> Int {
        Int(mark * 100)
    }

    static func pftComposite(_ raw: Int) -> Int {
        Int(Double(min(300, max(0, raw))) / 300.0 * 500.0)
    }

    static func cftComposite(_ raw: Int) -> Int {
        Int(Double(min(300, max(0, raw))) / 300.0 * 500.0)
    }
}

enum MarineCompositePoints {
    static func proPoints(avgMark: Double) -> Int { MarineComposite.proPts(avgMark) }
    static func conPoints(avgMark: Double) -> Int { MarineComposite.conPts(avgMark) }

    enum PFT {
        static func compositePoints(raw: Int) -> Int {
            MarineComposite.pftComposite(raw)
        }
    }

    enum CFT {
        static func compositePoints(raw: Int) -> Int {
            MarineComposite.cftComposite(raw)
        }
    }

    enum MCI {
        static func points(creditsEarned: Int) -> Int {
            min(creditsEarned, MarineComposite.mciMax)
        }
    }
}

enum CGSWE {
    static func perfFactor(_ evalAvg: Double) -> Double {
        min(70, max(10, evalAvg * 10))
    }

    static func finalScore(_ sweRaw: Int, _ evalAvg: Double) -> Double {
        Double(sweRaw) + perfFactor(evalAvg)
    }
}

enum CGSWEPoints {
    static func finalScore(sweRaw: Int, evalAvg: Double) -> Double {
        CGSWE.finalScore(sweRaw, evalAvg)
    }
}

enum PromotionScoring {
    static func cutoffScore(for record: PromotionData, branch: MilitaryBranch) -> Int? {
        switch branch {
        case .army:
            return record.armyMosCutoff
        case .airForce, .spaceForce:
            return record.wapsCutoffPublished
        case .navy:
            return nil
        case .marines:
            return record.marineCutScore
        case .coastGuard:
            return record.cgCutScore
        }
    }

    static func cutoffLabel(for branch: MilitaryBranch) -> String {
        switch branch {
        case .army:
            return "MOS Cutoff"
        case .airForce, .spaceForce:
            return "WAPS Cutoff"
        case .navy:
            return "Ranked List"
        case .marines:
            return "Cutting Score"
        case .coastGuard:
            return "Exam Cut"
        }
    }

    static func totalScore(for record: PromotionData, branch: MilitaryBranch, targetPayGrade: String? = nil) -> Int {
        switch branch {
        case .army:
            let milEd = record.armyMilEdPts ?? 0
            let civEd = record.armyCivEdPts ?? 0
            let awards = record.armyAwardsPts ?? 0
            let milTrg = record.armyMilTrgPts ?? 0
            let aft = record.armyAftPts ?? 0
            let weapons = record.armyWeaponsPts ?? 0
            return milEd + civEd + awards + milTrg + aft + weapons
        case .airForce, .spaceForce:
            let grade = targetPayGrade ?? "E-5"
            let skt = WAPSPoints.sktWeighted(record.wapsSktRaw ?? 0, grade: grade)
            let pfe = Double(record.wapsPfeRaw ?? 0)
            let epr = Double(WAPSPoints.eprPts(record.wapsEprRating ?? 0, grade: grade))
            let decorations = Double(record.wapsDecorationsPts ?? 0)
            let afadcons = Double(record.wapsAfadconsPts ?? 0)
            let tis = WAPSPoints.tisPts(record.wapsTisYears ?? 0, grade: grade)
            let tig = WAPSPoints.tigPts(record.wapsTigMonths ?? 0, grade: grade)
            let total = skt + pfe + epr + decorations + afadcons + tis + tig
            return Int(total.rounded())
        case .navy:
            let pma = NavyFMS.pmaPoints(record.navyPma ?? 0)
            let exam = Double(record.navyExamRaw ?? 0)
            let awards = Double(record.navyAwardsPts ?? 0)
            let sipg = NavyFMS.sipgPts(record.navySipgYears ?? 0)
            let pna = NavyFMS.pnaPts(record.navyPnaAttempts ?? 0)
            let total = pma + exam + awards + sipg + pna
            return Int(total.rounded())
        case .marines:
            let pro = MarineComposite.proPts(record.marineProMark ?? 0)
            let con = MarineComposite.conPts(record.marineConMark ?? 0)
            let pft = MarineComposite.pftComposite(record.marinePftRaw ?? 0)
            let cft = MarineComposite.cftComposite(record.marineCftRaw ?? 0)
            let rifle = record.marineRifleQual ?? 0
            let mci = min(MarineComposite.mciMax, record.marineMciCredits ?? 0)
            return pro + con + pft + cft + rifle + mci
        case .coastGuard:
            let score = CGSWE.finalScore(record.cgSweRaw ?? 0, record.cgPerfFactor ?? 1.0)
            return Int(score.rounded())
        }
    }

    static func components(for record: PromotionData, branch: MilitaryBranch, targetPayGrade: String? = nil) -> [ScoreComponent] {
        switch branch {
        case .army:
            return [
                ScoreComponent(name: "Military Education", current: Double(record.armyMilEdPts ?? 0), maximum: 220, color: "#45B7D1", icon: "graduationcap.fill", tip: "Resident ALC/SLC and functional courses drive this category."),
                ScoreComponent(name: "Civilian Education", current: Double(record.armyCivEdPts ?? 0), maximum: 100, color: "#96CEB4", icon: "building.columns.fill", tip: "Degrees and college hours can close score gaps quickly."),
                ScoreComponent(name: "Awards", current: Double(record.armyAwardsPts ?? 0), maximum: 125, color: "#FFD700", icon: "rosette", tip: "Audit every deserved award and make sure it is in your record."),
                ScoreComponent(name: "Military Training", current: Double(record.armyMilTrgPts ?? 0), maximum: 100, color: "#A29BFE", icon: "wrench.and.screwdriver.fill", tip: "ASI, DLPT, and MOS-related training add up."),
                ScoreComponent(name: "AFT Score", current: Double(record.armyAftPts ?? 0), maximum: 60, color: "#FF6B6B", icon: "figure.run", tip: "Every tier jump matters. Train for your weakest AFT event."),
                ScoreComponent(name: "Weapons Qual", current: Double(record.armyWeaponsPts ?? 0), maximum: 20, color: "#FF9F0A", icon: "scope", tip: "Expert is a fast 20 points if you prepare ahead of qual.")
            ]
        case .airForce, .spaceForce:
            let grade = targetPayGrade ?? "E-5"
            let factor = (grade == "E-7" || grade == "E-8") ? 2.0 : 1.5
            let tisMax = WAPSPoints.tisPts(999, grade: grade)
            let tigMax = WAPSPoints.tigPts(999, grade: grade)
            let eprMax = Double(WAPSPoints.eprPts(5, grade: grade))
            return [
                ScoreComponent(name: "SKT", current: WAPSPoints.sktWeighted(record.wapsSktRaw ?? 0, grade: grade), maximum: factor * 100, color: "#45B7D1", icon: "doc.text.magnifyingglass", tip: "Use the official bibliography and study by objective area."),
                ScoreComponent(name: "PFE", current: Double(record.wapsPfeRaw ?? 0), maximum: 100, color: "#A29BFE", icon: "book.fill", tip: "The PFE is straight study payoff. Build a dedicated plan."),
                ScoreComponent(name: "EPR Rating", current: Double(WAPSPoints.eprPts(record.wapsEprRating ?? 0, grade: grade)), maximum: eprMax, color: "#FFD700", icon: "star.fill", tip: "Your next report quality can swing the entire cycle."),
                ScoreComponent(name: "Decorations", current: Double(record.wapsDecorationsPts ?? 0), maximum: 25, color: "#FF9F0A", icon: "rosette", tip: "Make sure every approved decoration is credited before closeout."),
                ScoreComponent(name: "AFADCONS", current: Double(record.wapsAfadconsPts ?? 0), maximum: 25, color: "#96CEB4", icon: "person.2.fill", tip: "Volunteer work and off-duty development are easy-to-miss points."),
                ScoreComponent(name: "TIS + TIG", current: WAPSPoints.tisPts(record.wapsTisYears ?? 0, grade: grade) + WAPSPoints.tigPts(record.wapsTigMonths ?? 0, grade: grade), maximum: tisMax + tigMax, color: "#4ECDC4", icon: "clock.fill", tip: "This grows automatically, so focus on the categories you control today.")
            ]
        case .navy:
            return [
                ScoreComponent(name: "PMA (EVALs)", current: NavyFMS.pmaPoints(record.navyPma ?? 0), maximum: NavyFMS.pmaMax, color: "#FFD700", icon: "star.fill", tip: "PMA is your highest-leverage long-term multiplier."),
                ScoreComponent(name: "Advancement Exam", current: Double(record.navyExamRaw ?? 0), maximum: NavyFMS.examMax, color: "#45B7D1", icon: "doc.text.fill", tip: "The exam is the quickest way to move your FMS this cycle."),
                ScoreComponent(name: "Awards", current: Double(record.navyAwardsPts ?? 0), maximum: NavyFMS.awardsMax, color: "#FF9F0A", icon: "rosette", tip: "Verify every award is in NSIPS before the cycle closes."),
                ScoreComponent(name: "SIPG Bonus", current: NavyFMS.sipgPts(record.navySipgYears ?? 0), maximum: 5.5, color: "#96CEB4", icon: "clock.fill", tip: "Time in grade helps, but it will not replace study or eval strength."),
                ScoreComponent(name: "PNA Points", current: NavyFMS.pnaPts(record.navyPnaAttempts ?? 0), maximum: 1.5, color: "#A29BFE", icon: "arrow.clockwise", tip: "Keep testing. Small PNA gains matter when rates are tight.")
            ]
        case .marines:
            return [
                ScoreComponent(name: "PRO Marks", current: Double(MarineComposite.proPts(record.marineProMark ?? 0)), maximum: 500, color: "#CC0000", icon: "person.fill.checkmark", tip: "Billet performance and leadership visibility drive this category."),
                ScoreComponent(name: "CON Marks", current: Double(MarineComposite.conPts(record.marineConMark ?? 0)), maximum: 500, color: "#FF6B6B", icon: "shield.fill", tip: "Conduct consistency matters over time, not just at cycle close."),
                ScoreComponent(name: "PFT Score", current: Double(MarineComposite.pftComposite(record.marinePftRaw ?? 0)), maximum: 500, color: "#FF9F0A", icon: "figure.run", tip: "Target the events where your training gap is most obvious."),
                ScoreComponent(name: "CFT Score", current: Double(MarineComposite.cftComposite(record.marineCftRaw ?? 0)), maximum: 500, color: "#FFD700", icon: "figure.walk", tip: "Train the actual CFT movements to convert effort into points."),
                ScoreComponent(name: "Rifle Qual", current: Double(record.marineRifleQual ?? 0), maximum: 50, color: "#45B7D1", icon: "scope", tip: "Expert is one of the simplest fixed jumps available."),
                ScoreComponent(name: "MCI Credits", current: Double(min(MarineComposite.mciMax, record.marineMciCredits ?? 0)), maximum: 100, color: "#A29BFE", icon: "graduationcap.fill", tip: "Short courses can create steady monthly gains.")
            ]
        case .coastGuard:
            return [
                ScoreComponent(name: "SWE Raw Score", current: Double(record.cgSweRaw ?? 0), maximum: 100, color: "#003087", icon: "doc.text.fill", tip: "Raw exam score remains the largest controllable category."),
                ScoreComponent(name: "Performance Factor", current: CGSWE.perfFactor(record.cgPerfFactor ?? 1.0), maximum: 70, color: "#45B7D1", icon: "star.fill", tip: "Keep your last three evals strong because they compound into PF.")
            ]
        }
    }

    static func maxScore(for record: PromotionData, branch: MilitaryBranch, targetPayGrade: String? = nil) -> Int {
        Int(components(for: record, branch: branch, targetPayGrade: targetPayGrade).reduce(0.0) { $0 + $1.maximum }.rounded())
    }
}

extension BranchPromotionConfig {
    static let army = BranchPromotionConfig(
        branch: .army,
        accentHex: "#4A7C59",
        systemName: "Semi-Centralized Promotion Points",
        systemSummary: "Army E-5 and E-6 promotions use point-based competition across education, awards, training, AFT, and weapons qualification. Senior enlisted grades use centralized boards.",
        officialRef: "AR 600-8-19",
        ranks: [
            PromotionRank(payGrade: "E-4", abbreviation: "SPC/CPL", title: "Specialist / Corporal", minTISMonths: 24, minTIGMonths: 6, systemType: .armyPoints, maxScore: nil, isBoardSelected: false, notes: "Commander recommendation and time-based advancement."),
            PromotionRank(payGrade: "E-5", abbreviation: "SGT", title: "Sergeant", minTISMonths: 36, minTIGMonths: 8, systemType: .armyPoints, maxScore: 800, isBoardSelected: false, notes: "Monthly MOS cutoff scores determine advancement."),
            PromotionRank(payGrade: "E-6", abbreviation: "SSG", title: "Staff Sergeant", minTISMonths: 84, minTIGMonths: 10, systemType: .armyPoints, maxScore: 800, isBoardSelected: false, notes: "Same point categories as SGT with steeper competition."),
            PromotionRank(payGrade: "E-7", abbreviation: "SFC", title: "Sergeant First Class", minTISMonths: 72, minTIGMonths: 12, systemType: .selectionBoard, maxScore: nil, isBoardSelected: true, notes: "Centralized board with whole-record review."),
            PromotionRank(payGrade: "E-8", abbreviation: "MSG/1SG", title: "Master Sergeant / First Sergeant", minTISMonths: 96, minTIGMonths: 12, systemType: .selectionBoard, maxScore: nil, isBoardSelected: true, notes: "Leadership trend and evaluations matter most."),
            PromotionRank(payGrade: "E-9", abbreviation: "SGM/CSM", title: "Sergeant Major / Command Sergeant Major", minTISMonths: 108, minTIGMonths: 12, systemType: .selectionBoard, maxScore: nil, isBoardSelected: true, notes: "Extremely competitive centralized board.")
        ],
        officialLinks: [
            OfficialLink(title: "HRC Enlisted Promotions", subtitle: "army.mil", url: "https://www.hrc.army.mil/Enlisted/Promotion", icon: "star.circle.fill"),
            OfficialLink(title: "Monthly MILPER Messages", subtitle: "MOS cutoff scores", url: "https://www.hrc.army.mil/Milper", icon: "doc.text.fill"),
            OfficialLink(title: "AR 600-8-19", subtitle: "Promotions regulation", url: "https://armypubs.army.mil", icon: "book.fill"),
            OfficialLink(title: "ArmyIgnitED", subtitle: "Tuition Assistance", url: "https://armyignited.army.mil", icon: "graduationcap.fill")
        ],
        tips: [
            PromotionTip(title: "Max the AFT when possible", body: "AFT promotion points can move quickly when you train the exact scored events.", impact: .critical),
            PromotionTip(title: "Expert weapons qualification is a fast swing", body: "The jump from marksman to expert is meaningful and can be fixed in one range cycle.", impact: .high),
            PromotionTip(title: "Resident PME is worth chasing", body: "Resident NCOES courses typically outperform distance alternatives for points.", impact: .high),
            PromotionTip(title: "College work compounds", body: "Civilian education is one of the biggest long-term point builders available.", impact: .high),
            PromotionTip(title: "Track your MOS cutoff monthly", body: "Promotion readiness changes with the published cutoff, not just your raw score.", impact: .critical),
            PromotionTip(title: "Audit awards often", body: "Missing approved awards can hide easy points on your record.", impact: .medium)
        ]
    )

    static let airForce = BranchPromotionConfig(
        branch: .airForce,
        accentHex: "#004990",
        systemName: "WAPS",
        systemSummary: "Air Force promotions use the Weighted Airman Promotion System with exact SKT weighting, PFE raw score, EPR-derived points, decorations, AFADCONS, and TIS/TIG bonuses.",
        officialRef: "AFI 36-2502",
        ranks: [
            PromotionRank(payGrade: "E-5", abbreviation: "SSgt", title: "Staff Sergeant", minTISMonths: 36, minTIGMonths: 6, systemType: .waps, maxScore: nil, isBoardSelected: false, notes: "WAPS with published AFPC cutoff scores."),
            PromotionRank(payGrade: "E-6", abbreviation: "TSgt", title: "Technical Sergeant", minTISMonths: 60, minTIGMonths: 23, systemType: .waps, maxScore: nil, isBoardSelected: false, notes: "Higher TIS/TIG caps and stronger competition."),
            PromotionRank(payGrade: "E-7", abbreviation: "MSgt", title: "Master Sergeant", minTISMonths: 96, minTIGMonths: 24, systemType: .waps, maxScore: nil, isBoardSelected: false, notes: "Senior-tier WAPS scoring applies."),
            PromotionRank(payGrade: "E-8", abbreviation: "SMSgt", title: "Senior Master Sergeant", minTISMonths: 144, minTIGMonths: 20, systemType: .waps, maxScore: nil, isBoardSelected: false, notes: "Senior-tier WAPS with heavier SKT weighting."),
            PromotionRank(payGrade: "E-9", abbreviation: "CMSgt", title: "Chief Master Sergeant", minTISMonths: 180, minTIGMonths: 21, systemType: .selectionBoard, maxScore: nil, isBoardSelected: true, notes: "Centralized board selection.")
        ],
        officialLinks: [
            OfficialLink(title: "AFPC Enlisted Promotions", subtitle: "afpc.af.mil", url: "https://www.afpc.af.mil/Airman-Development/Enlisted-Promotions/", icon: "star.circle.fill"),
            OfficialLink(title: "WAPS Scoring Guide", subtitle: "Official guidance", url: "https://www.afpc.af.mil", icon: "chart.bar.fill"),
            OfficialLink(title: "SKT / PFE Bibliography", subtitle: "Study materials", url: "https://www.afpc.af.mil", icon: "book.fill"),
            OfficialLink(title: "myFSS", subtitle: "Records and decorations", url: "https://myfss.us.af.mil", icon: "person.fill.checkmark")
        ],
        tips: [
            PromotionTip(title: "Test prep still moves the cycle fastest", body: "SKT and PFE are the most immediate ways to change your score before cutoff release.", impact: .critical),
            PromotionTip(title: "EPR quality compounds over time", body: "Your rating-derived points can outweigh smaller categories in a single cycle.", impact: .critical),
            PromotionTip(title: "Track AFADCONS early", body: "Waiting until closeout to gather volunteer and development records often leaves points behind.", impact: .high),
            PromotionTip(title: "Verify decorations before cutoff processing", body: "Approved but uncredited decorations do not help if they miss the cycle lock date.", impact: .high),
            PromotionTip(title: "Know the grade-specific SKT multiplier", body: "The same raw score is worth more at higher WAPS grades.", impact: .medium)
        ]
    )

    static let navy = BranchPromotionConfig(
        branch: .navy,
        accentHex: "#1B2A4A",
        systemName: "Final Multiple Score",
        systemSummary: "Navy advancement blends PMA, exam score, awards, service in paygrade bonus, and PNA credit into Final Multiple Score for cycle ranking.",
        officialRef: "MILPERSMAN 1430-010",
        ranks: [
            PromotionRank(payGrade: "E-4", abbreviation: "PO3", title: "Petty Officer Third Class", minTISMonths: 6, minTIGMonths: 6, systemType: .navyFMS, maxScore: 182, isBoardSelected: false, notes: "Rate-specific exam and PMA determine competitiveness."),
            PromotionRank(payGrade: "E-5", abbreviation: "PO2", title: "Petty Officer Second Class", minTISMonths: 12, minTIGMonths: 12, systemType: .navyFMS, maxScore: 182, isBoardSelected: false, notes: "Cycle ranking based on FMS."),
            PromotionRank(payGrade: "E-6", abbreviation: "PO1", title: "Petty Officer First Class", minTISMonths: 36, minTIGMonths: 36, systemType: .navyFMS, maxScore: 182, isBoardSelected: false, notes: "FMS plus rate competition drives advancement."),
            PromotionRank(payGrade: "E-7", abbreviation: "CPO", title: "Chief Petty Officer", minTISMonths: 84, minTIGMonths: 36, systemType: .selectionBoard, maxScore: nil, isBoardSelected: true, notes: "Selection board and whole-record review."),
            PromotionRank(payGrade: "E-8", abbreviation: "SCPO", title: "Senior Chief Petty Officer", minTISMonths: 120, minTIGMonths: 36, systemType: .selectionBoard, maxScore: nil, isBoardSelected: true, notes: "Centralized board."),
            PromotionRank(payGrade: "E-9", abbreviation: "MCPO", title: "Master Chief Petty Officer", minTISMonths: 144, minTIGMonths: 36, systemType: .selectionBoard, maxScore: nil, isBoardSelected: true, notes: "Centralized board. Extremely selective.")
        ],
        officialLinks: [
            OfficialLink(title: "MyNavy HR Advancement", subtitle: "mynavyhr.navy.mil", url: "https://www.mynavyhr.navy.mil/Career-Management/Advancement/", icon: "star.circle.fill"),
            OfficialLink(title: "NETPDC Exam Prep", subtitle: "Bibliographies and guidance", url: "https://www.netc.navy.mil", icon: "book.fill"),
            OfficialLink(title: "Navy COOL", subtitle: "Credentialing and development", url: "https://cool.osd.mil/usn", icon: "graduationcap.fill")
        ],
        tips: [
            PromotionTip(title: "PMA is the long-term anchor", body: "PMA has one of the biggest impacts on your FMS and is built before the exam cycle begins.", impact: .critical),
            PromotionTip(title: "The exam is your fastest short-term lever", body: "A strong bibliography-based study block can create immediate FMS movement.", impact: .critical),
            PromotionTip(title: "Do not ignore PNA accumulation", body: "Small PNA gains help when your rate runs tight over multiple cycles.", impact: .medium),
            PromotionTip(title: "Keep awards and eval records clean", body: "Missing administrative data quietly suppresses your FMS.", impact: .high)
        ]
    )

    static let marines = BranchPromotionConfig(
        branch: .marines,
        accentHex: "#CC0000",
        systemName: "Composite Score",
        systemSummary: "Marine Corps enlisted advancement blends PRO/CON marks, PFT, CFT, rifle qualification, and MCI credit into a composite score that is compared with MOS cutting scores.",
        officialRef: "MCO P1400.32D",
        ranks: [
            PromotionRank(payGrade: "E-4", abbreviation: "LCpl", title: "Lance Corporal", minTISMonths: 9, minTIGMonths: 8, systemType: .marineComposite, maxScore: 2_150, isBoardSelected: false, notes: "Composite score with published MOS cutting score."),
            PromotionRank(payGrade: "E-5", abbreviation: "Cpl", title: "Corporal", minTISMonths: 24, minTIGMonths: 12, systemType: .marineComposite, maxScore: 2_150, isBoardSelected: false, notes: "Composite score with monthly competition."),
            PromotionRank(payGrade: "E-6", abbreviation: "Sgt", title: "Sergeant", minTISMonths: 36, minTIGMonths: 12, systemType: .marineComposite, maxScore: 2_150, isBoardSelected: false, notes: "Higher competition and leadership expectations."),
            PromotionRank(payGrade: "E-7", abbreviation: "SSgt", title: "Staff Sergeant", minTISMonths: 60, minTIGMonths: 24, systemType: .selectionBoard, maxScore: nil, isBoardSelected: true, notes: "Board-selected rank."),
            PromotionRank(payGrade: "E-8", abbreviation: "GySgt", title: "Gunnery Sergeant", minTISMonths: 96, minTIGMonths: 24, systemType: .selectionBoard, maxScore: nil, isBoardSelected: true, notes: "Board-selected rank."),
            PromotionRank(payGrade: "E-9", abbreviation: "MGySgt/SgtMaj", title: "Master Gunnery Sergeant / Sergeant Major", minTISMonths: 120, minTIGMonths: 36, systemType: .selectionBoard, maxScore: nil, isBoardSelected: true, notes: "Centralized board.")
        ],
        officialLinks: [
            OfficialLink(title: "MMPR Promotions", subtitle: "manpower.usmc.mil", url: "https://www.manpower.usmc.mil", icon: "star.circle.fill"),
            OfficialLink(title: "Monthly Cutting Scores", subtitle: "MOS cutoffs", url: "https://www.manpower.usmc.mil", icon: "chart.bar.fill"),
            OfficialLink(title: "MCO P1400.32D", subtitle: "Promotions manual", url: "https://www.marines.mil/Publications/", icon: "book.fill"),
            OfficialLink(title: "MCI Catalog", subtitle: "Distance education", url: "https://www.mci.marines.mil", icon: "graduationcap.fill")
        ],
        tips: [
            PromotionTip(title: "Target rifle expert early", body: "Rifle qualification is a fixed category with fast gains compared with board-style categories.", impact: .critical),
            PromotionTip(title: "Train the PFT and CFT specifically", body: "Composite points come from raw event performance, not generic conditioning alone.", impact: .critical),
            PromotionTip(title: "PRO/CON marks are your leadership record", body: "Day-to-day billet performance directly changes the largest sections of your score.", impact: .high),
            PromotionTip(title: "Use short MCI blocks consistently", body: "Steady course completion is one of the easiest monthly ways to build composite score.", impact: .medium)
        ]
    )

    static let spaceForce = BranchPromotionConfig(
        branch: .spaceForce,
        accentHex: "#1B2559",
        systemName: "Guardian WAPS",
        systemSummary: "Space Force enlisted promotion follows a WAPS-style model with Space Force-specific testing and the same core record-based bonus structure.",
        officialRef: "DAFI 36-2502",
        ranks: [
            PromotionRank(payGrade: "E-5", abbreviation: "Spc5", title: "Specialist 5", minTISMonths: 36, minTIGMonths: 6, systemType: .waps, maxScore: nil, isBoardSelected: false, notes: "Guardian WAPS-style score."),
            PromotionRank(payGrade: "E-6", abbreviation: "Spc6", title: "Specialist 6", minTISMonths: 60, minTIGMonths: 23, systemType: .waps, maxScore: nil, isBoardSelected: false, notes: "Guardian WAPS with stronger development expectations."),
            PromotionRank(payGrade: "E-7", abbreviation: "Spc7", title: "Specialist 7", minTISMonths: 96, minTIGMonths: 24, systemType: .waps, maxScore: nil, isBoardSelected: false, notes: "Senior-tier WAPS-style score."),
            PromotionRank(payGrade: "E-8", abbreviation: "Spc8", title: "Specialist 8", minTISMonths: 144, minTIGMonths: 20, systemType: .waps, maxScore: nil, isBoardSelected: false, notes: "Smaller force means tighter competition."),
            PromotionRank(payGrade: "E-9", abbreviation: "Spc9", title: "Specialist 9", minTISMonths: 180, minTIGMonths: 21, systemType: .selectionBoard, maxScore: nil, isBoardSelected: true, notes: "Board-selected rank.")
        ],
        officialLinks: [
            OfficialLink(title: "Space Force Talent Management", subtitle: "spaceforce.mil", url: "https://www.spaceforce.mil/", icon: "sparkles"),
            OfficialLink(title: "Guardian Development", subtitle: "Career development guidance", url: "https://www.spaceforce.mil/News/", icon: "person.fill.checkmark"),
            OfficialLink(title: "DAFI 36-2502", subtitle: "Promotion guidance", url: "https://www.e-publishing.af.mil", icon: "book.fill")
        ],
        tips: BranchPromotionConfig.airForce.tips
    )

    static let coastGuard = BranchPromotionConfig(
        branch: .coastGuard,
        accentHex: "#003087",
        systemName: "Servicewide Examination",
        systemSummary: "Coast Guard advancement combines raw SWE score with a performance factor from recent evaluations, then compares the result against published rating cut scores.",
        officialRef: "COMDTINST M1000.2C",
        ranks: [
            PromotionRank(payGrade: "E-4", abbreviation: "PO3", title: "Petty Officer Third Class", minTISMonths: 12, minTIGMonths: 12, systemType: .coastGuardSWE, maxScore: 170, isBoardSelected: false, notes: "SWE plus performance factor."),
            PromotionRank(payGrade: "E-5", abbreviation: "PO2", title: "Petty Officer Second Class", minTISMonths: 36, minTIGMonths: 24, systemType: .coastGuardSWE, maxScore: 170, isBoardSelected: false, notes: "SWE plus performance factor."),
            PromotionRank(payGrade: "E-6", abbreviation: "PO1", title: "Petty Officer First Class", minTISMonths: 60, minTIGMonths: 36, systemType: .coastGuardSWE, maxScore: 170, isBoardSelected: false, notes: "SWE-based advancement."),
            PromotionRank(payGrade: "E-7", abbreviation: "CPO", title: "Chief Petty Officer", minTISMonths: 84, minTIGMonths: 36, systemType: .selectionBoard, maxScore: nil, isBoardSelected: true, notes: "Centralized board."),
            PromotionRank(payGrade: "E-8", abbreviation: "MCPO", title: "Senior Chief / Master Chief path", minTISMonths: 120, minTIGMonths: 36, systemType: .selectionBoard, maxScore: nil, isBoardSelected: true, notes: "Centralized board.")
        ],
        officialLinks: [
            OfficialLink(title: "PSC EPM Advancement", subtitle: "dcms.uscg.mil", url: "https://www.dcms.uscg.mil", icon: "star.circle.fill"),
            OfficialLink(title: "SWE Bibliography", subtitle: "Study materials", url: "https://www.dcms.uscg.mil", icon: "book.fill"),
            OfficialLink(title: "COMDTINST M1000.2C", subtitle: "Advancement guidance", url: "https://www.dcms.uscg.mil", icon: "doc.text.fill")
        ],
        tips: [
            PromotionTip(title: "Raw SWE score is still the backbone", body: "The exam remains the largest controllable piece of your final score.", impact: .critical),
            PromotionTip(title: "Protect your last three evals", body: "Performance factor compounds over multiple cycles and can separate close results.", impact: .critical),
            PromotionTip(title: "Track published rating cuts", body: "Your readiness changes with the rating environment, not just your own score.", impact: .high),
            PromotionTip(title: "Use professional development to support evals", body: "Courses and collateral duties help supervisors write stronger evaluations.", impact: .medium)
        ]
    )
}

extension PromotionData {
    static func empty(userId: UUID, branch: MilitaryBranch, currentPayGrade: String = "") -> PromotionData {
        PromotionData(
            id: UUID(),
            userId: userId,
            branch: branch,
            currentPayGrade: currentPayGrade,
            targetPayGrade: "",
            monthsInService: 0,
            monthsInGrade: 0,
            armyMilEdPts: nil,
            armyCivEdPts: nil,
            armyAwardsPts: nil,
            armyMilTrgPts: nil,
            armyAftPts: nil,
            armyWeaponsPts: nil,
            armyMosCutoff: nil,
            armyMos: nil,
            wapsSktRaw: nil,
            wapsPfeRaw: nil,
            wapsEprRating: nil,
            wapsDecorationsPts: nil,
            wapsAfadconsPts: nil,
            wapsTisYears: nil,
            wapsTigMonths: nil,
            wapsCutoffPublished: nil,
            navyPma: nil,
            navyExamRaw: nil,
            navyAwardsPts: nil,
            navySipgYears: nil,
            navyPnaAttempts: nil,
            marineProMark: nil,
            marineConMark: nil,
            marinePftRaw: nil,
            marineCftRaw: nil,
            marineRifleQual: nil,
            marineMciCredits: nil,
            marineCutScore: nil,
            cgSweRaw: nil,
            cgPerfFactor: nil,
            cgCutScore: nil,
            nextBoardDate: nil,
            boardNotes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    var currentRank: String {
        get { currentPayGrade }
        set { currentPayGrade = newValue }
    }

    var targetRank: String {
        get { targetPayGrade }
        set { targetPayGrade = newValue }
    }

    var boardDate: Date? {
        get { nextBoardDate }
        set { nextBoardDate = newValue }
    }

    var notes: String? {
        get { boardNotes }
        set { boardNotes = newValue }
    }
}
