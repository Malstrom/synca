import Foundation
import Observation

/// Backs `ProfileView` — the "My Health" screen. Aggregates `GET /me` (display
/// name) and `GET /signals/me/summary` (rhythm/energy/sleep summary).
@MainActor
@Observable
final class ProfileViewModel {
    private let apiClient: APIClientProtocol

    var isLoading = false
    var errorMessage: String?
    private(set) var profile: Profile?
    private(set) var signalsSummary: SignalsSummary?

    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        if let me = try? await apiClient.me() {
            profile = me.profile
        } else {
            errorMessage = "Couldn't load your profile."
        }

        // `no_signals` (404) is an expected state, not an error — see
        // docs/product/phases/phase-0.md § UC-09.
        signalsSummary = try? await apiClient.signalsSummary()
    }
}
