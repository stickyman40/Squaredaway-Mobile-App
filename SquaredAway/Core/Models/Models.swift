import Foundation

struct UserProfile: Codable, Identifiable {
    let id: UUID
    var email: String
    var branch: MilitaryBranch?
    var branchLocked: Bool?
    var rank: String?
    var mos: String?
    var discoverySource: DiscoverySource?
    var discoveryNotes: String?
    var firstName: String
    var lastName: String
    var heightCm: Double?
    var weightKg: Double?
    var fitnessGoal: FitnessGoal?
    var onboardingComplete: Bool
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case branch
        case branchLocked = "branch_locked"
        case rank
        case mos
        case discoverySource = "discovery_source"
        case discoveryNotes = "discovery_notes"
        case firstName = "first_name"
        case lastName = "last_name"
        case heightCm = "height_cm"
        case weightKg = "weight_kg"
        case fitnessGoal = "fitness_goal"
        case onboardingComplete = "onboarding_complete"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct OnboardingProfileDraft: Equatable {
    var firstName = ""
    var lastName = ""
    var branch: MilitaryBranch = .army
    var rank = ""
    var mos = ""
    var discoverySource: DiscoverySource = .appStore
    var discoveryNotes = ""
    var heightCm = ""
    var weightKg = ""
    var fitnessGoal: FitnessGoal = .improveScore
}

enum MilitaryBranch: String, CaseIterable, Codable {
    case army = "Army"
    case airForce = "Air Force"
    case navy = "Navy"
    case marines = "Marines"
    case spaceForce = "Space Force"
    case coastGuard = "Coast Guard"

    var icon: String {
        switch self {
        case .army:
            return "shield.fill"
        case .airForce:
            return "airplane"
        case .navy:
            return "anchor"
        case .marines:
            return "star.fill"
        case .spaceForce:
            return "sparkles"
        case .coastGuard:
            return "water.waves"
        }
    }

    var mosLabel: String {
        switch self {
        case .army, .marines:
            return "MOS"
        case .airForce, .spaceForce:
            return "AFSC"
        case .navy:
            return "Rate"
        case .coastGuard:
            return "Rating"
        }
    }

    var color: String {
        switch self {
        case .army:
            return "#4A7C59"
        case .airForce:
            return "#004990"
        case .navy:
            return "#1B2A4A"
        case .marines:
            return "#A0001C"
        case .spaceForce:
            return "#1B2559"
        case .coastGuard:
            return "#003087"
        }
    }
}

struct MilitarySpecialty: Identifiable, Hashable {
    let code: String
    let title: String

