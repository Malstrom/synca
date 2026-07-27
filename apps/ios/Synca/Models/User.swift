import Foundation

struct User: Codable, Equatable, Identifiable {
    let id: Int
    let email: String?
    let phone: String?
    let authProvider: String?
}

enum AccountType: String, Codable {
    case guest
    case active
}
