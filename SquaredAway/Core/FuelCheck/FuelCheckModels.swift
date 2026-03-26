import Foundation
import SwiftUI

struct FuelProduct: Decodable, Identifiable, Hashable {
    let id: UUID
    let barcode: String
    let name: String
    let brand: String?
    let imageURL: String?
    let category: ProductCategory
    let servingSize: String
    let servingSizeGrams: Double
    let nutrition: ProductNutrition
    var scores: ProductScores?
    var ingredientFlags: [IngredientFlag]
    let dataSource: ProductDataSource
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case barcode
        case name
        case brand
        case imageURL = "image_url"
        case category
        case servingSize = "serving_size"
        case servingSizeGrams = "serving_size_g"
        case nutrition
        case scores
        case fuelProductScores = "fuel_product_scores"
        case ingredientFlags = "flags"
        case dataSource = "data_source"
        case createdAt = "created_at"
    }

    init(
        id: UUID,
        barcode: String,
        name: String,
        brand: String?,
        imageURL: String?,
        category: ProductCategory,
        servingSize: String,
        servingSizeGrams: Double,
        nutrition: ProductNutrition,
        scores: ProductScores?,
        ingredientFlags: [IngredientFlag],
        dataSource: ProductDataSource,
        createdAt: Date
    ) {
        self.id = id
        self.barcode = barcode
        self.name = name
        self.brand = brand
        self.imageURL = imageURL
        self.category = category
        self.servingSize = servingSize
        self.servingSizeGrams = servingSizeGrams
        self.nutrition = nutrition
        self.scores = scores
        self.ingredientFlags = ingredientFlags
        self.dataSource = dataSource
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        barcode = try container.decodeIfPresent(String.self, forKey: .barcode) ?? ""
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Unknown Product"
        brand = try container.decodeIfPresent(String.self, forKey: .brand)
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        category = try container.decodeIfPresent(ProductCategory.self, forKey: .category) ?? .other
        servingSize = try container.decodeIfPresent(String.self, forKey: .servingSize) ?? "1 serving"
        servingSizeGrams = try container.decodeIfPresent(Double.self, forKey: .servingSizeGrams) ?? 0
        nutrition = try container.decodeIfPresent(ProductNutrition.self, forKey: .nutrition) ?? .empty
        let directScores = try container.decodeIfPresent(ProductScores.self, forKey: .scores)
        let relatedScores = try container.decodeOneOrFirstIfPresent(ProductScores.self, forKey: .fuelProductScores)
        scores = directScores ?? relatedScores
        ingredientFlags = try container.decodeIfPresent([IngredientFlag].self, forKey: .ingredientFlags) ?? []
        dataSource = try container.decodeIfPresent(ProductDataSource.self, forKey: .dataSource) ?? .cached
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }
}

struct ProductNutrition: Codable, Hashable {
    let calories: Double
    let proteinG: Double
    let carbsG: Double
    let fatG: Double
    let saturatedFatG: Double?
    let fiberG: Double?
    let sugarG: Double?
    let sodiumMg: Double?
    let cholesterolMg: Double?
    let potassiumMg: Double?
    let calPer100g: Double?
    let proteinPer100g: Double?
    let carbsPer100g: Double?
    let fatPer100g: Double?
    let sugarPer100g: Double?
    let sodiumPer100g: Double?

    enum CodingKeys: String, CodingKey {
        case calories
        case proteinG = "protein_g"
        case carbsG = "carbs_g"
        case fatG = "fat_g"
        case saturatedFatG = "saturated_fat_g"
        case fiberG = "fiber_g"
        case sugarG = "sugar_g"
        case sodiumMg = "sodium_mg"
        case cholesterolMg = "cholesterol_mg"
        case potassiumMg = "potassium_mg"
        case calPer100g = "cal_per_100g"
        case proteinPer100g = "protein_per_100g"
        case carbsPer100g = "carbs_per_100g"
        case fatPer100g = "fat_per_100g"
        case sugarPer100g = "sugar_per_100g"
        case sodiumPer100g = "sodium_per_100g"
    }