    var id: String { code }
    var displayName: String { "\(code) · \(title)" }
}

extension MilitaryBranch {
    var rankOptions: [String] {
        switch self {
        case .army:
            return [
                "Private (E-1)", "Private (E-2)", "Private First Class (E-3)", "Specialist (E-4)",
                "Corporal (E-4)", "Sergeant (E-5)", "Staff Sergeant (E-6)",
                "Sergeant First Class (E-7)", "Master Sergeant (E-8)", "First Sergeant (E-8)",
                "Sergeant Major (E-9)", "Command Sergeant Major (E-9)",
                "Sergeant Major of the Army (E-9S)", "Warrant Officer 1 (W-1)",
                "Chief Warrant Officer 2 (W-2)", "Chief Warrant Officer 3 (W-3)",
                "Chief Warrant Officer 4 (W-4)", "Chief Warrant Officer 5 (W-5)",
                "Second Lieutenant (O-1)", "First Lieutenant (O-2)", "Captain (O-3)",
                "Major (O-4)", "Lieutenant Colonel (O-5)", "Colonel (O-6)",
                "Brigadier General (O-7)", "Major General (O-8)", "Lieutenant General (O-9)",
                "General (O-10)", "General of the Army"
            ]
        case .airForce:
            return [
                "Airman Basic (E-1)", "Airman (E-2)", "Airman First Class (E-3)",
                "Senior Airman (E-4)", "Staff Sergeant (E-5)", "Technical Sergeant (E-6)",
                "Master Sergeant (E-7)", "Senior Master Sergeant (E-8)",
                "Chief Master Sergeant (E-9)", "Command Chief Master Sergeant (E-9)",
                "Chief Master Sergeant of the Air Force", "Second Lieutenant (O-1)",
                "First Lieutenant (O-2)", "Captain (O-3)", "Major (O-4)",
                "Lieutenant Colonel (O-5)", "Colonel (O-6)", "Brigadier General (O-7)",
                "Major General (O-8)", "Lieutenant General (O-9)", "General (O-10)"
            ]
        case .navy:
            return [
                "Seaman Recruit (E-1)", "Seaman Apprentice (E-2)", "Seaman (E-3)",
                "Petty Officer Third Class (E-4)", "Petty Officer Second Class (E-5)",
                "Petty Officer First Class (E-6)", "Chief Petty Officer (E-7)",
                "Senior Chief Petty Officer (E-8)", "Master Chief Petty Officer (E-9)",
                "Command Master Chief Petty Officer (E-9)", "Fleet Master Chief Petty Officer",
                "Master Chief Petty Officer of the Navy", "Ensign (O-1)",
                "Lieutenant Junior Grade (O-2)", "Lieutenant (O-3)",
                "Lieutenant Commander (O-4)", "Commander (O-5)", "Captain (O-6)",
                "Rear Admiral Lower Half (O-7)", "Rear Admiral Upper Half (O-8)",
                "Vice Admiral (O-9)", "Admiral (O-10)", "Fleet Admiral"
            ]
        case .marines:
            return [
                "Private (E-1)", "Private First Class (E-2)", "Lance Corporal (E-3)",
                "Corporal (E-4)", "Sergeant (E-5)", "Staff Sergeant (E-6)",
                "Gunnery Sergeant (E-7)", "Master Sergeant (E-8)", "First Sergeant (E-8)",
                "Master Gunnery Sergeant (E-9)", "Sergeant Major (E-9)",
                "Sergeant Major of the Marine Corps", "Warrant Officer 1 (W-1)",
                "Chief Warrant Officer 2 (W-2)", "Chief Warrant Officer 3 (W-3)",
                "Chief Warrant Officer 4 (W-4)", "Chief Warrant Officer 5 (W-5)",
                "Second Lieutenant (O-1)", "First Lieutenant (O-2)", "Captain (O-3)",
                "Major (O-4)", "Lieutenant Colonel (O-5)", "Colonel (O-6)",
                "Brigadier General (O-7)", "Major General (O-8)", "Lieutenant General (O-9)",
                "General (O-10)"
            ]
        case .spaceForce:
            return [
                "Specialist 1 (E-1)", "Specialist 2 (E-2)", "Specialist 3 (E-3)",
                "Specialist 4 (E-4)", "Sergeant (E-5)", "Technical Sergeant (E-6)",
                "Master Sergeant (E-7)", "Senior Master Sergeant (E-8)",
                "Chief Master Sergeant (E-9)", "Chief Master Sergeant of the Space Force",
                "Second Lieutenant (O-1)", "First Lieutenant (O-2)", "Captain (O-3)",
                "Major (O-4)", "Lieutenant Colonel (O-5)", "Colonel (O-6)",
                "Brigadier General (O-7)", "Major General (O-8)", "Lieutenant General (O-9)",
                "General (O-10)"
            ]
        case .coastGuard:
            return [
                "Seaman Recruit (E-1)", "Seaman Apprentice (E-2)", "Seaman (E-3)",
                "Petty Officer Third Class (E-4)", "Petty Officer Second Class (E-5)",
                "Petty Officer First Class (E-6)", "Chief Petty Officer (E-7)",
                "Senior Chief Petty Officer (E-8)", "Master Chief Petty Officer (E-9)",
                "Command Master Chief Petty Officer", "Master Chief Petty Officer of the Coast Guard",
                "Chief Warrant Officer 2 (W-2)", "Chief Warrant Officer 3 (W-3)",
                "Chief Warrant Officer 4 (W-4)", "Ensign (O-1)",
                "Lieutenant Junior Grade (O-2)", "Lieutenant (O-3)",
                "Lieutenant Commander (O-4)", "Commander (O-5)", "Captain (O-6)",
                "Rear Admiral Lower Half (O-7)", "Rear Admiral Upper Half (O-8)",
                "Vice Admiral (O-9)", "Admiral (O-10)"
            ]
        }
    }

