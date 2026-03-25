import Foundation
import Supabase

final class PayService {
    static let shared = PayService()

    private init() {}

    private var client: SupabaseClient { SupabaseManager.shared.client }
    private let table = SupabaseManager.Tables.payData

    func fetchPayData(userId: UUID) async throws -> PayData? {
        let response: [PayData] = try await client
            .from(table)
            .select()
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        return response.first
    }

    func createPayData(_ payData: PayData) async throws {
        try await client
            .from(table)
            .insert(payData)
            .execute()
    }

    func updatePayData(_ payData: PayData) async throws {
        try await client
            .from(table)
            .update(payData)
            .eq("id", value: payData.id.uuidString)
            .execute()
    }

    func savePayData(_ payData: PayData) async throws {
        if try await fetchPayData(userId: payData.userId) == nil {
            try await createPayData(payData)
        } else {
            try await updatePayData(payData)
        }
    }

    func deletePayData(id: UUID) async throws {
        try await client
            .from(table)
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}
