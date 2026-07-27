import Foundation

/// Row 5 of the design ("Matches & compatibility detail") is labelled
/// "Concept — not yet built" and is intentionally not wired into `AppRouter` or the
/// tab bar — see docs/design/ui-system.md § Navigation Map. These models exist so
/// `Features/Matching/` compiles and can be previewed, matching the design's own
/// treatment of these two screens as dashed-outline concepts.
struct MatchParticipantProfile: Codable, Equatable {
    let displayName: String?
}

struct MatchParticipant: Codable, Equatable {
    let userId: Int
    let role: String
    let profile: MatchParticipantProfile?
}

struct Match: Codable, Equatable, Identifiable {
    let id: Int
    let status: String
    let compatibilityScore: Double
    let acceptedAt: Date?
    let participants: [MatchParticipant]
}

struct MatchListResponse: Codable {
    let matches: [Match]
}
