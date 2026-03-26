import Foundation

enum PromotionSystemType: Hashable {
    case armyPoints
    case waps
    case navyFMS
    case marineComposite
    case coastGuardSWE
    case selectionBoard
}

struct BranchPromotionConfig {
    let branch: MilitaryBranch
    let systemType: PromotionSystemType
    let rankStructure: [PromotionRank]
    let accentColor: String
    let systemName: String
    let systemDescription: String
    let officialReference: String
    let resources: [PromotionResource]

    static func config(for branch: MilitaryBranch) -> BranchPromotionConfig {
        switch branch {
        case .army: return .army
        case .airForce: return .airForce
        case .navy: return .navy
        case .marines: return .marines
        case .spaceForce: return .spaceForce
        case .coastGuard: return .coastGuard
        }
    }
}

struct PromotionRank: Identifiable, Hashable {
    let payGrade: String
    let abbreviation: String
    let title: String
    let minTIS: Int
    let minTIG: Int
    let systemType: PromotionSystemType
    let maxPoints: Int?
    let notes: String

    var id: String { "\(payGrade)-\(abbreviation)" }
}

struct PromotionResource: Identifiable, Hashable {
    let title: String
    let subtitle: String
    let url: String
    let icon: String

    var id: String { title }
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

enum ArmyPromotionPoints {
    enum MilEd { static let maxTotal = 220 }
    enum CivEd { static let maxTotal = 100 }
    enum Awards { static let maxTotal = 125 }
    enum MilTrg { static let maxTotal = 100 }
    enum ACFT { static let maxTotal = 60 }
    enum Weapons { static let maxTotal = 20 }
}

enum NavyFMSPoints {
    static func pmaPoints(pma: Double) -> Double {
        max(0, ((pma * 10) - 10) * 2)
    }
}

enum MarineCompositePoints {
    static func proPoints(avgMark: Double) -> Int { Int(avgMark * 100) }
    static func conPoints(avgMark: Double) -> Int { Int(avgMark * 100) }

    enum PFT {
        static func compositePoints(raw: Int) -> Int {
            Int(Double(min(300, raw)) / 300.0 * 250)
        }
    }

    enum CFT {
        static func compositePoints(raw: Int) -> Int {
            Int(Double(min(300, raw)) / 300.0 * 250)
        }
    }

    enum MCI {
        static func points(creditsEarned: Int) -> Int {
            min(creditsEarned * 10, 100)
        }
    }
}

enum CGSWEPoints {
    static func finalScore(sweRaw: Int, evalAvg: Double) -> Double {
        Double(sweRaw) + (evalAvg * 10)
    }
}

extension BranchPromotionConfig {
    static let army = BranchPromotionConfig(
        branch: .army,
        systemType: .armyPoints,
        rankStructure: [
            PromotionRank(payGrade: "E-5", abbreviation: "SGT", title: "Sergeant", minTIS: 36, minTIG: 8, systemType: .armyPoints, maxPoints: 800, notes: "Semi-centralized. Monthly MOS-specific cutoff scores."),
            PromotionRank(payGrade: "E-6", abbreviation: "SSG", title: "Staff Sergeant", minTIS: 84, minTIG: 10, systemType: .armyPoints, maxPoints: 800, notes: "Semi-centralized. Higher cutoff competition."),
            PromotionRank(payGrade: "E-7", abbreviation: "SFC", title: "Sergeant First Class", minTIS: 72, minTIG: 12, systemType: .selectionBoard, maxPoints: nil, notes: "Selection board. Whole-record review."),
            PromotionRank(payGrade: "E-8", abbreviation: "MSG/1SG", title: "Master Sergeant / First Sergeant", minTIS: 96, minTIG: 12, systemType: .selectionBoard, maxPoints: nil, notes: "Selection board. Leadership potential matters."),
            PromotionRank(payGrade: "E-9", abbreviation: "SGM", title: "Sergeant Major", minTIS: 108, minTIG: 12, systemType: .selectionBoard, maxPoints: nil, notes: "Selection board. Extremely competitive.")
        ],
        accentColor: "#4A7C59",
        systemName: "Promotion Points",
        systemDescription: "Army E-5 and E-6 promotions use semi-centralized points. Senior grades use a board.",
        officialReference: "AR 600-8-19",
        resources: [
            PromotionResource(title: "HRC Enlisted Promotions", subtitle: "army.mil", url: "https://www.hrc.army.mil/Enlisted/Promotion", icon: "star.circle.fill"),
            PromotionResource(title: "Monthly MILPER Messages", subtitle: "MOS cutoff scores", url: "https://www.hrc.army.mil/Milper", icon: "doc.text.fill")
        ]
    )

