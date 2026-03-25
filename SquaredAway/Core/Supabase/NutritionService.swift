import Foundation
import Supabase

final class NutritionService {
    static let shared = NutritionService()

    private init() {}

    private var client: SupabaseClient { SupabaseManager.shared.client }
    private let table = SupabaseManager.Tables.nutritionLogs

    func fetchLogs(userId: UUID) async throws -> [NutritionLog] {
        let response: [NutritionLog] = try await client
            .from(table)
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("logged_at", ascending: false)
            .execute()
            .value

        return response
    }

    func createLog(_ log: NutritionLog) async throws {
        try await client
            .from(table)
            .insert(log)
            .execute()
    }

    func updateLog(_ log: NutritionLog) async throws {
        try await client
            .from(table)
            .update(log)
            .eq("id", value: log.id.uuidString)
            .execute()
    }

    func deleteLog(id: UUID) async throws {
        try await client
            .from(table)
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}
