import Foundation

enum SparkRewardType: String, Codable {
    case premiumWeek = "premium_week"
    case matchCredit = "match_credit"
    case boost
}

enum SparkRewardStatus: String, Codable {
    case pending, redeemed, expired
}

/// `GET /spark_rewards` — full reward record (`id`/`valid_until` included, unlike
/// the summary embedded in `SparkResult`).
struct SparkReward: Codable, Equatable, Identifiable {
    let id: Int
    let rewardType: SparkRewardType
    let status: SparkRewardStatus
    let validUntil: Date?
}

struct SparkRewardListResponse: Codable {
    let rewards: [SparkReward]
}
