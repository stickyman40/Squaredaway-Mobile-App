import Foundation
import Supabase

final class AuthService {
    static let shared = AuthService()

    private init() {}

    private var client: SupabaseClient { SupabaseManager.shared.client }
    private static let encoder = JSONEncoder()

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

    func reauthenticate() async throws {
        do {
            try await client.auth.reauthenticate()
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

    func requestAccountDeletionConfirmation() async throws {
        struct RequestBody: Encodable {
            let redirect_url: String
        }

        let session: Session
        do {
            session = try await client.auth.session
        } catch {
            throw AppError.authFailed("Session unavailable. Please sign in again.")
        }

        guard var components = URLComponents(url: SupabaseConfig.projectURL, resolvingAgainstBaseURL: false) else {
            throw AppError.unknown("Unable to prepare account deletion request.")
        }
        components.path = "/functions/v1/request-account-deletion"

        guard let url = components.url else {
            throw AppError.unknown("Unable to prepare account deletion request.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try Self.encoder.encode(
            RequestBody(redirect_url: SupabaseConfig.redirectURL.absoluteString)
        )

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw mapSupabaseError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.unknown("Invalid response from account deletion request.")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw AppError.authFailed(errorMessage(from: data, fallback: "Couldn't send the delete confirmation email."))
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

    private func errorMessage(from data: Data, fallback: String) -> String {
        if let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let message = payload["message"] as? String, !message.isEmpty {
                return message
            }
            if let error = payload["error"] as? String, !error.isEmpty {
                return error
            }
        }

        if let message = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !message.isEmpty {
            return message
        }

        return fallback
    }
}

struct AuthResult {
    let userId: UUID
    let email: String
    let needsEmailVerification: Bool
}
