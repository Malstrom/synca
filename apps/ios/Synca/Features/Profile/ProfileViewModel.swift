import Foundation
import Observation

/// Backs `ProfileView` — the "My Health" screen. Aggregates `GET /me` (display
/// name) and `GET /signals/me/summary` (rhythm/energy/sleep summary).
@MainActor
@Observable
final class ProfileViewModel {
    private let apiClient: APIClientProtocol
    private let signalsViewModel: SignalsViewModel

    var isLoading = false
    var errorMessage: String?
    private(set) var profile: Profile?
    private(set) var signalsSummary: SignalsSummary?

    init(apiClient: APIClientProtocol = DemoMode.apiClient, signalsViewModel: SignalsViewModel? = nil) {
        self.apiClient = apiClient
        // Can't default-construct a `@MainActor` type in a parameter list — see
        // SignalAggregatorService's doc comment on the same gotcha.
        self.signalsViewModel = signalsViewModel ?? SignalsViewModel()
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

    /// Lets an already-active user connect Apple Health from their profile —
    /// `ConnectHealthView` only covers the guest-Spark flow, so anyone who
    /// registered directly (see `RegisterView`) or skipped it otherwise had no
    /// way back in.
    func connectHealth() async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        guard let summary = await signalsViewModel.connectAppleHealth() else {
            errorMessage = signalsViewModel.errorMessage
            return false
        }

        do {
            try await apiClient.updateHealthSummary(summary)
            await load()
            return true
        } catch {
            errorMessage = "Couldn't save your Apple Health data. Please try again."
            return false
        }
    }
}