    var specialtyOptions: [MilitarySpecialty] {
        switch self {
        case .army:
            return [
                MilitarySpecialty(code: "11B", title: "Infantryman"),
                MilitarySpecialty(code: "11C", title: "Indirect Fire Infantryman"),
                MilitarySpecialty(code: "12B", title: "Combat Engineer"),
                MilitarySpecialty(code: "13B", title: "Cannon Crewmember"),
                MilitarySpecialty(code: "19D", title: "Cavalry Scout"),
                MilitarySpecialty(code: "25B", title: "Information Technology Specialist"),
                MilitarySpecialty(code: "25U", title: "Signal Support Systems Specialist"),
                MilitarySpecialty(code: "31B", title: "Military Police"),
                MilitarySpecialty(code: "35F", title: "Intelligence Analyst"),
                MilitarySpecialty(code: "35N", title: "Signals Intelligence Analyst"),
                MilitarySpecialty(code: "42A", title: "Human Resources Specialist"),
                MilitarySpecialty(code: "56M", title: "Religious Affairs Specialist"),
                MilitarySpecialty(code: "68W", title: "Combat Medic Specialist"),
                MilitarySpecialty(code: "74D", title: "Chemical Operations Specialist"),
                MilitarySpecialty(code: "88M", title: "Motor Transport Operator"),
                MilitarySpecialty(code: "91B", title: "Wheeled Vehicle Mechanic"),
                MilitarySpecialty(code: "92A", title: "Automated Logistical Specialist"),
                MilitarySpecialty(code: "92G", title: "Culinary Specialist"),
                MilitarySpecialty(code: "92Y", title: "Unit Supply Specialist")
            ]
        case .airForce:
            return [
                MilitarySpecialty(code: "1D7X1", title: "Cyber Defense Operations"),
                MilitarySpecialty(code: "1N0X1", title: "All-Source Intelligence Analyst"),
                MilitarySpecialty(code: "1N1X1", title: "Geospatial Intelligence"),
                MilitarySpecialty(code: "1N4X1", title: "Cyber Intelligence"),
                MilitarySpecialty(code: "2A5X1", title: "Aerospace Maintenance"),
                MilitarySpecialty(code: "2A6X1", title: "Aerospace Propulsion"),
                MilitarySpecialty(code: "2T2X1", title: "Air Transportation"),
                MilitarySpecialty(code: "2W0X1", title: "Munitions Systems"),
                MilitarySpecialty(code: "3E7X1", title: "Fire Protection"),
                MilitarySpecialty(code: "3F0X1", title: "Personnel"),
                MilitarySpecialty(code: "3F1X1", title: "Services"),
                MilitarySpecialty(code: "3P0X1", title: "Security Forces"),
                MilitarySpecialty(code: "4N0X1", title: "Aerospace Medical Service"),
                MilitarySpecialty(code: "4A0X1", title: "Health Services Management"),
                MilitarySpecialty(code: "6C0X1", title: "Contracting"),
                MilitarySpecialty(code: "6F0X1", title: "Financial Management"),
                MilitarySpecialty(code: "6R0X1", title: "Protocol"),
                MilitarySpecialty(code: "9S100", title: "Scientific Applications Specialist")
            ]
        case .navy:
            return [
                MilitarySpecialty(code: "ABH", title: "Aviation Boatswain's Mate - Handling"),
                MilitarySpecialty(code: "BM", title: "Boatswain's Mate"),
                MilitarySpecialty(code: "CTI", title: "Cryptologic Technician Interpretive"),
                MilitarySpecialty(code: "EM", title: "Electrician's Mate"),
                MilitarySpecialty(code: "ET", title: "Electronics Technician"),
                MilitarySpecialty(code: "HM", title: "Hospital Corpsman"),
                MilitarySpecialty(code: "IT", title: "Information Systems Technician"),
                MilitarySpecialty(code: "LS", title: "Logistics Specialist"),
                MilitarySpecialty(code: "MA", title: "Master-at-Arms"),
                MilitarySpecialty(code: "MM", title: "Machinist's Mate"),
                MilitarySpecialty(code: "MN", title: "Mineman"),
                MilitarySpecialty(code: "OS", title: "Operations Specialist"),
                MilitarySpecialty(code: "QM", title: "Quartermaster"),
                MilitarySpecialty(code: "STG", title: "Sonar Technician Surface"),
                MilitarySpecialty(code: "SW", title: "Steelworker"),
                MilitarySpecialty(code: "YN", title: "Yeoman")
            ]
        case .marines:
            return [
                MilitarySpecialty(code: "0111", title: "Administrative Specialist"),
                MilitarySpecialty(code: "0231", title: "Intelligence Specialist"),
                MilitarySpecialty(code: "0311", title: "Rifleman"),
                MilitarySpecialty(code: "0331", title: "Machine Gunner"),
                MilitarySpecialty(code: "0341", title: "Mortarman"),
                MilitarySpecialty(code: "0352", title: "Anti-Tank Missile Gunner"),
                MilitarySpecialty(code: "0621", title: "Field Radio Operator"),
                MilitarySpecialty(code: "0671", title: "Data Systems Administrator"),
                MilitarySpecialty(code: "0811", title: "Field Artillery Cannoneer"),
                MilitarySpecialty(code: "1141", title: "Electrician"),
                MilitarySpecialty(code: "1341", title: "Engineer Equipment Mechanic"),
                MilitarySpecialty(code: "1391", title: "Bulk Fuel Specialist"),
                MilitarySpecialty(code: "1721", title: "Cyberspace Warfare Operator"),
                MilitarySpecialty(code: "3531", title: "Motor Vehicle Operator"),
                MilitarySpecialty(code: "5811", title: "Military Police"),
                MilitarySpecialty(code: "6174", title: "Helicopter Crew Chief"),
                MilitarySpecialty(code: "6842", title: "METOC Analyst Forecaster"),
                MilitarySpecialty(code: "7236", title: "Tactical Air Defense Controller")
            ]
        case .spaceForce:
            return [
                MilitarySpecialty(code: "13S", title: "Space Operations Officer"),
                MilitarySpecialty(code: "14N", title: "Intelligence Officer"),
                MilitarySpecialty(code: "17D", title: "Cyber Operations Officer"),
                MilitarySpecialty(code: "17S", title: "Cyber Warfare Officer"),
                MilitarySpecialty(code: "5C031", title: "Cyber Defense Operations"),
                MilitarySpecialty(code: "5C032", title: "Cyber Systems Operations"),
                MilitarySpecialty(code: "5I031", title: "All Source Intelligence"),
                MilitarySpecialty(code: "5I131", title: "Geospatial Intelligence"),
                MilitarySpecialty(code: "5S031", title: "Space Systems Operations"),
                MilitarySpecialty(code: "5S071", title: "Orbital Warfare"),
                MilitarySpecialty(code: "5S111", title: "Space Electronic Warfare"),
                MilitarySpecialty(code: "62E", title: "Developmental Engineer"),
                MilitarySpecialty(code: "63A", title: "Acquisition Manager"),
                MilitarySpecialty(code: "64P", title: "Contracting Officer"),
                MilitarySpecialty(code: "65F", title: "Financial Management Officer")
            ]
        case .coastGuard:
            return [
                MilitarySpecialty(code: "BM", title: "Boatswain's Mate"),
                MilitarySpecialty(code: "CS", title: "Culinary Specialist"),
                MilitarySpecialty(code: "DC", title: "Damage Controlman"),
                MilitarySpecialty(code: "ET", title: "Electronics Technician"),
                MilitarySpecialty(code: "GM", title: "Gunner's Mate"),
                MilitarySpecialty(code: "HS", title: "Health Services Technician"),
                MilitarySpecialty(code: "IT", title: "Information Systems Technician"),
                MilitarySpecialty(code: "ME", title: "Maritime Enforcement Specialist"),
                MilitarySpecialty(code: "MK", title: "Machinery Technician"),
                MilitarySpecialty(code: "MST", title: "Marine Science Technician"),
                MilitarySpecialty(code: "OS", title: "Operations Specialist"),
                MilitarySpecialty(code: "PA", title: "Public Affairs Specialist"),
                MilitarySpecialty(code: "SK", title: "Storekeeper"),
                MilitarySpecialty(code: "AMT", title: "Aviation Maintenance Technician"),
                MilitarySpecialty(code: "AET", title: "Avionics Electrical Technician"),
                MilitarySpecialty(code: "AST", title: "Aviation Survival Technician"),
                MilitarySpecialty(code: "YN", title: "Yeoman")
            ]
        }
    }
}

enum FitnessGoal: String, CaseIterable, Codable {
    case passAPFT = "Pass APFT/AFT"
    case improveScore = "Improve Score"
    case loseWeight = "Lose Weight"
    case gainStrength = "Gain Strength"
    case maintain = "Maintain Fitness"
}

enum DiscoverySource: String, CaseIterable, Codable {
    case appStore = "App Store"
    case friend = "Friend or Family"
    case unit = "Unit / Command"
    case socialMedia = "Social Media"
    case search = "Web Search"
    case creator = "Creator / Content"
    case other = "Other"
}

enum AuthState: Equatable {
    case unknown
    case unauthenticated
    case pendingVerification(email: String)
    case passwordRecovery
    case needsOnboarding
    case authenticated
}

enum AppError: LocalizedError, Equatable {
    case authFailed(String)
    case networkError
    case profileNotFound
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .authFailed(let message):
            return message
        case .networkError:
            return "Check your connection and try again."
        case .profileNotFound:
            return "Profile not found. Please contact support."
        case .unknown(let message):
            return message
        }
    }
}

