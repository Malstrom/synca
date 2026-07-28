import Foundation
import Observation

/// Backs `MatchDetailView` — concept only, see `MatchListViewModel`.
///
/// `GET /matches` doesn't expose a per-dimension breakdown, only the overall
/// `compatibility_score` — so the dimension bars come from `POST
/// /matches/simulate` (real, implemented) using the two participants' user ids
/// when both are known. If that fails, only the overall score is shown; no
/// dimension values are fabricated client-side.
@MainActor
@Observable
final class MatchDetailViewModel {
    private let apiClient: APIClientProtocol

    var isLoading = false
    var errorMessage: String?
    private(set) var match: Match?
    private(set) var dimensions: [(label: String, value: Double)] = []

    init(apiClient: APIClientProtocol = DemoMode.apiClient) {
        self.apiClient = apiClient
    }

    func load(matchId: Int) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let meTask = apiClient.me()
            async let matchesTask = apiClient.listMatches()
            let (me, matches) = try await (meTask, matchesTask)

            guard let match = matches.first(where: { $0.id == matchId }) else {
                errorMessage = "Match not found."
                return
            }
            self.match = match

            if let otherUserId = match.participants.first(where: { $0.userId != me.user.id })?.userId {
                await loadDimensions(currentUserId: me.user.id, otherUserId: otherUserId)
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Couldn't load this match."
        }
    }

    private func loadDimensions(currentUserId: Int, otherUserId: Int) async {
        struct SimulateRequestBody: Encodable { let userId: Int; let otherUserId: Int }
        guard let result: CompatibilityResult = try? await apiClient.request(
            APIEndpoint(path: "matches/simulate", method: .post, body: SimulateRequestBody(userId: currentUserId, otherUserId: otherUserId))
        ) else { return }

        // `dimensions` is decoded through JSONDecoder.synca's .convertFromSnakeCase,
        // which also rewrites dictionary keys ("sleep_rhythm" -> "sleepRhythm").
        dimensions = [
            ("Sleep alignment", result.dimensions["sleepRhythm"]),
            ("Activity level", result.dimensions["energyOverlap"]),
            ("Rhythm stability", result.dimensions["lifestyle"])
        ].compactMap { label, value in value.map { (label, $0) } }
    }
}

/// `POST /matches/simulate` response — local to this concept feature, not
/// reused elsewhere.
struct CompatibilityResult: Codable {
    let compatibilityScore: Double
    let dimensions: [String: Double]
}
