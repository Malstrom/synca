import Foundation

/// Property names intentionally match what `JSONDecoder.KeyDecodingStrategy
/// .convertFromSnakeCase` produces (e.g. `photo_url_main` → `photoUrlMain`, not
/// `photoURLMain`) so no manual `CodingKeys` are needed — see docs/conventions/ios.md.
struct Profile: Codable, Equatable {
    var displayName: String?
    var birthDate: String?
    var gender: String?
    var bio: String?
    var city: String?
    var photoUrlMain: String?
    var photoUrls: [String]?
    var trustScore: Double?
    var sparkVerified: Bool?
}

/// `PUT /me/profile` request body wraps under `profile:`.
struct ProfileUpdateRequest: Codable {
    let profile: Profile
}

/// `PUT /me/profile` response wraps under `profile:`.
struct ProfileResponse: Codable {
    let profile: Profile
}

/// `GET /me` response.
struct MeResponse: Codable {
    let user: User
    let profile: Profile?
    let healthSummary: HealthSummary?
}
