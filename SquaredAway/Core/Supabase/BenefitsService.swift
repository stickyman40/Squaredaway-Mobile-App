import Foundation
import Supabase

final class BenefitsService {
    static let shared = BenefitsService()

    private init() {}

    private var client: SupabaseClient { SupabaseManager.shared.client }
    private let table = SupabaseManager.Tables.benefitsData

    func fetchBenefits(userId: UUID) async throws -> BenefitsData? {
        let response: [BenefitsData] = try await client
            .from(table)
            .select()
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        return response.first
    }

    func createBenefits(_ benefits: BenefitsData) async throws {
        try await client
            .from(table)
            .insert(benefits)
            .execute()
    }

    func updateBenefits(_ benefits: BenefitsData) async throws {
        try await client
            .from(table)
            .update(benefits)
            .eq("id", value: benefits.id.uuidString)
            .execute()
    }

    func saveBenefits(_ benefits: BenefitsData) async throws {
        if try await fetchBenefits(userId: benefits.userId) == nil {
            try await createBenefits(benefits)
        } else {
            try await updateBenefits(benefits)
        }
    }

    func deleteBenefits(id: UUID) async throws {
        try await client
            .from(table)
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}
