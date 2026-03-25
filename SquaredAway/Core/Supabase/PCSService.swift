import Foundation
import Supabase

final class PCSService {
    static let shared = PCSService()

    private init() {}

    private var client: SupabaseClient { SupabaseManager.shared.client }
    private let table = SupabaseManager.Tables.pcsData

    func fetchPCS(userId: UUID) async throws -> PCSData? {
        let response: [PCSData] = try await client
            .from(table)
            .select()
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        return response.first
    }

    func createPCS(_ pcs: PCSData) async throws {
        try await client
            .from(table)
            .insert(pcs)
            .execute()
    }

    func updatePCS(_ pcs: PCSData) async throws {
        try await client
            .from(table)
            .update(pcs)
            .eq("id", value: pcs.id.uuidString)
            .execute()
    }

    func savePCS(_ pcs: PCSData) async throws {
        if try await fetchPCS(userId: pcs.userId) == nil {
            try await createPCS(pcs)
        } else {
            try await updatePCS(pcs)
        }
    }

    func deletePCS(id: UUID) async throws {
        try await client
            .from(table)
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}
