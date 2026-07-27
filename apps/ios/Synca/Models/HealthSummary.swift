import Foundation

enum Chronotype: String, Codable {
    case earlyBird = "early_bird"
    case intermediate
    case nightOwl = "night_owl"
}

enum ActivityLevel: String, Codable {
    case low, medium, high
}

/// Aggregated, on-device-computed health metrics. Raw HealthKit samples never
/// appear here or leave the device — see docs/conventions/ios.md § HealthKit Integration.
///
/// `effectiveFrom`/`sleepStartLocal`/etc. are short date/time strings ("2026-07-27",
/// "23:30"), not full timestamps, so they're modeled as `String` rather than `Date` —
/// avoids a custom date-decoding strategy for a handful of fields.
struct HealthSummary: Codable, Equatable {
    var chronotype: Chronotype?
    var source: String?
    var effectiveFrom: String
    var effectiveTo: String?
    var sleepStartLocal: String?
    var sleepEndLocal: String?
    var avgSleepDurationMinutes: Int?
    var routineStabilityIndex: Double?
    var activityLevel: ActivityLevel?
    var peakEnergyStartLocal: String?
    var peakEnergyEndLocal: String?
    var recoveryScore: String?
}

/// `PUT /me/health_summary` request body wraps under `health_summary:`.
struct HealthSummaryUpdateRequest: Codable {
    let healthSummary: HealthSummary
}

/// `PUT /me/health_summary` response wraps under `health_summary:`.
struct HealthSummaryResponse: Codable {
    let healthSummary: HealthSummary
}

struct SelfReportAlignment: Codable, Equatable {
    let aligned: Bool?
    let note: String?
}

/// `GET /signals/me/summary` — human-readable, derived at request time, no
/// additional DB row (see docs/features/signals-v1.md § User-facing summary).
struct SignalsSummary: Codable, Equatable {
    let chronotypeLabel: String
    let peakEnergyWindow: String?
    let routineStabilityTier: String?
    let activityTier: String?
    let avgSleepDurationMinutes: Int?
    let selfReportAlignment: SelfReportAlignment
}

struct SignalsSummaryResponse: Codable {
    let summary: SignalsSummary
}
