import Foundation

struct UserProfile: Codable, Identifiable {
    let id: UUID
    var email: String
    var branch: MilitaryBranch?
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
}

enum FitnessGoal: String, CaseIterable, Codable {
    case passAPFT = "Pass APFT/ACFT"
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
    var exerciseType = "ACFT"
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

struct PromotionData: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var currentRank: String
    var targetRank: String
    var pointsCurrent: Int
    var pointsRequired: Int
    var boardDate: Date?
    var notes: String?
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case currentRank = "current_rank"
        case targetRank = "target_rank"
        case pointsCurrent = "points_current"
        case pointsRequired = "points_required"
        case boardDate = "board_date"
        case notes
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
    var title: String
    var body: String
    var isRead: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
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
