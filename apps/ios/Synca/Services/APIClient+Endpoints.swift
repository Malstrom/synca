import Foundation

// MARK: - Request body types
//
// These can't be declared as local `struct`s inside the methods below: Swift
// disallows nested type declarations inside a protocol extension's methods
// (they're implicitly generic over `Self`) — "Type '...' cannot be nested in
// generic function '...'". Hence top-level, file-private types instead.

private struct GuestSessionAuthPayload: Encodable { let email: String? }
private struct GuestSessionRequestBody: Encodable { let auth: GuestSessionAuthPayload }

private struct ClaimEmailAuthPayload: Encodable { let email: String }
private struct ClaimEmailRequestBody: Encodable { let auth: ClaimEmailAuthPayload }

private struct ActivateProfilePayload: Encodable { let displayName: String }
private struct ActivateRequestBody: Encodable { let profile: ActivateProfilePayload }

/// Typed calls for every endpoint the app needs, on top of the generic
/// `APIClient.request(_:)`. Keeps path strings and request/response envelopes out of
/// ViewModels. Mirrors docs/api/openapi.yaml exactly — including the endpoints
/// marked "needed — not yet implemented" there, which will 404/422 against a real
/// server today. See docs/product/decisions.md#spark-guest-anonymous-identity.
extension APIClientProtocol {

    // MARK: Auth

    /// `POST /auth/guest`. Passing `email: nil` requests a fully anonymous guest —
    /// this is the "needed" half described in openapi.yaml; today's
    /// `GuestRegistrationContract` rejects an empty body.
    func createGuestSession(email: String? = nil) async throws -> GuestAuthResponse {
        let endpoint = APIEndpoint(
            path: "auth/guest",
            method: .post,
            body: GuestSessionRequestBody(auth: GuestSessionAuthPayload(email: email)),
            requiresAuth: false
        )
        return try await request(endpoint)
    }

    /// `POST /auth/guest/claim_email` — "Save your results" screen.
    func claimEmail(_ email: String) async throws -> User {
        let endpoint = APIEndpoint(
            path: "auth/guest/claim_email",
            method: .post,
            body: ClaimEmailRequestBody(auth: ClaimEmailAuthPayload(email: email))
        )
        return try await request(endpoint)
    }

    /// `POST /auth/activate` — "Almost there" screen.
    func activate(displayName: String) async throws -> AuthResponse {
        let endpoint = APIEndpoint(
            path: "auth/activate",
            method: .post,
            body: ActivateRequestBody(profile: ActivateProfilePayload(displayName: displayName))
        )
        return try await request(endpoint)
    }

    // MARK: Profile

    func me() async throws -> MeResponse {
        try await request(APIEndpoint(path: "me", method: .get))
    }

    @discardableResult
    func updateProfile(_ profile: Profile) async throws -> Profile {
        let endpoint = APIEndpoint(path: "me/profile", method: .put, body: ProfileUpdateRequest(profile: profile))
        let response: ProfileResponse = try await request(endpoint)
        return response.profile
    }

    // MARK: Health

    @discardableResult
    func updateHealthSummary(_ summary: HealthSummary) async throws -> HealthSummary {
        let endpoint = APIEndpoint(path: "me/health_summary", method: .put, body: HealthSummaryUpdateRequest(healthSummary: summary))
        let response: HealthSummaryResponse = try await request(endpoint)
        return response.healthSummary
    }

    func signalsSummary() async throws -> SignalsSummary {
        let response: SignalsSummaryResponse = try await request(APIEndpoint(path: "signals/me/summary", method: .get))
        return response.summary
    }

    // MARK: Preferences

    func upsertPreferences(_ preferences: PreferenceProfile) async throws -> PreferenceProfile {
        let endpoint = APIEndpoint(path: "signals/preferences", method: .patch, body: PreferenceProfileUpdateRequest(preferences: preferences))
        return try await request(endpoint)
    }

    // MARK: Spark

    func createSpark(lat: Double? = nil, lng: Double? = nil) async throws -> SparkSession {
        let endpoint = APIEndpoint(path: "sparks", method: .post, body: CreateSparkRequest(spark: CreateSparkLocation(lat: lat, lng: lng)))
        return try await request(endpoint)
    }

    /// `POST /sparks/join` — what the Scan QR / manual code entry screen actually
    /// calls (no Spark id known client-side). Needed, not yet implemented — see
    /// docs/product/decisions.md#spark-join-by-code-without-id.
    func joinSpark(sessionCode: String? = nil, qrToken: String? = nil) async throws -> SparkSession {
        let endpoint = APIEndpoint(
            path: "sparks/join",
            method: .post,
            body: JoinSparkRequest(spark: JoinSparkPayload(sessionCode: sessionCode, qrToken: qrToken))
        )
        return try await request(endpoint)
    }

    func submitSparkAnswers(sparkId: Int, answers: [Int]) async throws -> SparkStatus {
        let endpoint = APIEndpoint(
            path: "sparks/\(sparkId)/submit_answers",
            method: .post,
            body: SubmitSparkAnswersRequest(spark: SubmitSparkAnswersPayload(answers: answers))
        )
        let response: SubmitSparkAnswersResponse = try await request(endpoint)
        return response.status
    }

    func sparkResult(sparkId: Int) async throws -> SparkResult {
        try await request(APIEndpoint(path: "sparks/\(sparkId)/result", method: .get))
    }

    /// `GET /sparks` — needed, not yet implemented server-side (see docs/api/openapi.yaml).
    func listSparks() async throws -> [SparkHistoryEntry] {
        let response: SparkListResponse = try await request(APIEndpoint(path: "sparks", method: .get))
        return response.sparks
    }

    func listSparkRewards() async throws -> [SparkReward] {
        let response: SparkRewardListResponse = try await request(APIEndpoint(path: "spark_rewards", method: .get))
        return response.rewards
    }

    // MARK: Matching (Features/Matching — concept only, see docs/design/ui-system.md)

    func listMatches() async throws -> [Match] {
        let response: MatchListResponse = try await request(APIEndpoint(path: "matches", method: .get))
        return response.matches
    }
}
