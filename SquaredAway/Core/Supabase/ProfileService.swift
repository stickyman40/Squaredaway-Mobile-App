import Foundation
import Supabase

final class ProfileService {
    static let shared = ProfileService()

    private init() {}

    private var client: SupabaseClient { SupabaseManager.shared.client }
    private let table = SupabaseManager.Tables.usersProfile

    func fetchProfile(userId: UUID) async throws -> UserProfile? {
        let response: [UserProfile] = try await client
            .from(table)
            .select()
            .eq("id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        return response.first
    }

    func createProfile(_ profile: UserProfile) async throws {
        try await client
            .from(table)
            .insert(profile)
            .execute()
    }

    func updateProfile(_ profile: UserProfile) async throws {
        try await client
            .from(table)
            .update(profile)
            .eq("id", value: profile.id.uuidString)
            .execute()
    }

    func updateEmail(userId: UUID, email: String) async throws {
        try await client
            .from(table)
            .update(["email": email])
            .eq("id", value: userId.uuidString)
            .execute()
    }

    func markOnboardingComplete(userId: UUID) async throws {
        try await client
            .from(table)
            .update(["onboarding_complete": true])
            .eq("id", value: userId.uuidString)
            .execute()
    }
}
