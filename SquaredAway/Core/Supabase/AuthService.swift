import Foundation
import Supabase

final class AuthService {
    static let shared = AuthService()

    private init() {}

    private var client: SupabaseClient { SupabaseManager.shared.client }

    func signUp(email: String, password: String) async throws -> AuthResult {
        do {
            let response = try await client.auth.signUp(
                email: email,
                password: password,
                redirectTo: SupabaseConfig.redirectURL
            )

            return AuthResult(
                userId: response.user.id,
                email: response.user.email ?? email,
                needsEmailVerification: response.session == nil
            )
        } catch {
            throw mapSupabaseError(error)
        }
    }

    func signIn(email: String, password: String) async throws -> AuthResult {
        do {
            let session = try await client.auth.signIn(email: email, password: password)
            return AuthResult(
                userId: session.user.id,
                email: session.user.email ?? email,
                needsEmailVerification: session.user.emailConfirmedAt == nil
            )
        } catch {
            throw mapSupabaseError(error)
        }
    }

    func signOut() async throws {
        do {
            try await client.auth.signOut()
        } catch {
            throw mapSupabaseError(error)
        }
    }

    func resendVerificationEmail(email: String) async throws {
        do {
            try await client.auth.resend(email: email, type: .signup)
        } catch {
            throw mapSupabaseError(error)
        }
    }

    func restoreSession() async throws -> AuthResult? {
        do {
            let session = try await client.auth.session
            return AuthResult(
                userId: session.user.id,
                email: session.user.email ?? "",
                needsEmailVerification: session.user.emailConfirmedAt == nil
            )
        } catch {
            return nil
        }
    }

    func isEmailVerified() async -> Bool {
        guard let user = try? await client.auth.user() else {
            return false
        }
        return user.emailConfirmedAt != nil
    }

    func sendPasswordReset(email: String) async throws {
        do {
            try await client.auth.resetPasswordForEmail(email, redirectTo: SupabaseConfig.redirectURL)
        } catch {
            throw mapSupabaseError(error)
        }
    }

    func updateEmail(_ email: String) async throws {
        do {
            try await client.auth.update(user: UserAttributes(email: email))
        } catch {
            throw mapSupabaseError(error)
        }
    }

    func updatePassword(_ password: String) async throws {
        do {
            try await client.auth.update(user: UserAttributes(password: password))
        } catch {
            throw mapSupabaseError(error)
        }
    }

    func deleteAccount() async throws {
        do {
            try await client.rpc("delete_my_account").execute()
        } catch {
            throw mapSupabaseError(error)
        }
    }

    private func mapSupabaseError(_ error: Error) -> AppError {
        let message = error.localizedDescription.lowercased()

        if message.contains("invalid login credentials") || message.contains("invalid_credentials") {
            return .authFailed("Incorrect email or password.")
        }

        if message.contains("email not confirmed") {
            return .authFailed("Please verify your email before signing in.")
        }

        if message.contains("user already registered") {
            return .authFailed("An account with this email already exists.")
        }

        if message.contains("network") || message.contains("connection") {
            return .networkError
        }

        if message.contains("password") && message.contains("weak") {
            return .authFailed("Password must be at least 8 characters.")
        }

        return .authFailed(error.localizedDescription)
    }
}

struct AuthResult {
    let userId: UUID
    let email: String
    let needsEmailVerification: Bool
}
