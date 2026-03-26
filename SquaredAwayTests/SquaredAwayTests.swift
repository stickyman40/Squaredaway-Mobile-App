//
//  SquaredAwayTests.swift
//  SquaredAwayTests
//
//  Created by Jayland stitt on 3/23/26.
//

import XCTest
@testable import SquaredAway

final class SquaredAwayTests: XCTestCase {
    private var originalMilestonesPreference: Bool = true
    private var originalReadinessPreference: Bool = true
    private var originalActivityPreference: Bool = true

    override func setUpWithError() throws {
        let defaults = UserDefaults.standard
        originalMilestonesPreference = defaults.bool(forKey: NotificationPreferences.milestonesEnabledKey)
        originalReadinessPreference = defaults.bool(forKey: NotificationPreferences.readinessEnabledKey)
        originalActivityPreference = defaults.bool(forKey: NotificationPreferences.activityEnabledKey)
    }

    override func tearDownWithError() throws {
        let defaults = UserDefaults.standard
        defaults.set(originalMilestonesPreference, forKey: NotificationPreferences.milestonesEnabledKey)
        defaults.set(originalReadinessPreference, forKey: NotificationPreferences.readinessEnabledKey)
        defaults.set(originalActivityPreference, forKey: NotificationPreferences.activityEnabledKey)
    }

    func testMilitaryBranchMetadataMatchesExpectedLabelsAndIcons() {
        XCTAssertEqual(MilitaryBranch.army.icon, "shield.fill")
        XCTAssertEqual(MilitaryBranch.navy.icon, "anchor")
        XCTAssertEqual(MilitaryBranch.airForce.mosLabel, "AFSC")
        XCTAssertEqual(MilitaryBranch.marines.mosLabel, "MOS")
        XCTAssertEqual(MilitaryBranch.coastGuard.mosLabel, "Rating")
    }

    func testEveryBranchHasRankAndSpecialtyOptions() {
        for branch in MilitaryBranch.allCases {
            XCTAssertFalse(branch.rankOptions.isEmpty, "\(branch.rawValue) should expose rank options.")
            XCTAssertFalse(branch.specialtyOptions.isEmpty, "\(branch.rawValue) should expose specialty options.")
            XCTAssertGreaterThanOrEqual(branch.specialtyOptions.count, 14, "\(branch.rawValue) should keep a meaningful starter list.")
        }
    }

    func testMilitaryBranchColorPaletteMatchesExpectedBranding() {
        XCTAssertEqual(MilitaryBranch.army.color, "#4A7C59")
        XCTAssertEqual(MilitaryBranch.airForce.color, "#004990")
        XCTAssertEqual(MilitaryBranch.navy.color, "#1B2A4A")
        XCTAssertEqual(MilitaryBranch.marines.color, "#A0001C")
        XCTAssertEqual(MilitaryBranch.spaceForce.color, "#1B2559")
        XCTAssertEqual(MilitaryBranch.coastGuard.color, "#003087")
    }

    func testBranchSpecificStarterSpecialtiesMatchExpectedLabels() {
        XCTAssertTrue(MilitaryBranch.army.specialtyOptions.contains(MilitarySpecialty(code: "11B", title: "Infantryman")))
        XCTAssertTrue(MilitaryBranch.airForce.specialtyOptions.contains(MilitarySpecialty(code: "1D7X1", title: "Cyber Defense Operations")))
        XCTAssertTrue(MilitaryBranch.navy.specialtyOptions.contains(MilitarySpecialty(code: "HM", title: "Hospital Corpsman")))
        XCTAssertTrue(MilitaryBranch.marines.specialtyOptions.contains(MilitarySpecialty(code: "0311", title: "Rifleman")))
        XCTAssertTrue(MilitaryBranch.spaceForce.specialtyOptions.contains(MilitarySpecialty(code: "5S031", title: "Space Systems Operations")))
        XCTAssertTrue(MilitaryBranch.coastGuard.specialtyOptions.contains(MilitarySpecialty(code: "ME", title: "Maritime Enforcement Specialist")))
    }

