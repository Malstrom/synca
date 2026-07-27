import Foundation

struct APIEndpoint {
    enum HTTPMethod: String { case get = "GET", post = "POST", put = "PUT", patch = "PATCH" }

    let path: String
    let method: HTTPMethod
    let body: Data?
    let requiresAuth: Bool

    init<Body: Encodable>(path: String, method: HTTPMethod, body: Body, requiresAuth: Bool = true) {
        self.path = path
        self.method = method
        self.body = try? JSONEncoder.synca.encode(body)
        self.requiresAuth = requiresAuth
    }

    init(path: String, method: HTTPMethod, requiresAuth: Bool = true) {
        self.path = path
        self.method = method
        self.body = nil
        self.requiresAuth = requiresAuth
    }
}

protocol APIClientProtocol {
    func request<Response: Decodable>(_ endpoint: APIEndpoint) async throws -> Response
    func requestNoContent(_ endpoint: APIEndpoint) async throws
}

/// `URLSession` wrapper: injects `Authorization: Bearer <token>`, decodes with
/// `.convertFromSnakeCase`, clears the Keychain and broadcasts `unauthorizedNotification`
/// on 401 — see docs/conventions/ios.md § Networking.
final class APIClient: APIClientProtocol {
    static let shared = APIClient()
    static let unauthorizedNotification = Notification.Name("APIClient.unauthorized")

    static var defaultBaseURL: URL {
        #if DEBUG
        return URL(string: "http://localhost:3000/api/v1")!
        #else
        return URL(string: "https://api.synca.app/api/v1")!
        #endif
    }

    private let session: URLSession
    private let baseURL: URL
    private let keychain: KeychainServiceProtocol

    init(
        session: URLSession = .shared,
        baseURL: URL = APIClient.defaultBaseURL,
        keychain: KeychainServiceProtocol = KeychainService.shared
    ) {
        self.session = session
        self.baseURL = baseURL
        self.keychain = keychain
    }

    func request<Response: Decodable>(_ endpoint: APIEndpoint) async throws -> Response {
        let data = try await rawResponse(endpoint)
        do {
            return try JSONDecoder.synca.decode(Response.self, from: data)
        } catch {
            throw APIClientError.decoding(String(describing: error))
        }
    }

    func requestNoContent(_ endpoint: APIEndpoint) async throws {
        _ = try await rawResponse(endpoint)
    }

    @discardableResult
    private func rawResponse(_ endpoint: APIEndpoint) async throws -> Data {
        var urlRequest = URLRequest(url: baseURL.appendingPathComponent(endpoint.path))
        urlRequest.httpMethod = endpoint.method.rawValue
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = endpoint.body

        if endpoint.requiresAuth {
            guard let token = keychain.loadSession()?.accessToken else {
                throw APIClientError.unauthorized
            }
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            throw APIClientError.network(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200..<300:
            return data
        case 401:
            keychain.clear()
            NotificationCenter.default.post(name: APIClient.unauthorizedNotification, object: nil)
            throw APIClientError.unauthorized
        default:
            if let envelope = try? JSONDecoder.synca.decode(APIErrorEnvelope.self, from: data) {
                throw APIClientError.server(
                    code: envelope.error.code,
                    message: envelope.error.message,
                    field: envelope.error.field,
                    statusCode: httpResponse.statusCode
                )
            }
            throw APIClientError.invalidResponse
        }
    }
}