    static let empty = ProductNutrition(
        calories: 0,
        proteinG: 0,
        carbsG: 0,
        fatG: 0,
        saturatedFatG: nil,
        fiberG: nil,
        sugarG: nil,
        sodiumMg: nil,
        cholesterolMg: nil,
        potassiumMg: nil,
        calPer100g: nil,
        proteinPer100g: nil,
        carbsPer100g: nil,
        fatPer100g: nil,
        sugarPer100g: nil,
        sodiumPer100g: nil
    )

    var proteinCalorieRatio: Double {
        guard calories > 0 else { return 0 }
        return (proteinG * 4) / calories
    }
}

struct ProductScores: Decodable, Hashable {
    let overall: Int
    let fatLoss: Int
    let muscleGain: Int
    let performance: Int
    let convenience: Int
    let rating: FuelRating
    let primaryReason: String
    let factors: [ScoreFactor]
    let goalGuidance: [GoalGuidance]
    let computedAt: Date

    enum CodingKeys: String, CodingKey {
        case overall
        case fatLoss = "fat_loss"
        case muscleGain = "muscle_gain"
        case performance
        case convenience
        case rating
        case fuelRating = "fuel_rating"
        case primaryReason = "primary_reason"
        case factors
        case goalGuidance = "goal_guidance"
        case computedAt = "computed_at"
    }

    init(
        overall: Int,
        fatLoss: Int,
        muscleGain: Int,
        performance: Int,
        convenience: Int,
        rating: FuelRating,
        primaryReason: String,
        factors: [ScoreFactor],
        goalGuidance: [GoalGuidance],
        computedAt: Date
    ) {
        self.overall = overall
        self.fatLoss = fatLoss
        self.muscleGain = muscleGain
        self.performance = performance
        self.convenience = convenience
        self.rating = rating
        self.primaryReason = primaryReason
        self.factors = factors
        self.goalGuidance = goalGuidance
        self.computedAt = computedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        overall = try container.decodeIfPresent(Int.self, forKey: .overall) ?? 0
        fatLoss = try container.decodeIfPresent(Int.self, forKey: .fatLoss) ?? overall
        muscleGain = try container.decodeIfPresent(Int.self, forKey: .muscleGain) ?? overall
        performance = try container.decodeIfPresent(Int.self, forKey: .performance) ?? overall
        convenience = try container.decodeIfPresent(Int.self, forKey: .convenience) ?? overall
        let directRating = try container.decodeIfPresent(FuelRating.self, forKey: .rating)
        let alternateRating = try container.decodeIfPresent(FuelRating.self, forKey: .fuelRating)
        rating = directRating ?? alternateRating ?? FuelRating.from(score: overall)
        primaryReason = try container.decodeIfPresent(String.self, forKey: .primaryReason) ?? "Balanced nutritional profile"
        factors = try container.decodeIfPresent([ScoreFactor].self, forKey: .factors) ?? []
        goalGuidance = try container.decodeIfPresent([GoalGuidance].self, forKey: .goalGuidance) ?? []
        computedAt = try container.decodeIfPresent(Date.self, forKey: .computedAt) ?? Date()
    }

    func score(for goal: UserGoal) -> Int {
        switch goal {
        case .fatLoss:
            return fatLoss
        case .muscleGain:
            return muscleGain
        case .performance:
            return performance
        case .maintenance:
            return overall
        case .highProtein:
            return muscleGain
        case .fieldConvenience:
            return convenience
        }
    }
}

enum FuelRating: String, Codable, CaseIterable, Hashable {
    case green
    case yellow
    case orange
    case red

    var label: String {
        switch self {
        case .green: return "Strong Choice"
        case .yellow: return "Decent Choice"
        case .orange: return "Use Sparingly"
        case .red: return "Poor Fit"
        }
    }

    var shortLabel: String {
        switch self {
        case .green: return "Strong"
        case .yellow: return "Decent"
        case .orange: return "Limit"
        case .red: return "Avoid"
        }
    }

    var color: Color {
        switch self {
        case .green: return Color(hex: "#34C759")
        case .yellow: return Color(hex: "#FFD700")
        case .orange: return Color(hex: "#FF9F0A")
        case .red: return Color(hex: "#FF453A")
        }
    }

