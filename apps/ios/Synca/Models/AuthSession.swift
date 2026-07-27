import Foundation

/// `POST /auth/register`, `/auth/login`, `/auth/activate` all return this shape.
struct AuthResponse: Codable, Equatable {
    let accessToken: String
    let refreshToken: String?
    let user: User?
}

/// `POST /auth/guest` — no refresh_token, no user object (see docs/api/openapi.yaml).
struct GuestAuthResponse: Codable, Equatable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let accountType: AccountType
}

/// What `KeychainService` persists between launches. `refreshToken` is nil for a
/// still-anonymous guest session (see `docs/product/decisions.md#spark-guest-anonymous-identity`).
struct StoredSession: Codable, Equatable {
    let accessToken: String
    let refreshToken: String?
    let accountType: AccountType
}
