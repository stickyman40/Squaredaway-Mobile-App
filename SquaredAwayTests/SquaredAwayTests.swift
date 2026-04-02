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
    private var originalPlannerReminderMode: PlannerReminderMode = .adaptive
    private var originalPlannerReminderLeadTime: PlannerReminderLeadTime = .atTime

    override func setUpWithError() throws {
        let defaults = UserDefaults.standard
        originalMilestonesPreference = defaults.bool(forKey: NotificationPreferences.milestonesEnabledKey)
        originalReadinessPreference = defaults.bool(forKey: NotificationPreferences.readinessEnabledKey)
        originalActivityPreference = defaults.bool(forKey: NotificationPreferences.activityEnabledKey)
        originalPlannerReminderMode = ReminderPreferences.plannerReminderMode()
        originalPlannerReminderLeadTime = ReminderPreferences.plannerReminderLeadTime()
    }

    override func tearDownWithError() throws {
        let defaults = UserDefaults.standard
        defaults.set(originalMilestonesPreference, forKey: NotificationPreferences.milestonesEnabledKey)
        defaults.set(originalReadinessPreference, forKey: NotificationPreferences.readinessEnabledKey)
        defaults.set(originalActivityPreference, forKey: NotificationPreferences.activityEnabledKey)
        ReminderPreferences.setPlannerReminderMode(originalPlannerReminderMode)
        ReminderPreferences.setPlannerReminderLeadTime(originalPlannerReminderLeadTime)
    }

    func testMilitaryBranchMetadataMatchesExpectedLabelsAndIcons() {
        XCTAssertEqual(MilitaryBranch.army.icon, "shield.fill")
        XCTAssertEqual(MilitaryBranch.navy.icon, "anchor")
        XCTAssertEqual(MilitaryBranch.airForce.mosLabel, "AFSC")
        XCTAssertEqual(MilitaryBranch.marines.mosLabel, "MOS")
        XCTAssertEqual(MilitaryBranch.coastGuard.mosLabel, "Rating")
    }

    func testPlannerWorkoutReminderDateUsesPreferredTimeWhenStillUpcoming() throws {
        let calendar = Calendar(identifier: .gregorian)
        let now = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 4, day: 1, hour: 9, minute: 0)))
        let scheduledDate = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 4, day: 1)))
        let preferredTime = try XCTUnwrap(calendar.date(from: DateComponents(year: 2001, month: 1, day: 1, hour: 19, minute: 0)))

        let reminderDate = try XCTUnwrap(
            ReminderService.shared.plannerWorkoutReminderDate(
                scheduledDate: scheduledDate,
                preferredTime: preferredTime,
                now: now
            )
        )

        XCTAssertEqual(calendar.component(.hour, from: reminderDate), 19)
        XCTAssertEqual(calendar.component(.minute, from: reminderDate), 0)
        XCTAssertTrue(calendar.isDate(reminderDate, inSameDayAs: scheduledDate))
    }

    func testPlannerWorkoutReminderDateFallsBackToSoonForPastPreferredTime() throws {
        let calendar = Calendar(identifier: .gregorian)
        let now = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 4, day: 1, hour: 20, minute: 0)))
        let scheduledDate = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 4, day: 1)))
        let preferredTime = try XCTUnwrap(calendar.date(from: DateComponents(year: 2001, month: 1, day: 1, hour: 19, minute: 0)))

        let reminderDate = try XCTUnwrap(
            ReminderService.shared.plannerWorkoutReminderDate(
                scheduledDate: scheduledDate,
                preferredTime: preferredTime,
                now: now
            )
        )

        XCTAssertEqual(reminderDate.timeIntervalSince(now), 900, accuracy: 1)
    }

    func testPlannerWorkoutReminderDateAppliesLeadTime() throws {
        let calendar = Calendar(identifier: .gregorian)
        let now = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 4, day: 1, hour: 9, minute: 0)))
        let scheduledDate = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 4, day: 1)))
        let preferredTime = try XCTUnwrap(calendar.date(from: DateComponents(year: 2001, month: 1, day: 1, hour: 19, minute: 0)))

        let reminderDate = try XCTUnwrap(
            ReminderService.shared.plannerWorkoutReminderDate(
                scheduledDate: scheduledDate,
                preferredTime: preferredTime,
                leadTime: .oneHour,
                now: now
            )
        )

        XCTAssertEqual(calendar.component(.hour, from: reminderDate), 18)
        XCTAssertEqual(calendar.component(.minute, from: reminderDate), 0)
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
        vm.selectedTargetRank = vm.branchConfig.ranks.first(where: { $0.payGrade == "E-5" })
        vm.record = makePromotionData(
            branch: .army,
            armyMilEdPts: 120,
            armyCivEdPts: 40,
            armyAwardsPts: 55,
            armyMilTrgPts: 70,
            armyAftPts: 50,
            armyWeaponsPts: 20,
            armyMosCutoff: 320
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
        vm.selectedTargetRank = vm.branchConfig.ranks.first(where: { $0.payGrade == "E-5" })
        vm.record = makePromotionData(
            branch: .airForce,
            wapsSktRaw: 80,
            wapsPfeRaw: 70,
            wapsEprRating: 5,
            wapsDecorationsPts: 10,
            wapsTisYears: 10,
            wapsTigMonths: 40,
            wapsAfadconsPts: 12,
            wapsCutoffPublished: 340
        )

        XCTAssertEqual(vm.computedTotalScore, 355)
        XCTAssertEqual(vm.cutoffScore, 340)
        XCTAssertEqual(vm.isAboveCutoff, true)
        XCTAssertEqual(vm.scoreLabel, "WAPS Score")
    }

    @MainActor
    func testPromotionsViewModelCalculatesNavyFinalMultipleScore() {
        let vm = PromotionsViewModel()
        vm.branchConfig = .config(for: .navy)
        vm.selectedTargetRank = vm.branchConfig.ranks.first(where: { $0.payGrade == "E-5" })
        vm.record = makePromotionData(
            branch: .navy,
            navyPma: 3.8,
            navyExamRaw: 62,
            navyAwardsPts: 6,
            navySipgYears: 2.5,
            navyPnaAttempts: 2
        )

        XCTAssertEqual(vm.computedTotalScore, 126)
        XCTAssertNil(vm.cutoffScore)
        XCTAssertEqual(vm.scoreLabel, "Final Multiple Score")
    }

    @MainActor
    func testPromotionsViewModelCalculatesMarineCompositeScore() {
        let vm = PromotionsViewModel()
        vm.branchConfig = .config(for: .marines)
        vm.selectedTargetRank = vm.branchConfig.ranks.first(where: { $0.payGrade == "E-5" })
        vm.record = makePromotionData(
            branch: .marines,
            marineProMark: 4.5,
            marineConMark: 4.2,
            marinePftRaw: 285,
            marineCftRaw: 270,
            marineRifleQual: 50,
            marineMciCredits: 80,
            marineCutScore: 1050
        )

        XCTAssertEqual(vm.computedTotalScore, 1925)
        XCTAssertEqual(vm.cutoffScore, 1050)
        XCTAssertEqual(vm.isAboveCutoff, true)
        XCTAssertEqual(vm.scoreLabel, "Composite Score")
    }

    @MainActor
    func testPromotionsViewModelCalculatesCoastGuardFinalExamScore() {
        let vm = PromotionsViewModel()
        vm.branchConfig = .config(for: .coastGuard)
        vm.selectedTargetRank = vm.branchConfig.ranks.first(where: { $0.payGrade == "E-5" })
        vm.record = makePromotionData(
            branch: .coastGuard,
            cgSweRaw: 78,
            cgPerfFactor: 6.2,
            cgCutScore: 138
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

    func testFuelProductDecodesDietagramScannerContext() throws {
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
            "fat_g": 7
          },
          "flags": [],
          "dietagram": {
            "source": "dietagram_food_search",
            "search_term": "Protein Bar",
            "exact_match": {
              "id": "10",
              "name": "Protein Bar",
              "kind": "f",
              "kind_label": "Food",
              "category_id": "4",
              "nutrition": {
                "calories": 210,
                "protein_g": 20,
                "carbs_g": 18,
                "fat_g": 7
              }
            },
            "top_match": {
              "id": "10",
              "name": "Protein Bar",
              "kind": "f",
              "kind_label": "Food",
              "category_id": "4",
              "nutrition": {
                "calories": 210,
                "protein_g": 20,
                "carbs_g": 18,
                "fat_g": 7
              }
            },
            "matches": [
              {
                "id": "10",
                "name": "Protein Bar",
                "kind": "f",
                "kind_label": "Food",
                "category_id": "4",
                "nutrition": {
                  "calories": 210,
                  "protein_g": 20,
                  "carbs_g": 18,
                  "fat_g": 7
                }
              }
            ]
          },
          "data_source": "rapidapi",
          "created_at": "2026-03-26T18:45:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let product = try decoder.decode(FuelProduct.self, from: json)

        XCTAssertEqual(product.dietagram?.source, "dietagram_food_search")
        XCTAssertEqual(product.dietagram?.matches.first?.kindLabel, "Food")
        XCTAssertEqual(product.dietagram?.exactMatch?.nutrition.proteinG, 20)
    }

    func testFuelProductDecodesUSDAScannerContext() throws {
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
            "fat_g": 7
          },
          "flags": [],
          "usda": {
            "source": "usda_food_search",
            "search_term": "protein bar",
            "exact_match": {
              "id": "123",
              "name": "Protein bar",
              "brand": "SquaredAway",
              "data_type": "Branded",
              "nutrition": {
                "calories": 210,
                "protein_g": 20,
                "carbs_g": 18,
                "fat_g": 7
              }
            },
            "top_match": {
              "id": "123",
              "name": "Protein bar",
              "brand": "SquaredAway",
              "data_type": "Branded",
              "nutrition": {
                "calories": 210,
                "protein_g": 20,
                "carbs_g": 18,
                "fat_g": 7
              }
            },
            "matches": [
              {
                "id": "123",
                "name": "Protein bar",
                "brand": "SquaredAway",
                "data_type": "Branded",
                "nutrition": {
                  "calories": 210,
                  "protein_g": 20,
                  "carbs_g": 18,
                  "fat_g": 7
                }
              }
            ]
          },
          "data_source": "usda",
          "created_at": "2026-03-26T18:45:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let product = try decoder.decode(FuelProduct.self, from: json)

        XCTAssertEqual(product.usda?.source, "usda_food_search")
        XCTAssertEqual(product.usda?.matches.first?.dataType, "Branded")
        XCTAssertEqual(product.usda?.exactMatch?.nutrition.proteinG, 20)
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

    func testFuelScoringEnginePenalizesLowProteinMuscleGainFoods() {
        let nutrition = ProductNutrition(
            calories: 240,
            proteinG: 7,
            carbsG: 26,
            fatG: 12,
            saturatedFatG: 5,
            fiberG: 1,
            sugarG: 8,
            sodiumMg: 320,
            cholesterolMg: nil,
            potassiumMg: nil,
            calPer100g: 480,
            proteinPer100g: 14,
            carbsPer100g: 52,
            fatPer100g: 24,
            sugarPer100g: 16,
            sodiumPer100g: 640
        )

        let scores = FuelScoringEngine.score(
            nutrition: nutrition,
            category: .snack,
            ingredientFlags: [],
            goal: .muscleGain
        )

        XCTAssertLessThan(scores.muscleGain, 50)
        XCTAssertEqual(scores.goalGuidance.first(where: { $0.goal == .muscleGain })?.headline, "Not optimized for muscle building")
    }

    func testFuelProductDecodesRapidAPIDataSource() throws {
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
            "fat_g": 7
          },
          "flags": [],
          "data_source": "rapidapi",
          "created_at": "2026-03-26T18:45:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let product = try decoder.decode(FuelProduct.self, from: json)

        XCTAssertEqual(product.dataSource, .rapidAPI)
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

    func testHandleAuthCallbackDetectsAccountDeletedAction() {
        let url = URL(string: "squaredaway://auth-callback?action=account_deleted")!

        let action = SupabaseManager.shared.callbackAction(for: url)

        XCTAssertEqual(action, .accountDeleted)
    }

    func testWorkoutSplitAddsNewPlanningOptions() {
        XCTAssertTrue(WorkoutSplit.allCases.contains(.beginnerFoundation))
        XCTAssertTrue(WorkoutSplit.allCases.contains(.powerbuilding))
        XCTAssertTrue(WorkoutSplit.allCases.contains(.strengthConditioning))
        XCTAssertTrue(WorkoutSplit.allCases.contains(.runFocusedHybrid))
    }

    func testWorkoutDayDerivesMuscleGroupsFromFocus() {
        let day = WorkoutDay(
            dayNumber: 1,
            name: "Push",
            focus: "Chest · Shoulders · Triceps",
            exercises: WorkoutLibrary.pushDay
        )

        XCTAssertEqual(day.muscleGroups, ["Chest", "Shoulders", "Triceps"])
    }

    func testWorkoutSplitCanPlanWorkoutForSpecificDate() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 3, day: 29)))

        let workout = try XCTUnwrap(WorkoutSplit.powerbuilding.workout(on: date, calendar: calendar))

        XCTAssertEqual(workout.name, "Upper Power")
        XCTAssertFalse(workout.isRestDay)
    }

    func testWorkoutPlannerDraftBuildsCustomOverride() throws {
        let date = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-03-29T00:00:00Z"))
        var draft = WorkoutPlannerDraft(
            date: date,
            plannedWorkout: PlannedWorkout(
                date: date,
                workout: WorkoutDay(
                    dayNumber: 1,
                    name: "Push",
                    focus: "Chest · Shoulders · Triceps",
                    exercises: WorkoutLibrary.pushDay
                ),
                durationMinutes: 60
            )
        )
        draft.title = "Custom Push Day"
        draft.focus = "Chest emphasis"
        draft.muscleGroupsText = "Chest, Shoulders, Triceps"
        draft.durationMinutes = 75
        draft.notes = "Start heavy, then accessories."
        draft.exerciseLines = """
        Bench Press | 5x5 | heavy sets
        Incline Dumbbell Press | 3x10
        Bike Sprints | 8x20 sec | fast finish
        """

        let override = draft.makeOverride(dateKey: "2026-03-29")
        let plannedWorkout = override.plannedWorkout(on: date)

        XCTAssertEqual(override.title, "Custom Push Day")
        XCTAssertEqual(override.muscleGroups, ["Chest", "Shoulders", "Triceps"])
        XCTAssertEqual(override.durationMinutes, 75)
        XCTAssertEqual(override.exercises.count, 3)
        XCTAssertEqual(override.exercises[0].sets, 5)
        XCTAssertEqual(override.exercises[0].reps, "5")
        XCTAssertTrue(override.exercises[2].isCardio)
        XCTAssertEqual(plannedWorkout.workout.name, "Custom Push Day")
        XCTAssertEqual(plannedWorkout.durationMinutes, 75)
        XCTAssertTrue(plannedWorkout.notes?.contains("accessories") == true)
    }

    func testWorkoutPlannerDraftCanApplyTemplatePreset() throws {
        let date = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-03-29T00:00:00Z"))
        var draft = WorkoutPlannerDraft(
            date: date,
            plannedWorkout: PlannedWorkout(
                date: date,
                workout: WorkoutDay(
                    dayNumber: 1,
                    name: "Placeholder",
                    focus: "Placeholder",
                    exercises: []
                ),
                durationMinutes: 20
            )
        )

        draft.applyTemplate(.longRun)

        XCTAssertEqual(draft.title, "Long Run")
        XCTAssertEqual(draft.focus, "Endurance · Aerobic base")
        XCTAssertEqual(draft.muscleGroupsText, "Endurance, Cardio")
        XCTAssertEqual(Int(draft.durationMinutes), 75)
        XCTAssertFalse(draft.isRestDay)
        XCTAssertTrue(draft.exerciseLines.contains("Long Run | 1x45-60 min"))
    }

    func testWorkoutPlannerDraftCanAppendExerciseLibraryItem() throws {
        let date = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-03-29T00:00:00Z"))
        var draft = WorkoutPlannerDraft(
            date: date,
            plannedWorkout: PlannedWorkout(
                date: date,
                workout: WorkoutDay(
                    dayNumber: 1,
                    name: "Recovery",
                    focus: "Recovery",
                    exercises: []
                ),
                durationMinutes: 20,
                isCustom: false
            )
        )

        let libraryItem = try XCTUnwrap(ExerciseLibraryCatalog.items.first(where: { $0.exercise.name == "Bench Press" }))
        draft.appendExercise(libraryItem.exercise)

        XCTAssertFalse(draft.isRestDay)
        XCTAssertTrue(draft.exerciseLines.contains("Bench Press | 4x6-8 | Main press"))
    }

    func testWorkoutPlannerProgressRecordTracksExerciseAndWorkoutCompletion() {
        let exercises = [
            ExerciseEntry(name: "Bench Press", sets: 4, reps: "6-8", notes: nil, isCardio: false),
            ExerciseEntry(name: "Tempo Run", sets: 1, reps: "20 min", notes: nil, isCardio: true)
        ]
        let keys = exercises.enumerated().map {
            WorkoutPlannerProgressRecord.exerciseKey(for: $0.element, index: $0.offset)
        }

        var progress = WorkoutPlannerProgressRecord(dateKey: "2026-03-29")
        progress.setExerciseCompleted(true, key: keys[0], totalExerciseKeys: keys)
        XCTAssertEqual(progress.completedExerciseKeys.count, 1)
        XCTAssertFalse(progress.isWorkoutCompleted)

        progress.setExerciseCompleted(true, key: keys[1], totalExerciseKeys: keys)
        XCTAssertTrue(progress.isWorkoutCompleted)
        XCTAssertEqual(progress.completionFraction(totalExercises: 2), 1)

        progress.setWorkoutCompleted(false, allExerciseKeys: keys)
        XCTAssertFalse(progress.isWorkoutCompleted)
        XCTAssertTrue(progress.completedExerciseKeys.isEmpty)
    }

    @MainActor
    func testPTDashboardViewModelProvidesWeekAndMonthPlannerDates() throws {
        let viewModel = PTDashboardViewModel()
        let calendar = Calendar.current
        let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 3, day: 15)))

        let weekDates = viewModel.plannerWeekDates(containing: date)
        let monthDates = viewModel.plannerMonthDates(containing: date)

        XCTAssertEqual(weekDates.count, 7)
        XCTAssertEqual(monthDates.count, 31)
        XCTAssertTrue(weekDates.contains { calendar.isDate($0, inSameDayAs: date) })
        XCTAssertTrue(monthDates.contains { calendar.isDate($0, inSameDayAs: date) })
    }

    @MainActor
    func testPTDashboardPlannerCompletionPercentIgnoresRestAndFutureDays() throws {
        let viewModel = PTDashboardViewModel()
        let calendar = Calendar(identifier: .gregorian)
        let userId = UUID()
        let weekStart = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 3, day: 29)))
        XCTAssertEqual(calendar.component(.weekday, from: weekStart), 1)

        viewModel.fitnessProfile = FitnessProfile(
            id: UUID(),
            userId: userId,
            heightCm: 177.8,
            weightKg: 81,
            goalWeightKg: nil,
            fitnessGoal: .improvePTScore,
            experienceLevel: .intermediate,
            workoutSplit: .pushPullLegs,
            dailyCalorieTarget: nil,
            weeklyWorkoutTarget: 5,
            createdAt: weekStart,
            updatedAt: weekStart
        )

        let sunday = weekStart
        let monday = try XCTUnwrap(calendar.date(byAdding: .day, value: 1, to: sunday))
        let tuesday = try XCTUnwrap(calendar.date(byAdding: .day, value: 2, to: sunday))
        let wednesday = try XCTUnwrap(calendar.date(byAdding: .day, value: 3, to: sunday))
        let thursday = try XCTUnwrap(calendar.date(byAdding: .day, value: 4, to: sunday))
        let weekDates = [sunday, monday, tuesday, wednesday, thursday]

        viewModel.workoutHistory = [
            WorkoutLog(id: UUID(), userId: userId, workoutType: "Push", splitDay: "Push", durationSeconds: 1800, caloriesBurned: nil, notes: nil, loggedAt: sunday),
            WorkoutLog(id: UUID(), userId: userId, workoutType: "Pull", splitDay: "Pull", durationSeconds: 1800, caloriesBurned: nil, notes: nil, loggedAt: monday)
        ]

        XCTAssertEqual(viewModel.completedTrainingDays(in: weekDates, upTo: wednesday), 2)
        XCTAssertEqual(viewModel.plannerCompletionPercent(for: weekDates, upTo: wednesday), 67)
        XCTAssertEqual(viewModel.plannerCompletionPercent(for: weekDates, upTo: monday), 100)
    }

    @MainActor
    func testPTDashboardBestPlannerStreakUsesPlannedTrainingDaysOnly() throws {
        let viewModel = PTDashboardViewModel()
        let calendar = Calendar(identifier: .gregorian)
        let userId = UUID()
        let weekStart = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 3, day: 29)))

        viewModel.fitnessProfile = FitnessProfile(
            id: UUID(),
            userId: userId,
            heightCm: 177.8,
            weightKg: 81,
            goalWeightKg: nil,
            fitnessGoal: .improvePTScore,
            experienceLevel: .intermediate,
            workoutSplit: .pushPullLegs,
            dailyCalorieTarget: nil,
            weeklyWorkoutTarget: 5,
            createdAt: weekStart,
            updatedAt: weekStart
        )

        let completedOffsets = [0, 1, 4, 5]
        viewModel.workoutHistory = completedOffsets.compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: weekStart) else { return nil }
            return WorkoutLog(
                id: UUID(),
                userId: userId,
                workoutType: "Planned",
                splitDay: nil,
                durationSeconds: 1800,
                caloriesBurned: nil,
                notes: nil,
                loggedAt: date
            )
        }

        let weekDates = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
        XCTAssertEqual(viewModel.bestPlannerStreak(in: weekDates), 2)
    }

    @MainActor
    func testPTDashboardTrailingPlannerStatusesMarkTrainingAndRecoveryDays() throws {
        let viewModel = PTDashboardViewModel()
        let calendar = Calendar(identifier: .gregorian)
        let userId = UUID()
        let endDate = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 4, day: 1)))

        viewModel.fitnessProfile = FitnessProfile(
            id: UUID(),
            userId: userId,
            heightCm: 177.8,
            weightKg: 81,
            goalWeightKg: nil,
            fitnessGoal: .improvePTScore,
            experienceLevel: .intermediate,
            workoutSplit: .pushPullLegs,
            dailyCalorieTarget: nil,
            weeklyWorkoutTarget: 5,
            createdAt: endDate,
            updatedAt: endDate
        )

        let completedDates = [
            try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 3, day: 29))),
            try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 3, day: 31)))
        ]
        viewModel.workoutHistory = completedDates.map { date in
            WorkoutLog(
                id: UUID(),
                userId: userId,
                workoutType: "Planned",
                splitDay: nil,
                durationSeconds: 1800,
                caloriesBurned: nil,
                notes: nil,
                loggedAt: date
            )
        }

        let statuses = viewModel.trailingPlannerDailyStatuses(days: 5, endingAt: endDate)
        XCTAssertEqual(statuses.count, 5)

        let recoveryDay = try XCTUnwrap(statuses.first { calendar.isDate($0.date, inSameDayAs: endDate) })
        XCTAssertFalse(recoveryDay.isTrainingDay)
        XCTAssertFalse(recoveryDay.isCompleted)

        let completedTrainingDay = try XCTUnwrap(statuses.first { calendar.isDate($0.date, inSameDayAs: completedDates[0]) })
        XCTAssertTrue(completedTrainingDay.isTrainingDay)
        XCTAssertTrue(completedTrainingDay.isCompleted)
    }

    @MainActor
    func testPTDashboardWeeklyPlannerSnapshotsReturnChronologicalRows() throws {
        let viewModel = PTDashboardViewModel()
        let calendar = Calendar(identifier: .gregorian)
        let userId = UUID()
        let endDate = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 4, day: 9)))

        viewModel.fitnessProfile = FitnessProfile(
            id: UUID(),
            userId: userId,
            heightCm: 177.8,
            weightKg: 81,
            goalWeightKg: nil,
            fitnessGoal: .improvePTScore,
            experienceLevel: .intermediate,
            workoutSplit: .pushPullLegs,
            dailyCalorieTarget: nil,
            weeklyWorkoutTarget: 5,
            createdAt: endDate,
            updatedAt: endDate
        )

        let workoutOffsets = [0, 4, 7, 9, 10]
        viewModel.workoutHistory = workoutOffsets.compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: endDate) else { return nil }
            return WorkoutLog(
                id: UUID(),
                userId: userId,
                workoutType: "Planned",
                splitDay: nil,
                durationSeconds: 1800,
                caloriesBurned: nil,
                notes: nil,
                loggedAt: date
            )
        }

        let snapshots = viewModel.weeklyPlannerSnapshots(weeks: 2, endingAt: endDate)
        XCTAssertEqual(snapshots.count, 2)
        XCTAssertLessThan(snapshots[0].startDate, snapshots[1].startDate)
        XCTAssertEqual(snapshots[0].completedDays, 3)
        XCTAssertEqual(snapshots[0].totalDays, 6)
        XCTAssertEqual(snapshots[0].completionPercent, 50)
        XCTAssertEqual(snapshots[1].completedDays, 2)
        XCTAssertEqual(snapshots[1].totalDays, 4)
        XCTAssertEqual(snapshots[1].completionPercent, 50)
    }

    @MainActor
    func testPTDashboardPlannerPromptPrioritizesTodaysOpenWorkout() throws {
        let viewModel = PTDashboardViewModel()
        let calendar = Calendar(identifier: .gregorian)
        let userId = UUID()
        let today = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 4, day: 2)))

        viewModel.fitnessProfile = FitnessProfile(
            id: UUID(),
            userId: userId,
            heightCm: 177.8,
            weightKg: 81,
            goalWeightKg: nil,
            fitnessGoal: .improvePTScore,
            experienceLevel: .intermediate,
            workoutSplit: .pushPullLegs,
            dailyCalorieTarget: nil,
            weeklyWorkoutTarget: 5,
            createdAt: today,
            updatedAt: today
        )

        let sunday = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 3, day: 29)))
        viewModel.workoutHistory = [
            WorkoutLog(id: UUID(), userId: userId, workoutType: "Push", splitDay: "Push", durationSeconds: 1800, caloriesBurned: nil, notes: nil, loggedAt: sunday)
        ]

        let prompt = try XCTUnwrap(viewModel.plannerPrompt(endingAt: today))
        XCTAssertEqual(prompt.kind, .today)
        XCTAssertTrue(prompt.detail.contains("missed session"))
        XCTAssertTrue(calendar.isDate(prompt.date, inSameDayAs: today))
    }

    @MainActor
    func testPTDashboardPlannerPromptFallsBackToUpcomingWorkout() throws {
        let viewModel = PTDashboardViewModel()
        let calendar = Calendar(identifier: .gregorian)
        let userId = UUID()
        let today = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 4, day: 1)))

        viewModel.fitnessProfile = FitnessProfile(
            id: UUID(),
            userId: userId,
            heightCm: 177.8,
            weightKg: 81,
            goalWeightKg: nil,
            fitnessGoal: .improvePTScore,
            experienceLevel: .intermediate,
            workoutSplit: .pushPullLegs,
            dailyCalorieTarget: nil,
            weeklyWorkoutTarget: 5,
            createdAt: today,
            updatedAt: today
        )

        let completedDates = (1...14).compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: today)
        }
        .filter { date in
            (viewModel.plannedWorkout(on: date)?.isRestDay == false)
        }
        viewModel.workoutHistory = completedDates.map { date in
            WorkoutLog(
                id: UUID(),
                userId: userId,
                workoutType: "Planned",
                splitDay: nil,
                durationSeconds: 1800,
                caloriesBurned: nil,
                notes: nil,
                loggedAt: date
            )
        }

        let prompt = try XCTUnwrap(viewModel.plannerPrompt(endingAt: today))
        XCTAssertEqual(prompt.kind, .upcoming)
        XCTAssertEqual(prompt.title, "Next session is coming up")
        XCTAssertTrue(prompt.detail.contains("Thursday"))
    }

    @MainActor
    func testPTDashboardPlannerPromptMissedOnlyModeSkipsTodaysWorkout() throws {
        let viewModel = PTDashboardViewModel()
        let calendar = Calendar(identifier: .gregorian)
        let userId = UUID()
        let today = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 4, day: 2)))

        viewModel.fitnessProfile = FitnessProfile(
            id: UUID(),
            userId: userId,
            heightCm: 177.8,
            weightKg: 81,
            goalWeightKg: nil,
            fitnessGoal: .improvePTScore,
            experienceLevel: .intermediate,
            workoutSplit: .pushPullLegs,
            dailyCalorieTarget: nil,
            weeklyWorkoutTarget: 5,
            createdAt: today,
            updatedAt: today
        )

        let prompt = try XCTUnwrap(viewModel.plannerPrompt(mode: .missedOnly, endingAt: today))
        XCTAssertEqual(prompt.kind, .missed)
        XCTAssertFalse(calendar.isDate(prompt.date, inSameDayAs: today))
    }

    private func makePromotionData(
        branch: MilitaryBranch,
        armyMilEdPts: Int? = nil,
        armyCivEdPts: Int? = nil,
        armyAwardsPts: Int? = nil,
        armyMilTrgPts: Int? = nil,
        armyAftPts: Int? = nil,
        armyWeaponsPts: Int? = nil,
        armyMosCutoff: Int? = nil,
        wapsSktRaw: Int? = nil,
        wapsPfeRaw: Int? = nil,
        wapsEprRating: Int? = nil,
        wapsDecorationsPts: Int? = nil,
        wapsTisYears: Int? = nil,
        wapsTigMonths: Int? = nil,
        wapsAfadconsPts: Int? = nil,
        wapsCutoffPublished: Int? = nil,
        navyPma: Double? = nil,
        navyExamRaw: Int? = nil,
        navyAwardsPts: Int? = nil,
        navySipgYears: Double? = nil,
        navyPnaAttempts: Int? = nil,
        marineProMark: Double? = nil,
        marineConMark: Double? = nil,
        marinePftRaw: Int? = nil,
        marineCftRaw: Int? = nil,
        marineRifleQual: Int? = nil,
        marineMciCredits: Int? = nil,
        marineCutScore: Int? = nil,
        cgSweRaw: Int? = nil,
        cgPerfFactor: Double? = nil,
        cgCutScore: Int? = nil
    ) -> PromotionData {
        PromotionData(
            id: UUID(),
            userId: UUID(),
            branch: branch,
            currentPayGrade: "Current",
            targetPayGrade: "Target",
            monthsInService: 0,
            monthsInGrade: 0,
            armyMilEdPts: armyMilEdPts,
            armyCivEdPts: armyCivEdPts,
            armyAwardsPts: armyAwardsPts,
            armyMilTrgPts: armyMilTrgPts,
            armyAftPts: armyAftPts,
            armyWeaponsPts: armyWeaponsPts,
            armyMosCutoff: armyMosCutoff,
            armyMos: nil,
            wapsSktRaw: wapsSktRaw,
            wapsPfeRaw: wapsPfeRaw,
            wapsEprRating: wapsEprRating,
            wapsDecorationsPts: wapsDecorationsPts,
            wapsAfadconsPts: wapsAfadconsPts,
            wapsTisYears: wapsTisYears,
            wapsTigMonths: wapsTigMonths,
            wapsCutoffPublished: wapsCutoffPublished,
            navyPma: navyPma,
            navyExamRaw: navyExamRaw,
            navyAwardsPts: navyAwardsPts,
            navySipgYears: navySipgYears,
            navyPnaAttempts: navyPnaAttempts,
            marineProMark: marineProMark,
            marineConMark: marineConMark,
            marinePftRaw: marinePftRaw,
            marineCftRaw: marineCftRaw,
            marineRifleQual: marineRifleQual,
            marineMciCredits: marineMciCredits,
            marineCutScore: marineCutScore,
            cgSweRaw: cgSweRaw,
            cgPerfFactor: cgPerfFactor,
            cgCutScore: cgCutScore,
            nextBoardDate: nil,
            boardNotes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
