import XCTest
@testable import Synca

final class KeychainServiceTests: XCTestCase {
    private var keychain: KeychainService!

    override func setUp() {
        super.setUp()
        keychain = KeychainService()
        keychain.clear()
    }

    override func tearDown() {
        keychain.clear()
        keychain = nil
        super.tearDown()
    }

    func test_loadSession_returnsNil_whenNothingStored() {
        XCTAssertNil(keychain.loadSession())
    }

    func test_save_thenLoad_roundTrips() throws {
        let session = StoredSession(accessToken: "access-123", refreshToken: "refresh-456", accountType: .active)

        try keychain.save(session)

        XCTAssertEqual(keychain.loadSession(), session)
    }

    func test_save_overwritesPreviousSession() throws {
        try keychain.save(StoredSession(accessToken: "first", refreshToken: nil, accountType: .guest))
        try keychain.save(StoredSession(accessToken: "second", refreshToken: "refresh", accountType: .active))

        let loaded = keychain.loadSession()

        XCTAssertEqual(loaded?.accessToken, "second")
        XCTAssertEqual(loaded?.accountType, .active)
    }

    func test_clear_removesStoredSession() throws {
        try keychain.save(StoredSession(accessToken: "token", refreshToken: nil, accountType: .guest))

        keychain.clear()

        XCTAssertNil(keychain.loadSession())
    }
}
