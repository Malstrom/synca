import Foundation
@testable import Synca

/// Scriptable `APIClientProtocol` double, keyed by endpoint path — lets
/// ViewModel tests avoid any real networking. `responses[path]` is consumed on
/// every matching call (doesn't distinguish HTTP method); that's precise enough
/// for the paths exercised in these tests.
final class MockAPIClient: APIClientProtocol {
    enum MockError: Error { case unhandledPath(String), typeMismatch }

    /// Fixed response for a path — read on every matching call.
    var responses: [String: Result<Any, Error>] = [:]
    /// Optional FIFO sequence for a path (e.g. "not completed yet" then
    /// "completed" for polling tests) — takes priority over `responses` while
    /// non-empty, so a test doesn't have to race a background poll loop against
    /// a timed mutation.
    var responseSequences: [String: [Result<Any, Error>]] = [:]
    private(set) var requestedPaths: [String] = []

    func request<Response>(_ endpoint: APIEndpoint) async throws -> Response where Response: Decodable {
        requestedPaths.append(endpoint.path)

        let result: Result<Any, Error>
        if var sequence = responseSequences[endpoint.path], !sequence.isEmpty {
            result = sequence.removeFirst()
            responseSequences[endpoint.path] = sequence
        } else if let fixed = responses[endpoint.path] {
            result = fixed
        } else {
            throw MockError.unhandledPath(endpoint.path)
        }

        switch result {
        case .success(let value):
            guard let typed = value as? Response else { throw MockError.typeMismatch }
            return typed
        case .failure(let error):
            throw error
        }
    }

    func requestNoContent(_ endpoint: APIEndpoint) async throws {
        requestedPaths.append(endpoint.path)
        if case .failure(let error) = responses[endpoint.path] {
            throw error
        }
    }
}
