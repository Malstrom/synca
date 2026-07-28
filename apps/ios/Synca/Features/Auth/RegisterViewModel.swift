import Foundation
import Observation

/// Backs `RegisterView` — "Create account" on the entry screen, for a
/// brand-new user who isn't going through a Spark session first. Distinct
/// from `AuthViewModel` (which owns the guest-activation sequence): this is
/// direct email+password signup via `POST /auth/register`.
@MainActor
@Observable
final class RegisterViewModel {
    private let apiClient: APIClientProtocol
    private let keychain: KeychainServiceProtocol

    var email: String = ""
    var password: String = ""
    var displayName: String = ""
    var isLoading = false
    var errorMessage: String?

    private static let minPasswordLength = 8

    init(apiClient: APIClientProtocol = DemoMode.apiClient, keychain: KeychainServiceProtocol = KeychainService.shared) {
        self.apiClient = apiClient
        self.keychain = keychain
    }

    func register() async -> Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        let trimmedName = displayName.trimmingCharacters(in: .whitespaces)
        guard !trimmedEmail.isEmpty else {
            errorMessage = "Enter an email to create your account."
            return false
        }
        guard password.count >= Self.minPasswordLength else {
            errorMessage = "Password must be at least \(Self.minPasswordLength) characters."
            return false
        }
        guard !trimmedName.isEmpty else {
            errorMessage = "Enter a display name."
            return false
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await apiClient.register(email: trimmedEmail, password: password)
            try keychain.save(StoredSession(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken,
                accountType: .active
            ))
            let profile = Profile(
                displayName: trimmedName,
                birthDate: nil,
                gender: nil,
                bio: nil,
                city: nil,
                photoUrlMain: nil,
                photoUrls: nil,
                trustScore: nil,
                sparkVerified: nil
            )
            // Best-effort: the account is already created and usable even if
            // this fails — the user just won't have a display name set yet.
            _ = try? await apiClient.updateProfile(profile)
            return true
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Something went wrong. Please try again."
            return false
        }
    }
}
