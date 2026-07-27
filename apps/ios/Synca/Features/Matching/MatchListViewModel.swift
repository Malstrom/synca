import Foundation
import Observation

/// Backs `MatchListView`. `GET /matches` is implemented, but this feature is
/// "Concept — not yet built" in the approved design (row 5, marked with a
/// dashed outline) and is intentionally not reachable from `AppRouter` or the
/// tab bar — see docs/design/ui-system.md § Navigation Map.
@MainActor
@Observable
final class MatchListViewModel {
    private let apiClient: APIClientProtocol

    var isLoading = false
    var errorMessage: String?
    private(set) var matches: [Match] = []

    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            matches = try await apiClient.listMatches()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Couldn't load matches."
        }
    }
}