struct FitnessLog: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let exerciseType: String
    let duration: Int
    let score: Double?
    let notes: String?
    let loggedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case exerciseType = "exercise_type"
        case duration
        case score
        case notes
        case loggedAt = "logged_at"
    }
}

struct FitnessLogDraft: Equatable {
    var exerciseType = "AFT"
    var duration = ""
    var score = ""
    var notes = ""
}

struct NutritionLog: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let mealType: MealType
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let notes: String?
    let loggedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case mealType = "meal_type"
        case calories
        case protein
        case carbs
        case fat
        case notes
        case loggedAt = "logged_at"
    }
}

struct NutritionLogDraft: Equatable {
    var mealType: MealType = .breakfast
    var calories = ""
    var protein = ""
    var carbs = ""
    var fat = ""
    var notes = ""
}

enum MealType: String, CaseIterable, Codable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"
}

extension MealType {
    var icon: String {
        switch self {
        case .breakfast:
            return "sun.horizon.fill"
        case .lunch:
            return "sun.max.fill"
        case .dinner:
            return "moon.fill"
        case .snack:
            return "leaf.fill"
        }
    }

    var timeRange: String {
        switch self {
        case .breakfast:
            return "6-10 AM"
        case .lunch:
            return "11 AM-2 PM"
        case .dinner:
            return "5-9 PM"
        case .snack:
            return "Any time"
        }
    }
}

