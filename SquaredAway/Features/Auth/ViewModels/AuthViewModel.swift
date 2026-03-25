import SwiftUI

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var authState: AuthState = .unknown
    @Published var isLoading = false
    @Published private(set) var currentUserId: UUID?
    @Published private(set) var currentUserEmail = ""
    @Published private(set) var currentProfile: UserProfile?

    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var staySignedIn = true

    @Published var emailError: String?
    @Published var passwordError: String?
    @Published var confirmPasswordError: String?
    @Published var generalError: String?

    private let authService = AuthService.shared
    private let profileService = ProfileService.shared

    init() {
        Task { await restoreSession() }
    }

    func handleIncomingURL(_ url: URL) async {
        let action = SupabaseManager.shared.handleAuthCallback(url)

        switch action {
        case .passwordRecovery:
            clearErrors()
            if let result = try? await authService.restoreSession() {
                currentUserId = result.userId
                currentUserEmail = result.email
            }
            authState = .passwordRecovery

        case .standard:
            await restoreSession()
        }
    }

    private func restoreSession() async {
        guard let result = try? await authService.restoreSession() else {
            clearSessionData()
            authState = .unauthenticated
            return
        }

        currentUserId = result.userId
        currentUserEmail = result.email

        if result.needsEmailVerification {
            authState = .pendingVerification(email: result.email)
            return
        }

        await resolvePostAuthState(userId: result.userId)
    }

    func signIn() async {
        guard validateLoginForm() else { return }

        isLoading = true
        clearErrors()
        defer { isLoading = false }

        do {
            let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
            let result = try await authService.signIn(email: trimmedEmail, password: password)
            currentUserId = result.userId
            currentUserEmail = result.email

            if result.needsEmailVerification {
                authState = .pendingVerification(email: result.email)
                return
            }

            await resolvePostAuthState(userId: result.userId)
        } catch let error as AppError {
            handleAuthError(error)
        } catch {
            generalError = error.localizedDescription
        }
    }

    func signUp() async {
        guard validateSignupForm() else { return }

        isLoading = true
        clearErrors()
        defer { isLoading = false }

        do {
            let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
            let result = try await authService.signUp(email: trimmedEmail, password: password)
            currentUserId = result.userId
            currentUserEmail = result.email
            authState = .pendingVerification(email: result.email)
        } catch let error as AppError {
            handleAuthError(error)
        } catch {
            generalError = error.localizedDescription
        }
    }

    func signOut() async {
        do {
            try await authService.signOut()
            resetFormFields()
            clearSessionData()
            authState = .unauthenticated
        } catch {
            generalError = error.localizedDescription
        }
    }

    func requestEmailChange(to newEmail: String) async throws {
        let trimmedEmail = newEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            throw AppError.authFailed("Email is required.")
        }
        guard isValidEmail(trimmedEmail) else {
            throw AppError.authFailed("Enter a valid email address.")
        }

        isLoading = true
        clearErrors()
        defer { isLoading = false }

        do {
            try await authService.updateEmail(trimmedEmail)
        } catch let error as AppError {
            generalError = error.errorDescription
            throw error
        } catch {
            generalError = error.localizedDescription
            throw error
        }
    }

    func updatePassword(to newPassword: String, confirmation: String) async throws {
        guard !newPassword.isEmpty else {
            throw AppError.authFailed("New password is required.")
        }
        guard newPassword.count >= 8 else {
            throw AppError.authFailed("Password must be at least 8 characters.")
        }
        guard newPassword == confirmation else {
            throw AppError.authFailed("Passwords don't match.")
        }

        isLoading = true
        clearErrors()
        defer { isLoading = false }

        do {
            try await authService.updatePassword(newPassword)
        } catch let error as AppError {
            generalError = error.errorDescription
            throw error
        } catch {
            generalError = error.localizedDescription
            throw error
        }
    }

    func sendPasswordResetToCurrentEmail() async throws {
        guard !currentUserEmail.isEmpty else {
            throw AppError.authFailed("No email is available for this account.")
        }

        isLoading = true
        clearErrors()
        defer { isLoading = false }

        do {
            try await authService.sendPasswordReset(email: currentUserEmail)
        } catch let error as AppError {
            generalError = error.errorDescription
            throw error
        } catch {
            generalError = error.localizedDescription
            throw error
        }
    }

    func requestPasswordReset(for email: String) async throws {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            throw AppError.authFailed("Email is required.")
        }
        guard isValidEmail(trimmedEmail) else {
            throw AppError.authFailed("Enter a valid email address.")
        }

        isLoading = true
        clearErrors()
        defer { isLoading = false }

        do {
            try await authService.sendPasswordReset(email: trimmedEmail)
        } catch let error as AppError {
            generalError = error.errorDescription
            throw error
        } catch {
            generalError = error.localizedDescription
            throw error
        }
    }

    func completePasswordRecovery(newPassword: String, confirmation: String) async throws {
        try await updatePassword(to: newPassword, confirmation: confirmation)

        if let result = try? await authService.restoreSession() {
            currentUserId = result.userId
            currentUserEmail = result.email
            await resolvePostAuthState(userId: result.userId)
        } else {
            authState = .unauthenticated
        }
    }

    func cancelPasswordRecovery() async {
        await signOut()
    }

    func deleteAccount() async throws {
        isLoading = true
        clearErrors()
        defer { isLoading = false }

        do {
            try await authService.deleteAccount()
            resetFormFields()
            clearSessionData()
            authState = .unauthenticated
        } catch let error as AppError {
            generalError = error.errorDescription
            throw error
        } catch {
            generalError = error.localizedDescription
            throw error
        }
    }

    func checkEmailVerified() async {
        isLoading = true
        defer { isLoading = false }

        clearErrors()

        let verified = await authService.isEmailVerified()
        guard verified else {
            generalError = "Email not verified yet. Please check your inbox."
            return
        }

        guard let result = try? await authService.restoreSession(),
              !result.needsEmailVerification else {
            generalError = "Verification not detected yet. Please try again."
            return
        }

        currentUserId = result.userId
        currentUserEmail = result.email
        await resolvePostAuthState(userId: result.userId)
    }

    func resendVerification() async {
        guard case .pendingVerification(let pendingEmail) = authState else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            try await authService.resendVerificationEmail(email: pendingEmail)
            generalError = nil
        } catch let error as AppError {
            generalError = error.errorDescription
        } catch {
            generalError = error.localizedDescription
        }
    }

    private func resolvePostAuthState(userId: UUID) async {
        do {
            var profile = try await profileService.fetchProfile(userId: userId)

            if let currentProfileEmail = profile?.email,
               !currentUserEmail.isEmpty,
               currentProfileEmail != currentUserEmail {
                try? await profileService.updateEmail(userId: userId, email: currentUserEmail)
                profile?.email = currentUserEmail
            }

            currentProfile = profile
            if let profile, !profile.email.isEmpty {
                currentUserEmail = profile.email
            }
            authState = (profile?.onboardingComplete == true) ? .authenticated : .needsOnboarding
        } catch {
            currentProfile = nil
            authState = .needsOnboarding
        }
    }

    func refreshProfile() async {
        guard let currentUserId else { return }
        await resolvePostAuthState(userId: currentUserId)
    }

    func completeOnboarding(with draft: OnboardingProfileDraft) async {
        guard validateOnboardingDraft(draft) else { return }
        guard let currentUserId else {
            generalError = "Session unavailable. Please sign in again."
            authState = .unauthenticated
            return
        }

        isLoading = true
        clearErrors()
        defer { isLoading = false }

        do {
            let existingProfile = try await profileService.fetchProfile(userId: currentUserId)
            let resolvedEmail = {
                if let existingProfile, !existingProfile.email.isEmpty {
                    return existingProfile.email
                }
                return currentUserEmail
            }()
            let updatedProfile = UserProfile(
                id: currentUserId,
                email: resolvedEmail,
                branch: draft.branch,
                rank: draft.rank.trimmingCharacters(in: .whitespacesAndNewlines),
                mos: draft.mos.trimmingCharacters(in: .whitespacesAndNewlines),
                discoverySource: draft.discoverySource,
                discoveryNotes: draft.discoveryNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? nil
                    : draft.discoveryNotes.trimmingCharacters(in: .whitespacesAndNewlines),
                firstName: draft.firstName.trimmingCharacters(in: .whitespacesAndNewlines),
                lastName: draft.lastName.trimmingCharacters(in: .whitespacesAndNewlines),
                heightCm: Double(draft.heightCm),
                weightKg: Double(draft.weightKg),
                fitnessGoal: draft.fitnessGoal,
                onboardingComplete: true,
                createdAt: existingProfile?.createdAt ?? Date(),
                updatedAt: Date()
            )

            if existingProfile == nil {
                try await profileService.createProfile(updatedProfile)
            } else {
                try await profileService.updateProfile(updatedProfile)
            }

            currentProfile = updatedProfile
            currentUserEmail = updatedProfile.email
            authState = .authenticated
        } catch let error as AppError {
            generalError = error.errorDescription
        } catch {
            generalError = error.localizedDescription
        }
    }

    func updateProfileSettings(with draft: ProfileSettingsDraft) async {
        guard validateProfileSettingsDraft(draft) else { return }
        guard let currentUserId else {
            generalError = "Session unavailable. Please sign in again."
            authState = .unauthenticated
            return
        }

        isLoading = true
        clearErrors()
        defer { isLoading = false }

        do {
            let existingProfile = try await profileService.fetchProfile(userId: currentUserId)
            guard let existingProfile else {
                generalError = "Profile not found. Please complete onboarding again."
                authState = .needsOnboarding
                return
            }

            let updatedProfile = UserProfile(
                id: existingProfile.id,
                email: existingProfile.email,
                branch: draft.branch,
                rank: draft.rank.trimmingCharacters(in: .whitespacesAndNewlines),
                mos: draft.mos.trimmingCharacters(in: .whitespacesAndNewlines),
                discoverySource: draft.discoverySource,
                discoveryNotes: draft.discoveryNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? nil
                    : draft.discoveryNotes.trimmingCharacters(in: .whitespacesAndNewlines),
                firstName: draft.firstName.trimmingCharacters(in: .whitespacesAndNewlines),
                lastName: draft.lastName.trimmingCharacters(in: .whitespacesAndNewlines),
                heightCm: Double(draft.heightCm),
                weightKg: Double(draft.weightKg),
                fitnessGoal: draft.fitnessGoal,
                onboardingComplete: true,
                createdAt: existingProfile.createdAt,
                updatedAt: Date()
            )

            try await profileService.updateProfile(updatedProfile)
            currentProfile = updatedProfile
        } catch let error as AppError {
            generalError = error.errorDescription
        } catch {
            generalError = error.localizedDescription
        }
    }

    private func validateLoginForm() -> Bool {
        clearErrors()
        var isValid = true

        if email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            emailError = "Email is required."
            isValid = false
        } else if !isValidEmail(email) {
            emailError = "Enter a valid email address."
            isValid = false
        }

        if password.isEmpty {
            passwordError = "Password is required."
            isValid = false
        }

        return isValid
    }

    private func validateSignupForm() -> Bool {
        clearErrors()
        var isValid = true

        if email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            emailError = "Email is required."
            isValid = false
        } else if !isValidEmail(email) {
            emailError = "Enter a valid email address."
            isValid = false
        }

        if password.isEmpty {
            passwordError = "Password is required."
            isValid = false
        } else if password.count < 8 {
            passwordError = "Password must be at least 8 characters."
            isValid = false
        }

        if confirmPassword != password {
            confirmPasswordError = "Passwords don't match."
            isValid = false
        }

        return isValid
    }

    private func isValidEmail(_ email: String) -> Bool {
        let regex = #"^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return email.range(of: regex, options: .regularExpression) != nil
    }

    func clearErrors() {
        emailError = nil
        passwordError = nil
        confirmPasswordError = nil
        generalError = nil
    }

    private func resetFormFields() {
        email = ""
        password = ""
        confirmPassword = ""
    }

    private func clearSessionData() {
        currentUserId = nil
        currentUserEmail = ""
        currentProfile = nil
    }

    private func validateOnboardingDraft(_ draft: OnboardingProfileDraft) -> Bool {
        let firstName = draft.firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let lastName = draft.lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let rank = draft.rank.trimmingCharacters(in: .whitespacesAndNewlines)
        let mos = draft.mos.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !firstName.isEmpty else {
            generalError = "First name is required."
            return false
        }

        guard !lastName.isEmpty else {
            generalError = "Last name is required."
            return false
        }

        guard !rank.isEmpty else {
            generalError = "Rank is required."
            return false
        }

        guard !mos.isEmpty else {
            generalError = "\(draft.branch.mosLabel) is required."
            return false
        }

        if !draft.heightCm.isEmpty, Double(draft.heightCm) == nil {
            generalError = "Height must be a number in centimeters."
            return false
        }

        if !draft.weightKg.isEmpty, Double(draft.weightKg) == nil {
            generalError = "Weight must be a number in kilograms."
            return false
        }

        return true
    }

    private func validateProfileSettingsDraft(_ draft: ProfileSettingsDraft) -> Bool {
        let firstName = draft.firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let lastName = draft.lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let rank = draft.rank.trimmingCharacters(in: .whitespacesAndNewlines)
        let mos = draft.mos.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !firstName.isEmpty else {
            generalError = "First name is required."
            return false
        }

        guard !lastName.isEmpty else {
            generalError = "Last name is required."
            return false
        }

        guard !rank.isEmpty else {
            generalError = "Rank is required."
            return false
        }

        guard !mos.isEmpty else {
            generalError = "\(draft.branch.mosLabel) is required."
            return false
        }

        if !draft.heightCm.isEmpty, Double(draft.heightCm) == nil {
            generalError = "Height must be a number in centimeters."
            return false
        }

        if !draft.weightKg.isEmpty, Double(draft.weightKg) == nil {
            generalError = "Weight must be a number in kilograms."
            return false
        }

        return true
    }

    private func handleAuthError(_ error: AppError) {
        switch error {
        case .authFailed(let message):
            let lowercasedMessage = message.lowercased()
            if lowercasedMessage.contains("email") {
                emailError = message
            } else if lowercasedMessage.contains("password") {
                passwordError = message
            } else {
                generalError = message
            }
        case .networkError:
            generalError = "No connection. Check your network and try again."
        default:
            generalError = error.errorDescription
        }
    }
}
