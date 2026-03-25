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

    func testSupabaseTableConstantsIncludeNewFeatureTables() {
        XCTAssertEqual(SupabaseManager.Tables.trackerData, "tracker_data")
        XCTAssertEqual(SupabaseManager.Tables.pcsData, "pcs_data")
        XCTAssertEqual(SupabaseManager.Tables.benefitsData, "benefits_data")
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
}
