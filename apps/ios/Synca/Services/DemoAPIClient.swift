import Foundation

/// Manual fallback for testing the SwiftUI flow without a reachable
/// backend. Off by default — the app talks to the real `APIClient` server.
/// Flip `isEnabled` to `true` locally if the backend becomes unreachable
/// again; it's still hard-pinned to `false` in Release builds so this can
/// never accidentally ship on. Nothing about `APIClient`/`APIClient+Endpoints.swift`
/// changes either way.
enum DemoMode {
    static let isEnabled: Bool = {
        #if DEBUG
        return false
        #else
        return false
        #endif
    }()

    static var apiClient: APIClientProtocol {
        isEnabled ? DemoAPIClient.shared : APIClient.shared
    }
}

/// Every response is canned and plausible; nothing ever touches the network.
/// Implements the same two `APIClientProtocol` requirements `APIClient` does,
/// keyed by `endpoint.path` — same technique as `SyncaTests/Mocks/MockAPIClient.swift`,
/// just with fixed demo data instead of test-scripted responses. Holds no
/// real state beyond a fixed Spark id, so join → submit_answers → result all
/// address the same "session" without needing a real second participant.
final class DemoAPIClient: APIClientProtocol {
    static let shared = DemoAPIClient()

    private let sparkId = 1
    private let demoUser = User(id: 1, email: "demo@example.com", phone: nil, authProvider: "email")

    func request<Response>(_ endpoint: APIEndpoint) async throws -> Response where Response: Decodable {
        guard let response = cannedResponse(for: endpoint) as? Response else {
            throw APIClientError.invalidResponse
        }
        return response
    }

    func requestNoContent(_ endpoint: APIEndpoint) async throws {}

    private func cannedResponse(for endpoint: APIEndpoint) -> Any {
        switch endpoint.path {
        case "auth/guest":
            return GuestAuthResponse(accessToken: "demo-guest-token", tokenType: "Bearer", expiresIn: 900, accountType: .guest)

        case "auth/guest/claim_email":
            return demoUser

        case "auth/activate", "auth/login":
            return AuthResponse(accessToken: "demo-active-token", refreshToken: "demo-refresh-token", user: demoUser)

        case "me":
            return MeResponse(
                user: demoUser,
                profile: demoProfile,
                healthSummary: nil
            )

        case "me/profile":
            return ProfileResponse(profile: demoProfile)

        case "me/health_summary":
            return HealthSummaryResponse(healthSummary: HealthSummary(effectiveFrom: "2026-07-27"))

        case "signals/me/summary":
            return SignalsSummaryResponse(summary: SignalsSummary(
                chronotypeLabel: "Night owl",
                peakEnergyWindow: "21:00–23:00",
                routineStabilityTier: "High",
                activityTier: "high",
                avgSleepDurationMinutes: 432,
                selfReportAlignment: SelfReportAlignment(
                    aligned: false,
                    note: "You told us you're a morning person — your data says otherwise. No judgment, just noting it."
                ),
                avgDailySteps: 8400,
                avgRestingHeartRateBpm: 58
            ))

        case "signals/preferences":
            return PreferenceProfile()

        case "sparks":
            // POST (create, GenerateQRView) and GET (list, Dashboard) share this
            // path — disambiguate on the HTTP method.
            if endpoint.method == .get {
                return SparkListResponse(sparks: [
                    SparkHistoryEntry(id: sparkId, status: .completed, compatibilityScore: 84, startedAt: Date(), completedAt: Date())
                ])
            }
            return SparkSession(id: 2, sessionCode: "834920", qrToken: UUID().uuidString, status: .pending, startedAt: nil, locationLat: nil, locationLng: nil)

        case "sparks/join":
            return SparkSession(id: sparkId, sessionCode: "834920", qrToken: UUID().uuidString, status: .active, startedAt: Date(), locationLat: nil, locationLng: nil)

        case "sparks/\(sparkId)/submit_answers":
            // Completed immediately — no real second participant to wait on.
            return SubmitSparkAnswersResponse(status: .completed)

        case "sparks/\(sparkId)/result":
            return SparkResult(
                compatibilityScore: 84,
                dimensions: ["sleepRhythm": 90, "energyOverlap": 85, "lifestyle": 78],
                rewards: [SparkResultReward(type: "premium_week", status: "pending")],
                yourAvgHeartRate: 78,
                partnerAvgHeartRate: 85
            )

        case "spark_rewards":
            return SparkRewardListResponse(rewards: [])

        case "matches":
            return MatchListResponse(matches: [])

        case "matches/simulate":
            return CompatibilityResult(compatibilityScore: 78, dimensions: ["sleepRhythm": 90, "energyOverlap": 71, "lifestyle": 85])

        default:
            return EmptyDemoResponse()
        }
    }

    private var demoProfile: Profile {
        Profile(
            displayName: "Alex",
            birthDate: nil,
            gender: nil,
            bio: nil,
            city: nil,
            photoUrlMain: nil,
            photoUrls: nil,
            trustScore: 78,
            sparkVerified: true
        )
    }
}

private struct EmptyDemoResponse: Decodable {}