    func testNotificationCategoryBrandingReflectsCurrentCopy() {
        XCTAssertEqual(AppNotificationCategory.activity.title, "Fitness & Chow Activity")
        XCTAssertEqual(
            AppNotificationCategory.activity.subtitle,
            "Workout and chow entry create, edit, and delete events."
        )
        XCTAssertEqual(AppNotificationCategory.readiness.title, "Readiness Updates")
        XCTAssertEqual(AppNotificationCategory.milestones.rawValue, "milestones")
        XCTAssertEqual(AppNotificationCategory.readiness.rawValue, "readiness")
        XCTAssertEqual(AppNotificationCategory.activity.rawValue, "activity")
        XCTAssertEqual(AppNotificationCategory.from(type: "READINESS"), .readiness)
        XCTAssertNil(AppNotificationCategory.from(type: "unknown"))
    }

    func testAppNotificationDecodesCategoryTypeField() throws {
        let json = """
        {
          "id": "7D08B86D-8B5D-4C68-9B4F-0DBF2B9E8A64",
          "user_id": "17BFA14D-6DF9-4D88-A8B0-BEA4998A8F22",
          "type": "readiness",
          "title": "PCS plan updated",
          "body": "2 of 3 move tasks complete.",
          "is_read": false,
          "created_at": "2026-03-25T22:15:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let notification = try decoder.decode(AppNotification.self, from: json)

        XCTAssertEqual(notification.type, "readiness")
        XCTAssertEqual(notification.title, "PCS plan updated")
        XCTAssertFalse(notification.isRead)
    }

    func testNotificationPreferencesCanBeSetAndRead() {
        NotificationPreferences.setEnabled(false, for: .milestones)
        NotificationPreferences.setEnabled(true, for: .readiness)
        NotificationPreferences.setEnabled(false, for: .activity)

        XCTAssertFalse(NotificationPreferences.isEnabled(for: .milestones))
        XCTAssertTrue(NotificationPreferences.isEnabled(for: .readiness))
        XCTAssertFalse(NotificationPreferences.isEnabled(for: .activity))
    }

    func testUserProfileDecodesBranchLockedField() throws {
        let json = """
        {
          "id": "0A53A1F0-5A83-42D6-A9C0-93CC4C5F6E8C",
          "email": "branch.locked@example.com",
          "branch": "Army",
          "branch_locked": true,
          "rank": "Sergeant (E-5)",
          "mos": "11B",
          "discovery_source": "App Store",
          "discovery_notes": "Friend referral",
          "first_name": "Taylor",
          "last_name": "Smith",
          "height_cm": 180,
          "weight_kg": 84,
          "fitness_goal": "Improve Score",
          "onboarding_complete": true,
          "created_at": "2026-03-25T22:15:00Z",
          "updated_at": "2026-03-25T22:15:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let profile = try decoder.decode(UserProfile.self, from: json)

        XCTAssertEqual(profile.branch, .army)
        XCTAssertEqual(profile.branchLocked, true)
        XCTAssertEqual(profile.discoveryNotes, "Friend referral")
    }

    @MainActor
    func testPromotionsViewModelCalculatesArmyPromotionPoints() {
        let vm = PromotionsViewModel()
        vm.branchConfig = .config(for: .army)
        vm.record = makePromotionData(
            branch: .army,
            armyMilEdPoints: 120,
            armyCivEdPoints: 40,
            armyAwardsPoints: 55,
            armyMilTrgPoints: 70,
            armyAcftPoints: 50,
            armyWeaponsPoints: 20,
            armyCurrentCutoff: 320
        )

        XCTAssertEqual(vm.computedTotalScore, 355)
        XCTAssertEqual(vm.cutoffScore, 320)
        XCTAssertEqual(vm.isAboveCutoff, true)
        XCTAssertEqual(vm.scoreLabel, "Promotion Points")
    }

    @MainActor
    func testPromotionsViewModelCalculatesWAPSScore() {
        let vm = PromotionsViewModel()
        vm.branchConfig = .config(for: .airForce)
        vm.record = makePromotionData(
            branch: .airForce,
            wapsSktScore: 80,
            wapsPfeScore: 70,
            wapsEprScore: 126,
            wapsDecorationsPoints: 10,
            wapsTisPoints: 8,
            wapsTigPoints: 4,
            wapsAfadconsPoints: 12,
            wapsCutoffScore: 340
        )

        XCTAssertEqual(vm.computedTotalScore, 350)
        XCTAssertEqual(vm.cutoffScore, 340)
        XCTAssertEqual(vm.isAboveCutoff, true)
        XCTAssertEqual(vm.scoreLabel, "WAPS Score")
    }

    @MainActor
    func testPromotionsViewModelCalculatesNavyFinalMultipleScore() {
        let vm = PromotionsViewModel()
        vm.branchConfig = .config(for: .navy)
        vm.record = makePromotionData(
            branch: .navy,
            navyPmaScore: 3.8,
            navyExamScore: 62,
            navyAwardsPoints: 6,
            navySipgPoints: 2.5,
            navyPnaPoints: 1.0
        )

        XCTAssertEqual(vm.computedTotalScore, 127)
        XCTAssertNil(vm.cutoffScore)
        XCTAssertEqual(vm.scoreLabel, "Final Multiple Score")
    }

    @MainActor
    func testPromotionsViewModelCalculatesMarineCompositeScore() {
        let vm = PromotionsViewModel()
        vm.branchConfig = .config(for: .marines)
        vm.record = makePromotionData(
            branch: .marines,
            marineProMark: 4.5,
            marineConMark: 4.2,
            marinePftScore: 285,
            marineCftScore: 270,
            marineRifleScore: 5,
            marineMciPoints: 8,
            marineCuttingScore: 1050
        )

        XCTAssertEqual(vm.computedTotalScore, 1462)
        XCTAssertEqual(vm.cutoffScore, 1050)
        XCTAssertEqual(vm.isAboveCutoff, true)
        XCTAssertEqual(vm.scoreLabel, "Composite Score")
    }

    @MainActor
    func testPromotionsViewModelCalculatesCoastGuardFinalExamScore() {
        let vm = PromotionsViewModel()
        vm.branchConfig = .config(for: .coastGuard)
        vm.record = makePromotionData(
            branch: .coastGuard,
            cgSweScore: 78,
            cgPerfFactor: 6.2,
            cgAdvancementCut: 138
        )

        XCTAssertEqual(vm.computedTotalScore, 140)
        XCTAssertEqual(vm.cutoffScore, 138)
        XCTAssertEqual(vm.isAboveCutoff, true)
        XCTAssertEqual(vm.scoreLabel, "Final Exam Score")
    }

    func testSupabaseTableConstantsIncludeNewFeatureTables() {
        XCTAssertEqual(SupabaseManager.Tables.trackerData, "tracker_data")
        XCTAssertEqual(SupabaseManager.Tables.pcsData, "pcs_data")
        XCTAssertEqual(SupabaseManager.Tables.benefitsData, "benefits_data")
        XCTAssertEqual(SupabaseManager.Tables.fuelProducts, "fuel_products")
        XCTAssertEqual(SupabaseManager.Tables.fuelProductScores, "fuel_product_scores")
        XCTAssertEqual(SupabaseManager.Tables.fuelScans, "fuel_scans")
        XCTAssertEqual(SupabaseManager.Tables.fuelSaved, "fuel_saved")
        XCTAssertEqual(SupabaseManager.Tables.chowEntries, "chow_entries")
        XCTAssertEqual(SupabaseManager.Tables.userNutritionGoals, "user_nutrition_goals")
    }

    func testFuelProductDecodesEmbeddedScoreArrayFromSupabase() throws {
        let json = """
        {
          "id": "DBE4A57F-E190-4D8E-A2FE-7806A46C599A",
          "barcode": "0123456789012",
          "name": "Protein Bar",
          "brand": "SquaredAway",
          "image_url": null,
          "category": "Protein",
          "serving_size": "1 bar (50g)",
          "serving_size_g": 50,
          "nutrition": {
            "calories": 210,
            "protein_g": 20,
            "carbs_g": 18,
            "fat_g": 7,
            "sugar_g": 4,
            "fiber_g": 3
          },
          "flags": [],
          "data_source": "cached",
          "created_at": "2026-03-26T18:45:00Z",
          "fuel_product_scores": [
            {
              "overall": 82,
              "fat_loss": 76,
              "muscle_gain": 88,
              "performance": 79,
              "convenience": 85,
              "fuel_rating": "green",
              "primary_reason": "High protein efficiency",
              "factors": [],
              "goal_guidance": [],
              "computed_at": "2026-03-26T18:45:00Z"
            }
          ]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let product = try decoder.decode(FuelProduct.self, from: json)

        XCTAssertEqual(product.name, "Protein Bar")
        XCTAssertEqual(product.scores?.overall, 82)
        XCTAssertEqual(product.scores?.rating, .green)
    }

    func testFuelScanDecodesEmbeddedProductObject() throws {
        let json = """
        {
          "id": "7A78D324-FE48-4587-B124-89A8C681B4CB",
          "user_id": "4DBE9B16-4D75-45A2-B15A-22E5082CF93D",
          "barcode": "0123456789012",
          "was_logged": true,
          "chow_entry_id": "A0B13D53-79ED-40D8-88A6-BE9E30BBA9C3",
          "scanned_at": "2026-03-26T18:45:00Z",
          "fuel_products": {
            "id": "DBE4A57F-E190-4D8E-A2FE-7806A46C599A",
            "barcode": "0123456789012",
            "name": "Protein Bar",
            "brand": "SquaredAway",
            "category": "Protein",
            "serving_size": "1 bar (50g)",
            "serving_size_g": 50,
            "nutrition": {
              "calories": 210,
              "protein_g": 20,
              "carbs_g": 18,
              "fat_g": 7
            },
            "flags": [],
            "data_source": "cached",
            "created_at": "2026-03-26T18:45:00Z"
          }
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let scan = try decoder.decode(FuelScan.self, from: json)

        XCTAssertTrue(scan.wasLogged)
        XCTAssertEqual(scan.product?.name, "Protein Bar")
        XCTAssertEqual(scan.product?.nutrition.proteinG, 20)
    }

    func testFuelScoringEngineRewardsLeanHighProteinFoods() {
        let nutrition = ProductNutrition(
            calories: 180,
            proteinG: 28,
            carbsG: 8,
            fatG: 4,
            saturatedFatG: 1,
            fiberG: 3,
            sugarG: 2,
            sodiumMg: 220,
            cholesterolMg: nil,
            potassiumMg: nil,
            calPer100g: 360,
            proteinPer100g: 56,
            carbsPer100g: 16,
            fatPer100g: 8,
            sugarPer100g: 4,
            sodiumPer100g: 440
        )

        let scores = FuelScoringEngine.score(
            nutrition: nutrition,
            category: .protein,
            ingredientFlags: [],
            goal: .muscleGain
        )

        XCTAssertGreaterThanOrEqual(scores.overall, 75)
        XCTAssertEqual(scores.rating, .green)
        XCTAssertGreaterThanOrEqual(scores.muscleGain, scores.fatLoss)
    }

    func testHandleAuthCallbackDetectsPasswordRecoveryInQuery() {
        let url = URL(string: "squaredaway://auth-callback?type=recovery")!

        let action = SupabaseManager.shared.callbackAction(for: url)

        XCTAssertEqual(action, .passwordRecovery)
    }

    func testHandleAuthCallbackDetectsPasswordRecoveryInFragment() {
        let url = URL(string: "squaredaway://auth-callback#type=recovery&access_token=abc")!

        let action = SupabaseManager.shared.callbackAction(for: url)

        XCTAssertEqual(action, .passwordRecovery)
    }

    private func makePromotionData(
        branch: MilitaryBranch,
        armyMilEdPoints: Int? = nil,
        armyCivEdPoints: Int? = nil,
        armyAwardsPoints: Int? = nil,
        armyMilTrgPoints: Int? = nil,
        armyAcftPoints: Int? = nil,
        armyWeaponsPoints: Int? = nil,
        armyCurrentCutoff: Int? = nil,
        wapsSktScore: Int? = nil,
        wapsPfeScore: Int? = nil,
        wapsEprScore: Int? = nil,
        wapsDecorationsPoints: Int? = nil,
        wapsTisPoints: Int? = nil,
        wapsTigPoints: Int? = nil,
        wapsAfadconsPoints: Int? = nil,
        wapsCutoffScore: Int? = nil,
        navyPmaScore: Double? = nil,
        navyExamScore: Int? = nil,
        navyAwardsPoints: Int? = nil,
        navySipgPoints: Double? = nil,
        navyPnaPoints: Double? = nil,
        marineProMark: Double? = nil,
        marineConMark: Double? = nil,
        marinePftScore: Int? = nil,
        marineCftScore: Int? = nil,
        marineRifleScore: Int? = nil,
        marineMciPoints: Int? = nil,
        marineCuttingScore: Int? = nil,
        cgSweScore: Int? = nil,
        cgPerfFactor: Double? = nil,
        cgAdvancementCut: Int? = nil
    ) -> PromotionData {
        PromotionData(
            id: UUID(),
            userId: UUID(),
            currentRank: "Current",
            targetRank: "Target",
            pointsCurrent: 0,
            pointsRequired: 0,
            boardDate: nil,
            notes: nil,
            updatedAt: Date(),
            branch: branch,
            armyMilEdPoints: armyMilEdPoints,
            armyCivEdPoints: armyCivEdPoints,
            armyAwardsPoints: armyAwardsPoints,
            armyMilTrgPoints: armyMilTrgPoints,
            armyAcftPoints: armyAcftPoints,
            armyWeaponsPoints: armyWeaponsPoints,
            armyCurrentCutoff: armyCurrentCutoff,
            armyMos: nil,
            wapsSktScore: wapsSktScore,
            wapsPfeScore: wapsPfeScore,
            wapsEprScore: wapsEprScore,
            wapsDecorationsPoints: wapsDecorationsPoints,
            wapsTisPoints: wapsTisPoints,
            wapsTigPoints: wapsTigPoints,
            wapsAfadconsPoints: wapsAfadconsPoints,
            wapsCutoffScore: wapsCutoffScore,
            navyPmaScore: navyPmaScore,
            navyExamScore: navyExamScore,
            navyAwardsPoints: navyAwardsPoints,
            navySipgPoints: navySipgPoints,
            navyPnaPoints: navyPnaPoints,
            navyCycleExamDate: nil,
            marineProMark: marineProMark,
            marineConMark: marineConMark,
            marinePftScore: marinePftScore,
            marineCftScore: marineCftScore,
            marineRifleScore: marineRifleScore,
            marineMciPoints: marineMciPoints,
            marineCuttingScore: marineCuttingScore,
            cgSweScore: cgSweScore,
            cgPerfFactor: cgPerfFactor,
            cgFinalExamScore: nil,
            cgAdvancementCut: cgAdvancementCut,
            nextBoardDate: nil,
            boardCycleYear: nil
        )
    }
}