struct PromotionData: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var branch: MilitaryBranch
    var currentPayGrade: String
    var targetPayGrade: String
    var monthsInService: Int
    var monthsInGrade: Int

    var armyMilEdPts: Int? = nil
    var armyCivEdPts: Int? = nil
    var armyAwardsPts: Int? = nil
    var armyMilTrgPts: Int? = nil
    var armyAftPts: Int? = nil
    var armyWeaponsPts: Int? = nil
    var armyMosCutoff: Int? = nil
    var armyMos: String? = nil

    var wapsSktRaw: Int? = nil
    var wapsPfeRaw: Int? = nil
    var wapsEprRating: Int? = nil
    var wapsDecorationsPts: Int? = nil
    var wapsAfadconsPts: Int? = nil
    var wapsTisYears: Int? = nil
    var wapsTigMonths: Int? = nil
    var wapsCutoffPublished: Int? = nil

    var navyPma: Double? = nil
    var navyExamRaw: Int? = nil
    var navyAwardsPts: Int? = nil
    var navySipgYears: Double? = nil
    var navyPnaAttempts: Int? = nil

    var marineProMark: Double? = nil
    var marineConMark: Double? = nil
    var marinePftRaw: Int? = nil
    var marineCftRaw: Int? = nil
    var marineRifleQual: Int? = nil
    var marineMciCredits: Int? = nil
    var marineCutScore: Int? = nil

    var cgSweRaw: Int? = nil
    var cgPerfFactor: Double? = nil
    var cgCutScore: Int? = nil

    var nextBoardDate: Date? = nil
    var boardNotes: String? = nil
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case branch
        case currentPayGrade = "current_pay_grade"
        case targetPayGrade = "target_pay_grade"
        case monthsInService = "months_in_service"
        case monthsInGrade = "months_in_grade"
        case armyMilEdPts = "army_mil_ed_pts"
        case armyCivEdPts = "army_civ_ed_pts"
        case armyAwardsPts = "army_awards_pts"
        case armyMilTrgPts = "army_mil_trg_pts"
        case armyAftPts = "army_aft_pts"
        case armyWeaponsPts = "army_weapons_pts"
        case armyMosCutoff = "army_mos_cutoff"
        case armyMos = "army_mos"
        case wapsSktRaw = "waps_skt_raw"
        case wapsPfeRaw = "waps_pfe_raw"
        case wapsEprRating = "waps_epr_rating"
        case wapsDecorationsPts = "waps_decorations_pts"
        case wapsAfadconsPts = "waps_afadcons_pts"
        case wapsTisYears = "waps_tis_years"
        case wapsTigMonths = "waps_tig_months"
        case wapsCutoffPublished = "waps_cutoff_published"
        case navyPma = "navy_pma"
        case navyExamRaw = "navy_exam_raw"
        case navyAwardsPts = "navy_awards_pts"
        case navySipgYears = "navy_sipg_years"
        case navyPnaAttempts = "navy_pna_attempts"
        case marineProMark = "marine_pro_mark"
        case marineConMark = "marine_con_mark"
        case marinePftRaw = "marine_pft_raw"
        case marineCftRaw = "marine_cft_raw"
        case marineRifleQual = "marine_rifle_qual"
        case marineMciCredits = "marine_mci_credits"
        case marineCutScore = "marine_cut_score"
        case cgSweRaw = "cg_swe_raw"
        case cgPerfFactor = "cg_perf_factor"
        case cgCutScore = "cg_cut_score"
        case nextBoardDate = "next_board_date"
        case boardNotes = "board_notes"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct PromotionDraft: Equatable {
    var currentRank = ""
    var targetRank = ""
    var pointsCurrent = ""
    var pointsRequired = ""
    var hasBoardDate = false
    var boardDate = Date()
    var notes = ""
}