    static let airForce = BranchPromotionConfig(
        branch: .airForce,
        systemType: .waps,
        rankStructure: [
            PromotionRank(payGrade: "E-5", abbreviation: "SSgt", title: "Staff Sergeant", minTIS: 36, minTIG: 6, systemType: .waps, maxPoints: 250, notes: "WAPS with SKT, PFE, EPR, decorations, TIS/TIG, AFADCONS."),
            PromotionRank(payGrade: "E-6", abbreviation: "TSgt", title: "Technical Sergeant", minTIS: 60, minTIG: 23, systemType: .waps, maxPoints: 250, notes: "WAPS with published AFPC cutoff."),
            PromotionRank(payGrade: "E-7", abbreviation: "MSgt", title: "Master Sergeant", minTIS: 96, minTIG: 24, systemType: .waps, maxPoints: 250, notes: "WAPS, high competition."),
            PromotionRank(payGrade: "E-8", abbreviation: "SMSgt", title: "Senior Master Sergeant", minTIS: 144, minTIG: 20, systemType: .waps, maxPoints: 250, notes: "WAPS with strong EPR weighting."),
            PromotionRank(payGrade: "E-9", abbreviation: "CMSgt", title: "Chief Master Sergeant", minTIS: 180, minTIG: 21, systemType: .selectionBoard, maxPoints: nil, notes: "Selection board.")
        ],
        accentColor: "#004990",
        systemName: "Weighted Airman Promotion System",
        systemDescription: "Weighted test and record-based score with published cutoff scores.",
        officialReference: "AFI 36-2502",
        resources: [
            PromotionResource(title: "AFPC Enlisted Promotions", subtitle: "afpc.af.mil", url: "https://www.afpc.af.mil/Career-Management/Enlisted-Career-Opportunities/", icon: "star.circle.fill"),
            PromotionResource(title: "WAPS Information", subtitle: "Study and cutoff guidance", url: "https://www.afpc.af.mil/Airman-Development/Enlisted-Promotions/", icon: "book.fill")
        ]
    )

    static let navy = BranchPromotionConfig(
        branch: .navy,
        systemType: .navyFMS,
        rankStructure: [
            PromotionRank(payGrade: "E-4", abbreviation: "PO3", title: "Petty Officer Third Class", minTIS: 6, minTIG: 6, systemType: .navyFMS, maxPoints: nil, notes: "FMS with advancement exam."),
            PromotionRank(payGrade: "E-5", abbreviation: "PO2", title: "Petty Officer Second Class", minTIS: 12, minTIG: 12, systemType: .navyFMS, maxPoints: nil, notes: "FMS with PMA, exam, SIPG, PNA, awards."),
            PromotionRank(payGrade: "E-6", abbreviation: "PO1", title: "Petty Officer First Class", minTIS: 36, minTIG: 36, systemType: .navyFMS, maxPoints: nil, notes: "FMS with higher competition."),
            PromotionRank(payGrade: "E-7", abbreviation: "CPO", title: "Chief Petty Officer", minTIS: 84, minTIG: 36, systemType: .selectionBoard, maxPoints: nil, notes: "Selection board.")
        ],
        accentColor: "#1B2A4A",
        systemName: "Final Multiple Score",
        systemDescription: "Navy advancement combines PMA, exam results, awards, SIPG, and PNA points.",
        officialReference: "MILPERSMAN 1430-010",
        resources: [
            PromotionResource(title: "NPC Advancement", subtitle: "mynavyhr.navy.mil", url: "https://www.mynavyhr.navy.mil/Career-Management/Advancement/", icon: "anchor"),
            PromotionResource(title: "NETPDTC Study Materials", subtitle: "Exam prep", url: "https://www.netc.navy.mil/centers/netpdtc/", icon: "book.fill")
        ]
    )

