import Foundation

/// `SparkResultService` returns `{ type:, status: }` per reward, not the full
/// `SparkReward` shape from `GET /spark_rewards` — modeled separately on purpose.
struct SparkResultReward: Codable, Equatable {
    let type: String
    let status: String
}

/// `GET /sparks/:id/result`. `dimensions` is empty when either participant has no
/// health summary yet (score falls back to declared preferences only —
/// docs/features/spark-v1.md § UC-05). Per docs/conventions/ios.md, the raw score
/// is never shown standalone in the UI — always pair it with the plain-language
/// explanation computed client-side from `compatibilityScore`.
struct SparkResult: Codable, Equatable {
    let compatibilityScore: Double
    let dimensions: [String: Double]
    let rewards: [SparkResultReward]

    /// Needed — not yet implemented server-side. Framed as "you"/"partner"
    /// (not initiator/partner) because `SparkSerializer` exposes neither id, so
    /// the client can't resolve which side it is itself — the server would
    /// return these already resolved to the requester's perspective, same as
    /// `compatibilityScore`. See docs/product/decisions.md#spark-heart-rate-during-session.
    var yourAvgHeartRate: Int? = nil
    var partnerAvgHeartRate: Int? = nil
}