struct PayData: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var payGrade: String
    var basePay: Double
    var bah: Double
    var bas: Double
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case payGrade = "pay_grade"
        case basePay = "base_pay"
        case bah
        case bas
        case updatedAt = "updated_at"
    }
}

struct PayDraft: Equatable {
    var payGrade = ""
    var basePay = ""
    var bah = ""
    var bas = ""
}

struct TrackerData: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var currentDutyStation: String
    var dutyStatus: String
    var nextMilestone: String
    var reportDate: Date?
    var notes: String?
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case currentDutyStation = "current_duty_station"
        case dutyStatus = "duty_status"
        case nextMilestone = "next_milestone"
        case reportDate = "report_date"
        case notes
        case updatedAt = "updated_at"
    }
}

struct TrackerDraft: Equatable {
    var currentDutyStation = ""
    var dutyStatus = ""
    var nextMilestone = ""
    var hasReportDate = false
    var reportDate = Date()
    var notes = ""
}

struct PCSData: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var originLocation: String
    var destinationLocation: String
    var moveDate: Date?
    var shipmentBooked: Bool
    var lodgingSecured: Bool
    var travelBooked: Bool
    var notes: String?
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case originLocation = "origin_location"
        case destinationLocation = "destination_location"
        case moveDate = "move_date"
        case shipmentBooked = "shipment_booked"
        case lodgingSecured = "lodging_secured"
        case travelBooked = "travel_booked"
        case notes
        case updatedAt = "updated_at"
    }
}

struct PCSDraft: Equatable {
    var originLocation = ""
    var destinationLocation = ""
    var hasMoveDate = false
    var moveDate = Date()
    var shipmentBooked = false
    var lodgingSecured = false
    var travelBooked = false
    var notes = ""
}

struct BenefitsData: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var vaHealthEnrolled: Bool
    var giBillReady: Bool
    var tspContributing: Bool
    var familySupportPlan: Bool
    var notes: String?
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case vaHealthEnrolled = "va_health_enrolled"
        case giBillReady = "gi_bill_ready"
        case tspContributing = "tsp_contributing"
        case familySupportPlan = "family_support_plan"
        case notes
        case updatedAt = "updated_at"
    }
}

struct BenefitsDraft: Equatable {
    var vaHealthEnrolled = false
    var giBillReady = false
    var tspContributing = false
    var familySupportPlan = false
    var notes = ""
}

struct ProfileSettingsDraft: Equatable {
    var firstName = ""
    var lastName = ""
    var branch: MilitaryBranch = .army
    var rank = ""
    var mos = ""
    var discoverySource: DiscoverySource = .appStore
    var discoveryNotes = ""
    var heightCm = ""
    var weightKg = ""
    var fitnessGoal: FitnessGoal = .improveScore
}

struct AppNotification: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var type: String
    var title: String
    var body: String
    var isRead: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case type
        case title
        case body
        case isRead = "is_read"
        case createdAt = "created_at"
    }
}

struct NotificationPreferenceRecord: Codable, Identifiable {
    let userId: UUID
    var milestonesEnabled: Bool
    var readinessEnabled: Bool
    var activityEnabled: Bool
    let createdAt: Date
    var updatedAt: Date

    var id: UUID { userId }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case milestonesEnabled = "milestones_enabled"
        case readinessEnabled = "readiness_enabled"
        case activityEnabled = "activity_enabled"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
