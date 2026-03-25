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

    func testNotificationCategoryBrandingReflectsCurrentCopy() {
        XCTAssertEqual(AppNotificationCategory.activity.title, "Fitness & Chow Activity")
        XCTAssertEqual(
            AppNotificationCategory.activity.subtitle,
            "Workout and chow entry create, edit, and delete events."
        )
        XCTAssertEqual(AppNotificationCategory.readiness.title, "Readiness Updates")
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
