import Foundation
import Security

protocol KeychainServiceProtocol {
    func save(_ session: StoredSession) throws
    func loadSession() -> StoredSession?
    func clear()
}

enum KeychainError: Error {
    case unableToSave(OSStatus)
}

/// JWT (and account type) read/write via Keychain. This is the ONLY place that
/// touches `SecItemAdd`/`SecItemCopyMatching` for auth data — per
/// docs/conventions/ios.md, tokens must never be stored in `UserDefaults` or any
/// other plain-text storage.
final class KeychainService: KeychainServiceProtocol {
    static let shared = KeychainService()

    private let service = "app.synca.auth"
    private let account = "session"

    init() {}

    func save(_ session: StoredSession) throws {
        let data = try JSONEncoder().encode(session)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)

        var attributes = query
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unableToSave(status)
        }
    }

    func loadSession() -> StoredSession? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return try? JSONDecoder().decode(StoredSession.self, from: data)
    }

    func clear() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
