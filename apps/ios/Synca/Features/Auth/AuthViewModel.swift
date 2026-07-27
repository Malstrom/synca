import Foundation
import Observation

/// Backs the two guest-account screens that come after a Spark result:
/// `SaveResultsView` (email capture) and `ActivationView` (display name).
/// Spans both screens for the same reason `SparkViewModel` spans its three
/// steps — see docs/architecture/ios-structure.md § AppRouter and
/// docs/product/phases/phase-0.md § UF-04.
@MainActor
@Observable
final class AuthViewModel {
    private let apiClient: APIClientProtocol
    private let keychain: KeychainServiceProtocol

    var email: String = ""
    var displayName: String = ""
    var isLoading = false
    var errorMessage: String?

    init(apiClient: APIClientProtocol = APIClient.shared, keychain: KeychainServiceProtocol = KeychainService.shared) {
        self.apiClient = apiClient
        self.keychain = keychain
    }

    /// "Save your results" screen — `POST /auth/guest/claim_email`.
    func saveResults() async -> Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        guard !trimmedEmail.isEmpty else {
            errorMessage = "Enter an email to save your results."
            return false
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            _ = try await apiClient.claimEmail(trimmedEmail)
            return true
        } catch {
            errorMessage = Self.message(for: error)
            return false
        }
    }

    /// "Almost there" screen — `POST /auth/activate`. On success the guest
    /// account is upgraded to `active` and a permanent token pair replaces the
    /// short-lived guest one in the Keychain.
    func activate() async -> Bool {
        let trimmedName = displayName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            errorMessage = "Enter a display name to activate your account."
            return false
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await apiClient.activate(displayName: trimmedName)
            try keychain.save(StoredSession(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken,
                accountType: .active
            ))
            return true
        } catch {
            errorMessage = Self.message(for: error)
            return false
        }
    }

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? "Something went wrong. Please try again."
    }
}