    var glowColor: Color { color.opacity(0.25) }
    var bgColor: Color { color.opacity(0.12) }

    var icon: String {
        switch self {
        case .green: return "checkmark.seal.fill"
        case .yellow: return "minus.circle.fill"
        case .orange: return "exclamationmark.circle.fill"
        case .red: return "xmark.circle.fill"
        }
    }

    static func from(score: Int) -> FuelRating {
        switch score {
        case 75...: return .green
        case 50..<75: return .yellow
        case 25..<50: return .orange
        default: return .red
        }
    }
}

struct ScoreFactor: Codable, Identifiable, Hashable {
    let id: UUID
    let label: String
    let detail: String
    let impact: FactorImpact
    let category: FactorCategory

    enum CodingKeys: String, CodingKey {
        case id
        case label
        case detail
        case impact
        case category
    }

    init(id: UUID = UUID(), label: String, detail: String, impact: FactorImpact, category: FactorCategory) {
        self.id = id
        self.label = label
        self.detail = detail
        self.impact = impact
        self.category = category
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        label = try container.decode(String.self, forKey: .label)
        detail = try container.decode(String.self, forKey: .detail)
        impact = try container.decode(FactorImpact.self, forKey: .impact)
        category = try container.decode(FactorCategory.self, forKey: .category)
    }
}

enum FactorImpact: String, Codable, Hashable {
    case positive
    case negative
    case neutral

    var color: Color {
        switch self {
        case .positive: return Color(hex: "#34C759")
        case .negative: return Color(hex: "#FF453A")
        case .neutral: return Color(hex: "#A0A0B8")
        }
    }

    var icon: String {
        switch self {
        case .positive: return "arrow.up.circle.fill"
        case .negative: return "arrow.down.circle.fill"
        case .neutral: return "minus.circle.fill"
        }
    }
}

enum FactorCategory: String, Codable, Hashable {
    case protein
    case sugar
    case fat
    case sodium
    case fiber
    case calories
    case ingredients
    case caffeine
    case overall
}

struct GoalGuidance: Codable, Identifiable, Hashable {
    let id: UUID
    let goal: UserGoal
    let headline: String
    let detail: String
    let rating: FuelRating

    enum CodingKeys: String, CodingKey {
        case id
        case goal
        case headline
        case detail
        case rating
    }

    init(id: UUID = UUID(), goal: UserGoal, headline: String, detail: String, rating: FuelRating) {
        self.id = id
        self.goal = goal
        self.headline = headline
        self.detail = detail
        self.rating = rating
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        goal = try container.decode(UserGoal.self, forKey: .goal)
        headline = try container.decode(String.self, forKey: .headline)
        detail = try container.decode(String.self, forKey: .detail)
        rating = try container.decode(FuelRating.self, forKey: .rating)
    }
}

struct IngredientFlag: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let concern: String
    let severity: FlagSeverity

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case concern
        case severity
    }

    init(id: UUID = UUID(), name: String, concern: String, severity: FlagSeverity) {
        self.id = id
        self.name = name
        self.concern = concern
        self.severity = severity
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        concern = try container.decode(String.self, forKey: .concern)
        severity = try container.decode(FlagSeverity.self, forKey: .severity)
    }
}

enum FlagSeverity: String, Codable, Hashable {
    case low
    case medium
    case high

    var color: Color {
        switch self {
        case .low: return Color(hex: "#FFD700")
        case .medium: return Color(hex: "#FF9F0A")
        case .high: return Color(hex: "#FF453A")
        }
    }
}

enum ProductCategory: String, Codable, Hashable, CaseIterable {
    case protein = "Protein"
    case snack = "Snack"
    case mre = "MRE / Field Ration"
    case drink = "Drink"
    case supplement = "Supplement"
    case meal = "Meal"
    case dairy = "Dairy"
    case grain = "Grain / Bread"
    case fruit = "Fruit"
    case vegetable = "Vegetable"
    case condiment = "Condiment"
    case candy = "Candy / Dessert"
    case fastFood = "Fast Food"
    case frozen = "Frozen Meal"
    case other = "Other"

