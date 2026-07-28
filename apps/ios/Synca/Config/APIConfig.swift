import Foundation

/// Single source of truth for which backend the app talks to.
///
/// To point the app at a different backend (e.g. once a domain + HTTPS are
/// live), change the three constants below — and update the matching
/// NSAppTransportSecurity exception in Info.plist to match the new host.
/// Nothing else in the app needs to change.
enum APIConfig {
    static let scheme = "http"           // "https" once TLS is available
    static let host = "72.56.97.181"     // terminus VPS static IP — no domain yet
    static let basePath = "/api/v1"

    static var baseURL: URL {
        URL(string: "\(scheme)://\(host)\(basePath)")!
    }
}
