import Foundation
import Supabase

final class TrackerService {
    static let shared = TrackerService()

    private init() {}

    private var client: SupabaseClient { SupabaseManager.shared.client }
    private let table = SupabaseManager.Tables.trackerData

    func fetchTracker(userId: UUID) async throws -> TrackerData? {
        let response: [TrackerData] = try await client
            .from(table)
            .select()
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        return response.first
    }

    func createTracker(_ tracker: TrackerData) async throws {
        try await client
            .from(table)
            .insert(tracker)
            .execute()
    }

    func updateTracker(_ tracker: TrackerData) async throws {
        try await client
            .from(table)
            .update(tracker)
            .eq("id", value: tracker.id.uuidString)
            .execute()
    }

    func saveTracker(_ tracker: TrackerData) async throws {
        if try await fetchTracker(userId: tracker.userId) == nil {
            try await createTracker(tracker)
        } else {
            try await updateTracker(tracker)
        }
    }

    func deleteTracker(id: UUID) async throws {
        try await client
            .from(table)
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}
