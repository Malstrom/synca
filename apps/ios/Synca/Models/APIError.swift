import Foundation

struct APIErrorDetail: Codable {
    let code: String
    let message: String
    let field: String?
}

struct APIErrorEnvelope: Codable {
    let error: APIErrorDetail
}

enum APIClientError: Error, LocalizedError, Equatable {
    case server(code: String, message: String, field: String?, statusCode: Int)
    case unauthorized
    case decoding(String)
    case network(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .server(_, let message, _, _):
            return message
        case .unauthorized:
            return "Your session expired. Please start again."
        case .decoding:
            return "Something went wrong reading the server's response."
        case .network:
            return "Check your connection and try again."
        case .invalidResponse:
            return "Unexpected response from the server."
        }
    }

    /// The `error.code` string from the API, when this came from a server response.
    /// ViewModels use this to branch on specific failures (e.g. `email_already_active`).
    var serverCode: String? {
        if case .server(let code, _, _, _) = self { return code }
        return nil
    }
}
