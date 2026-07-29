import Foundation

enum SparkStatus: String, Codable {
    case pending, active, completed, expired
}

/// `SparkSerializer` on the backend only exposes these fields — no
/// `initiator_id`/`partner_id`/`completed_at`/`created_at` despite earlier docs
/// implying otherwise (see docs/api/openapi.yaml § SparkSession).
///
/// `Hashable` because `AppDestination.sparkFlow` carries one (the initiator
/// resumes into the questionnaire with an already-joined session) and
/// `AppDestination` has to be `Hashable` for `NavigationPath`.
struct SparkSession: Codable, Equatable, Hashable, Identifiable {
    let id: Int
    let sessionCode: String?
    let qrToken: String?
    let status: SparkStatus
    let startedAt: Date?
    let locationLat: Double?
    let locationLng: Double?
}

struct CreateSparkLocation: Codable {
    let lat: Double?
    let lng: Double?
}

struct CreateSparkRequest: Codable {
    let spark: CreateSparkLocation?
}

struct JoinSparkPayload: Codable {
    let sessionCode: String?
    let qrToken: String?
}

struct JoinSparkRequest: Codable {
    let spark: JoinSparkPayload
}

struct SubmitSparkAnswersPayload: Codable {
    let answers: [Int]
}

struct SubmitSparkAnswersRequest: Codable {
    let spark: SubmitSparkAnswersPayload
}

struct SubmitSparkAnswersResponse: Codable {
    let status: SparkStatus
}

/// `GET /sparks` row. Deliberately not `SparkSession`: `SparkSerializer` has no
/// `compatibility_score`, which the Dashboard "YOUR SPARKS" list needs — the
/// backend serves this shape via `SparkHistorySerializer`.
struct SparkHistoryEntry: Codable, Equatable, Identifiable {
    let id: Int
    let status: SparkStatus
    let compatibilityScore: Double?
    let startedAt: Date?
    let completedAt: Date?
}

struct SparkListResponse: Codable {
    let sparks: [SparkHistoryEntry]
}
