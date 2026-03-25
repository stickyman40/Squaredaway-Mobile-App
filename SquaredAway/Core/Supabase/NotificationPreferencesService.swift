import Foundation
import Supabase

final class NotificationPreferencesService {
    static let shared = NotificationPreferencesService()

    private init() {}

    private var client: SupabaseClient { SupabaseManager.shared.client }
    private let table = SupabaseManager.Tables.notificationPreferences

    func fetchPreferences(userId: UUID) async throws -> NotificationPreferenceRecord? {
        let response: [NotificationPreferenceRecord] = try await client
            .from(table)
            .select()
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        return response.first
    }

    func updatePreferences(_ preferences: NotificationPreferenceRecord) async throws {
        try await client
            .from(table)
            .upsert(
                NotificationPreferencesUpsert(
                    userId: preferences.userId,
                    milestonesEnabled: preferences.milestonesEnabled,
                    readinessEnabled: preferences.readinessEnabled,
                    activityEnabled: preferences.activityEnabled
                )
            )
            .execute()
    }
}

private struct NotificationPreferencesUpsert: Encodable {
    let userId: UUID
    let milestonesEnabled: Bool
    let readinessEnabled: Bool
    let activityEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case milestonesEnabled = "milestones_enabled"
        case readinessEnabled = "readiness_enabled"
        case activityEnabled = "activity_enabled"
    }
}