    static let marines = BranchPromotionConfig(
        branch: .marines,
        systemType: .marineComposite,
        rankStructure: [
            PromotionRank(payGrade: "E-4", abbreviation: "LCpl", title: "Lance Corporal", minTIS: 9, minTIG: 8, systemType: .marineComposite, maxPoints: 1000, notes: "Composite score with PRO/CON, PFT, CFT, rifle, and MCI."),
            PromotionRank(payGrade: "E-5", abbreviation: "Cpl", title: "Corporal", minTIS: 24, minTIG: 12, systemType: .marineComposite, maxPoints: 1000, notes: "Composite score with published cutting score."),
            PromotionRank(payGrade: "E-6", abbreviation: "Sgt", title: "Sergeant", minTIS: 36, minTIG: 12, systemType: .marineComposite, maxPoints: 1000, notes: "Composite score with MOS-specific competition."),
            PromotionRank(payGrade: "E-7", abbreviation: "SSgt", title: "Staff Sergeant", minTIS: 60, minTIG: 24, systemType: .selectionBoard, maxPoints: nil, notes: "Selection board.")
        ],
        accentColor: "#A0001C",
        systemName: "Composite Score",
        systemDescription: "USMC composite score blends performance marks, fitness, rifle qualification, and MCI credits.",
        officialReference: "MCO P1400.32D",
        resources: [
            PromotionResource(title: "MMPR Promotions", subtitle: "manpower.usmc.mil", url: "https://www.manpower.usmc.mil", icon: "star.fill"),
            PromotionResource(title: "Monthly Cutting Scores", subtitle: "Current cutoffs", url: "https://www.manpower.usmc.mil", icon: "chart.bar.fill")
        ]
    )

    static let spaceForce = BranchPromotionConfig(
        branch: .spaceForce,
        systemType: .waps,
        rankStructure: [
            PromotionRank(payGrade: "E-5", abbreviation: "Spc5", title: "Specialist 5", minTIS: 36, minTIG: 6, systemType: .waps, maxPoints: 250, notes: "Guardian WAPS-style score."),
            PromotionRank(payGrade: "E-6", abbreviation: "Spc6", title: "Specialist 6", minTIS: 60, minTIG: 23, systemType: .waps, maxPoints: 250, notes: "Guardian WAPS with space-specific knowledge weighting."),
            PromotionRank(payGrade: "E-7", abbreviation: "Spc7", title: "Specialist 7", minTIS: 96, minTIG: 24, systemType: .waps, maxPoints: 250, notes: "Guardian WAPS."),
            PromotionRank(payGrade: "E-8", abbreviation: "Spc8", title: "Specialist 8", minTIS: 144, minTIG: 20, systemType: .waps, maxPoints: 250, notes: "Guardian WAPS."),
            PromotionRank(payGrade: "E-9", abbreviation: "Spc9", title: "Specialist 9", minTIS: 180, minTIG: 21, systemType: .selectionBoard, maxPoints: nil, notes: "Selection board.")
        ],
        accentColor: "#1B2559",
        systemName: "Guardian Promotion System",
        systemDescription: "The Space Force uses a WAPS-style scoring model with Space Force-specific knowledge and performance inputs.",
        officialReference: "DAFI 36-2502",
        resources: [
            PromotionResource(title: "Space Force Talent Management", subtitle: "spaceforce.mil", url: "https://www.spaceforce.mil/", icon: "sparkles"),
            PromotionResource(title: "Guardian Development", subtitle: "Career development guidance", url: "https://www.spaceforce.mil/News/", icon: "person.fill.checkmark")
        ]
    )

