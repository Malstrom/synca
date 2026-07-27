import Foundation
import Observation

/// Backs `LoginView` only — the "Go to my profile instead" shortcut on the Scan
/// QR screen, for a returning user with a full account. Separate from
/// `AuthViewModel` (which owns the guest-activation sequence: save email, then
/// set display name) — login is an unrelated, single-shot flow, not part of
/// that sequence.
@MainActor
@Observable
final class LoginViewModel {
    private let apiClient: APIClientProtocol
    private let keychain: KeychainServiceProtocol

    var email: String = ""
    var password: String = ""
    var isLoading = false
    var errorMessage: String?

    init(apiClient: APIClientProtocol = APIClient.shared, keychain: KeychainServiceProtocol = KeychainService.shared) {
        self.apiClient = apiClient
        self.keychain = keychain
    }

    func login() async -> Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            errorMessage = "Enter your email and password to sign in."
            return false
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await apiClient.login(email: trimmedEmail, password: password)
            // A successful password login always implies a full, activated
            // account — guest accounts (created via /auth/guest) never have a
            // password set, so there's no "guest" case to distinguish here.
            try keychain.save(StoredSession(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken,
                accountType: .active
            ))
            return true
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Something went wrong. Please try again."
            return false
        }
    }
}