    var icon: String {
        switch self {
        case .protein: return "figure.strengthtraining.traditional"
        case .snack: return "leaf.fill"
        case .mre: return "bag.fill"
        case .drink: return "drop.fill"
        case .supplement: return "pill.fill"
        case .meal: return "fork.knife"
        case .dairy: return "cup.and.saucer.fill"
        case .grain: return "takeoutbag.and.cup.and.straw.fill"
        case .fruit: return "applelogo"
        case .vegetable: return "carrot.fill"
        case .condiment: return "flame.fill"
        case .candy: return "birthday.cake.fill"
        case .fastFood: return "bag.fill"
        case .frozen: return "snowflake"
        case .other: return "square.grid.2x2.fill"
        }
    }
}

enum ProductDataSource: String, Codable, Hashable {
    case openFoodFacts = "openfoodfacts"
    case usda = "usda"
    case manual = "manual"
    case cached = "cached"
}

enum UserGoal: String, Codable, CaseIterable, Hashable {
    case fatLoss = "fat_loss"
    case muscleGain = "muscle_gain"
    case maintenance = "maintenance"
    case performance = "performance"
    case highProtein = "high_protein"
    case fieldConvenience = "field_convenience"

    var label: String {
        switch self {
        case .fatLoss: return "Fat Loss"
        case .muscleGain: return "Muscle Gain"
        case .maintenance: return "Maintenance"
        case .performance: return "Performance"
        case .highProtein: return "High Protein"
        case .fieldConvenience: return "Field / Convenience"
        }
    }

    var icon: String {
        switch self {
        case .fatLoss: return "scalemass.fill"
        case .muscleGain: return "figure.strengthtraining.traditional"
        case .maintenance: return "arrow.trianglehead.2.clockwise"
        case .performance: return "bolt.fill"
        case .highProtein: return "chart.bar.fill"
        case .fieldConvenience: return "bag.fill"
        }
    }

    var color: String {
        switch self {
        case .fatLoss: return "#FF6B6B"
        case .muscleGain: return "#45B7D1"
        case .maintenance: return "#96CEB4"
        case .performance: return "#FFD700"
        case .highProtein: return "#A29BFE"
        case .fieldConvenience: return "#FF9F0A"
        }
    }
}

struct FuelScan: Decodable, Identifiable {
    let id: UUID
    let userId: UUID
    let barcode: String
    var product: FuelProduct?
    var wasLogged: Bool
    var chowEntryId: UUID?
    let scannedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case barcode
        case product
        case fuelProducts = "fuel_products"
        case wasLogged = "was_logged"
        case chowEntryId = "chow_entry_id"
        case scannedAt = "scanned_at"
    }

    init(
        id: UUID,
        userId: UUID,
        barcode: String,
        product: FuelProduct?,
        wasLogged: Bool,
        chowEntryId: UUID?,
        scannedAt: Date
    ) {
        self.id = id
        self.userId = userId
        self.barcode = barcode
        self.product = product
        self.wasLogged = wasLogged
        self.chowEntryId = chowEntryId
        self.scannedAt = scannedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        userId = try container.decode(UUID.self, forKey: .userId)
        barcode = try container.decodeIfPresent(String.self, forKey: .barcode) ?? ""
        let directProduct = try container.decodeIfPresent(FuelProduct.self, forKey: .product)
        let relatedProduct = try container.decodeIfPresent(FuelProduct.self, forKey: .fuelProducts)
        product = directProduct ?? relatedProduct
        wasLogged = try container.decodeIfPresent(Bool.self, forKey: .wasLogged) ?? false
        chowEntryId = try container.decodeIfPresent(UUID.self, forKey: .chowEntryId)
        scannedAt = try container.decodeIfPresent(Date.self, forKey: .scannedAt) ?? Date()
    }
}