    static let coastGuard = BranchPromotionConfig(
        branch: .coastGuard,
        systemType: .coastGuardSWE,
        rankStructure: [
            PromotionRank(payGrade: "E-4", abbreviation: "PO3", title: "Petty Officer Third Class", minTIS: 12, minTIG: 12, systemType: .coastGuardSWE, maxPoints: nil, notes: "SWE plus performance factor."),
            PromotionRank(payGrade: "E-5", abbreviation: "PO2", title: "Petty Officer Second Class", minTIS: 36, minTIG: 24, systemType: .coastGuardSWE, maxPoints: nil, notes: "SWE plus evaluation factor."),
            PromotionRank(payGrade: "E-6", abbreviation: "PO1", title: "Petty Officer First Class", minTIS: 60, minTIG: 36, systemType: .coastGuardSWE, maxPoints: nil, notes: "SWE-based advancement."),
            PromotionRank(payGrade: "E-7", abbreviation: "CPO", title: "Chief Petty Officer", minTIS: 84, minTIG: 36, systemType: .selectionBoard, maxPoints: nil, notes: "Selection board.")
        ],
        accentColor: "#003087",
        systemName: "Servicewide Exam",
        systemDescription: "SWE raw score combines with performance factor for Coast Guard advancement.",
        officialReference: "COMDTINST M1000.2",
        resources: [
            PromotionResource(title: "PSC EPM Promotions", subtitle: "dcms.uscg.mil", url: "https://www.dcms.uscg.mil", icon: "star.circle.fill"),
            PromotionResource(title: "SWE Study Materials", subtitle: "Advancement bibliography", url: "https://www.dcms.uscg.mil", icon: "book.fill")
        ]
    )

    var boardTips: [PromotionBoardTip] {
        switch branch {
        case .army:
            return [
                PromotionBoardTip(title: "Max ACFT if possible", body: "Army ACFT points are a direct scoring category for E-5 and E-6 boards.", priority: .high),
                PromotionBoardTip(title: "Track MOS cutoff monthly", body: "Use the latest published MOS cutoff before judging readiness.", priority: .critical),
                PromotionBoardTip(title: "Audit awards and school completions", body: "Military education and awards can move your total quickly.", priority: .medium)
            ]
        case .airForce, .spaceForce:
            return [
                PromotionBoardTip(title: "Study SKT/PFE early", body: "Test performance is still a major driver of WAPS-style scoring.", priority: .critical),
                PromotionBoardTip(title: "Watch EPR weighting", body: "Performance reports materially affect your promotion competitiveness.", priority: .high),
                PromotionBoardTip(title: "Capture decorations and AFADCONS", body: "These smaller categories still matter on tight cutoffs.", priority: .medium)
            ]
        case .navy:
            return [
                PromotionBoardTip(title: "Protect your PMA", body: "PMA conversion has a big impact on Final Multiple Score.", priority: .critical),
                PromotionBoardTip(title: "Track exam cycles", body: "Use cycle timing to plan study windows and competitiveness.", priority: .high),
                PromotionBoardTip(title: "Keep PNA context", body: "PNA points can help you close small score gaps over time.", priority: .medium)
            ]
        case .marines:
            return [
                PromotionBoardTip(title: "Keep PFT and CFT current", body: "Both fitness events affect the composite score.", priority: .critical),
                PromotionBoardTip(title: "Rifle qualification matters", body: "Expert and sharpshooter scores directly improve your composite total.", priority: .high),
                PromotionBoardTip(title: "MCI work still counts", body: "Education credit can be useful when scores are close.", priority: .medium)
            ]
        case .coastGuard:
            return [
                PromotionBoardTip(title: "Prepare for the SWE", body: "Raw exam score remains the backbone of advancement readiness.", priority: .critical),
                PromotionBoardTip(title: "Protect your eval average", body: "Performance factor can meaningfully shift your final score.", priority: .high),
                PromotionBoardTip(title: "Track published cut scores", body: "Use current cutoffs to know whether you are within range.", priority: .medium)
            ]
        }
    }
}
