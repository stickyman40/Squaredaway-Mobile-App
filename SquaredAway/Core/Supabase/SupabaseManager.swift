import Foundation
import Supabase

enum AuthCallbackAction: Equatable {
    case passwordRecovery
    case standard
}

enum SupabaseConfig {
    static let projectURL = URL(
        string: ProcessInfo.processInfo.environment["SUPABASE_URL"]
            ?? "https://cwfipabgnufbmclexunm.supabase.co"
    )!

    static let anonKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"]
        ?? "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN3ZmlwYWJnbnVmYm1jbGV4dW5tIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI4NTQ5NDMsImV4cCI6MjA4ODQzMDk0M30.0i837hYp5GTk9CYIreDC6hI8zKu8KvDjYpCdrjlb3wY"

    static let redirectURL = URL(
        string: ProcessInfo.processInfo.environment["SUPABASE_REDIRECT_URL"]
            ?? "squaredaway://auth-callback"
    )!
}

final class SupabaseManager {
    static let shared = SupabaseManager()

    private init() {}

    lazy var client: SupabaseClient = {
        SupabaseClient(
            supabaseURL: SupabaseConfig.projectURL,
            supabaseKey: SupabaseConfig.anonKey
        )
    }()

    func handleAuthCallback(_ url: URL) -> AuthCallbackAction {
        client.auth.handle(url)
        return callbackAction(for: url)
    }

    enum Tables {
        static let usersProfile = "users_profile"
        static let notificationPreferences = "notification_preferences"
        static let fitnessLogs = "fitness_logs"
        static let nutritionLogs = "nutrition_logs"
        static let promotionsData = "promotions_data"
        static let payData = "pay_data"
        static let trackerData = "tracker_data"
        static let pcsData = "pcs_data"
        static let benefitsData = "benefits_data"
        static let notifications = "notifications"
    }

    func callbackAction(for url: URL) -> AuthCallbackAction {
        if authCallbackParameter(named: "type", in: url)?.lowercased() == "recovery" {
            return .passwordRecovery
        }
        return .standard
    }

    private func authCallbackParameter(named name: String, in url: URL) -> String? {
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let value = components.queryItems?.first(where: { $0.name == name })?.value {
            return value
        }

        guard let fragment = URLComponents(url: url, resolvingAgainstBaseURL: false)?.fragment else {
            return nil
        }

        return fragment
            .split(separator: "&")
            .compactMap { pair -> (String, String)? in
                let parts = pair.split(separator: "=", maxSplits: 1).map(String.init)
                guard parts.count == 2 else { return nil }
                return (parts[0], parts[1].removingPercentEncoding ?? parts[1])
            }
            .first(where: { $0.0 == name })?
            .1
    }
}