struct ChowEntry: Decodable, Identifiable {
    let id: UUID
    let userId: UUID
    var mealType: MealType
    var servings: Double
    var source: ChowEntrySource
    var productId: UUID?
    var product: FuelProduct?
    var manualName: String?
    var manualCalories: Double?
    var manualProteinG: Double?
    var manualCarbsG: Double?
    var manualFatG: Double?
    var notes: String?
    let logDate: String
    let loggedAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case mealType = "meal_type"
        case servings
        case source
        case productId = "product_id"
        case product
        case fuelProducts = "fuel_products"
        case manualName = "manual_name"
        case manualCalories = "manual_calories"
        case manualProteinG = "manual_protein_g"
        case manualCarbsG = "manual_carbs_g"
        case manualFatG = "manual_fat_g"
        case notes
        case logDate = "log_date"
        case loggedAt = "logged_at"
        case updatedAt = "updated_at"
    }

    var totalCalories: Double {
        if let product { return product.nutrition.calories * servings }
        return (manualCalories ?? 0) * servings
    }

    var totalProtein: Double {
        if let product { return product.nutrition.proteinG * servings }
        return (manualProteinG ?? 0) * servings
    }

    var totalCarbs: Double {
        if let product { return product.nutrition.carbsG * servings }
        return (manualCarbsG ?? 0) * servings
    }

    var totalFat: Double {
        if let product { return product.nutrition.fatG * servings }
        return (manualFatG ?? 0) * servings
    }

    var displayName: String {
        product?.name ?? manualName ?? "Food entry"
    }

    var fuelRating: FuelRating? {
        product?.scores?.rating
    }

    init(
        id: UUID,
        userId: UUID,
        mealType: MealType,
        servings: Double,
        source: ChowEntrySource,
        productId: UUID?,
        product: FuelProduct?,
        manualName: String?,
        manualCalories: Double?,
        manualProteinG: Double?,
        manualCarbsG: Double?,
        manualFatG: Double?,
        notes: String?,
        logDate: String,
        loggedAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.userId = userId
        self.mealType = mealType
        self.servings = servings
        self.source = source
        self.productId = productId
        self.product = product
        self.manualName = manualName
        self.manualCalories = manualCalories
        self.manualProteinG = manualProteinG
        self.manualCarbsG = manualCarbsG
        self.manualFatG = manualFatG
        self.notes = notes
        self.logDate = logDate
        self.loggedAt = loggedAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        userId = try container.decode(UUID.self, forKey: .userId)
        mealType = try container.decodeIfPresent(MealType.self, forKey: .mealType) ?? .snack
        servings = try container.decodeIfPresent(Double.self, forKey: .servings) ?? 1
        source = try container.decodeIfPresent(ChowEntrySource.self, forKey: .source) ?? .manual
        productId = try container.decodeIfPresent(UUID.self, forKey: .productId)
        let directProduct = try container.decodeIfPresent(FuelProduct.self, forKey: .product)
        let relatedProduct = try container.decodeIfPresent(FuelProduct.self, forKey: .fuelProducts)
        product = directProduct ?? relatedProduct
        manualName = try container.decodeIfPresent(String.self, forKey: .manualName)
        manualCalories = try container.decodeIfPresent(Double.self, forKey: .manualCalories)
        manualProteinG = try container.decodeIfPresent(Double.self, forKey: .manualProteinG)
        manualCarbsG = try container.decodeIfPresent(Double.self, forKey: .manualCarbsG)
        manualFatG = try container.decodeIfPresent(Double.self, forKey: .manualFatG)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        logDate = try container.decodeIfPresent(String.self, forKey: .logDate) ?? BarcodeService.todayString
        loggedAt = try container.decodeIfPresent(Date.self, forKey: .loggedAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }
}

enum ChowEntrySource: String, Codable, Hashable {
    case scan
    case manual
    case favorite
    case recent
    case quickAdd = "quick_add"
}

struct DailyNutritionSummary {
    let date: String
    let entries: [ChowEntry]
    let goals: UserNutritionGoals

    var totalCalories: Double { entries.reduce(0) { $0 + $1.totalCalories } }
    var totalProtein: Double { entries.reduce(0) { $0 + $1.totalProtein } }
    var totalCarbs: Double { entries.reduce(0) { $0 + $1.totalCarbs } }
    var totalFat: Double { entries.reduce(0) { $0 + $1.totalFat } }

    var calorieProgress: Double {
        goals.calorieTarget > 0 ? min(1.0, totalCalories / Double(goals.calorieTarget)) : 0
    }

