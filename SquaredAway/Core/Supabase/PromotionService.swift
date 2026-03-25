import Foundation
import Supabase

final class PromotionService {
    static let shared = PromotionService()

    private init() {}

    private var client: SupabaseClient { SupabaseManager.shared.client }
    private let table = SupabaseManager.Tables.promotionsData

    func fetchPromotion(userId: UUID) async throws -> PromotionData? {
        let response: [PromotionData] = try await client
            .from(table)
            .select()
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        return response.first
    }

    func createPromotion(_ promotion: PromotionData) async throws {
        try await client
            .from(table)
            .insert(promotion)
            .execute()
    }

    func updatePromotion(_ promotion: PromotionData) async throws {
        try await client
            .from(table)
            .update(promotion)
            .eq("id", value: promotion.id.uuidString)
            .execute()
    }

    func savePromotion(_ promotion: PromotionData) async throws {
        if try await fetchPromotion(userId: promotion.userId) == nil {
            try await createPromotion(promotion)
        } else {
            try await updatePromotion(promotion)
        }
    }

    func deletePromotion(id: UUID) async throws {
        try await client
            .from(table)
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}
