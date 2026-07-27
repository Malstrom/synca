import Foundation
@testable import Synca

final class MockKeychainService: KeychainServiceProtocol {
    var storedSession: StoredSession?
    private(set) var saveCallCount = 0
    private(set) var clearCallCount = 0

    func save(_ session: StoredSession) throws {
        saveCallCount += 1
        storedSession = session
    }

    func loadSession() -> StoredSession? { storedSession }

    func clear() {
        clearCallCount += 1
        storedSession = nil
    }
}