    var remainingCalories: Int {
        max(0, goals.calorieTarget - Int(totalCalories))
    }

    func entries(for mealType: MealType) -> [ChowEntry] {
        entries.filter { $0.mealType == mealType }
    }
}

struct UserNutritionGoals: Codable {
    var userId: UUID
    var calorieTarget: Int
    var proteinTarget: Int
    var carbTarget: Int
    var fatTarget: Int
    var primaryGoal: UserGoal
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case calorieTarget = "calorie_target"
        case proteinTarget = "protein_target"
        case carbTarget = "carb_target"
        case fatTarget = "fat_target"
        case primaryGoal = "primary_goal"
        case updatedAt = "updated_at"
    }

    static func defaults(for goal: UserGoal, userId: UUID) -> UserNutritionGoals {
        switch goal {
        case .fatLoss:
            return .init(userId: userId, calorieTarget: 1800, proteinTarget: 140, carbTarget: 150, fatTarget: 60, primaryGoal: .fatLoss, updatedAt: Date())
        case .muscleGain:
            return .init(userId: userId, calorieTarget: 2800, proteinTarget: 170, carbTarget: 300, fatTarget: 80, primaryGoal: .muscleGain, updatedAt: Date())
        case .performance:
            return .init(userId: userId, calorieTarget: 2500, proteinTarget: 160, carbTarget: 280, fatTarget: 75, primaryGoal: .performance, updatedAt: Date())
        case .highProtein:
            return .init(userId: userId, calorieTarget: 2200, proteinTarget: 180, carbTarget: 180, fatTarget: 70, primaryGoal: .highProtein, updatedAt: Date())
        case .fieldConvenience:
            return .init(userId: userId, calorieTarget: 2400, proteinTarget: 150, carbTarget: 240, fatTarget: 75, primaryGoal: .fieldConvenience, updatedAt: Date())
        case .maintenance:
            return .init(userId: userId, calorieTarget: 2200, proteinTarget: 150, carbTarget: 220, fatTarget: 70, primaryGoal: .maintenance, updatedAt: Date())
        }
    }
}

struct SavedProduct: Decodable, Identifiable {
    let id: UUID
    let userId: UUID
    let productId: UUID
    var product: FuelProduct?
    let savedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case productId = "product_id"
        case product
        case fuelProducts = "fuel_products"
        case savedAt = "saved_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        userId = try container.decode(UUID.self, forKey: .userId)
        productId = try container.decode(UUID.self, forKey: .productId)
        let directProduct = try container.decodeIfPresent(FuelProduct.self, forKey: .product)
        let relatedProduct = try container.decodeIfPresent(FuelProduct.self, forKey: .fuelProducts)
        product = directProduct ?? relatedProduct
        savedAt = try container.decodeIfPresent(Date.self, forKey: .savedAt) ?? Date()
    }
}

struct BarcodeLookupResponse: Decodable {
    let found: Bool
    let product: FuelProduct?
    let scanId: UUID?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case found
        case product
        case scanId = "scan_id"
        case error
    }
}

enum ScanState: Equatable {
    case idle
    case scanning
    case processing(barcode: String)
    case found(product: FuelProduct)
    case notFound(barcode: String)
    case error(String)

    static func == (lhs: ScanState, rhs: ScanState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.scanning, .scanning):
            return true
        case (.processing(let a), .processing(let b)):
            return a == b
        case (.found(let a), .found(let b)):
            return a.id == b.id
        case (.notFound(let a), .notFound(let b)):
            return a == b
        case (.error(let a), .error(let b)):
            return a == b
        default:
            return false
        }
    }
}

private extension KeyedDecodingContainer {
    func decodeOneOrFirstIfPresent<T: Decodable>(_ type: T.Type, forKey key: Key) throws -> T? {
        if let single = try? decode(T.self, forKey: key) {
            return single
        }

        if var arrayContainer = try? nestedUnkeyedContainer(forKey: key) {
            if try arrayContainer.decodeNil() {
                return nil
            }
            return try arrayContainer.decode(T.self)
        }

        return nil
    }
}
