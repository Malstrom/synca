import XCTest
@testable import Synca

@MainActor
final class AuthViewModelTests: XCTestCase {
    private var apiClient: MockAPIClient!
    private var keychain: MockKeychainService!
    private var sut: AuthViewModel!

    override func setUp() {
        super.setUp()
        apiClient = MockAPIClient()
        keychain = MockKeychainService()
        sut = AuthViewModel(apiClient: apiClient, keychain: keychain)
    }

    override func tearDown() {
        sut = nil
        keychain = nil
        apiClient = nil
        super.tearDown()
    }

    // MARK: - saveResults (claim email)

    func test_saveResults_withBlankEmail_failsWithoutCallingAPI() async {
        sut.email = "   "

        let succeeded = await sut.saveResults()

        XCTAssertFalse(succeeded)
        XCTAssertEqual(sut.errorMessage, "Enter an email to save your results.")
        XCTAssertTrue(apiClient.requestedPaths.isEmpty)
    }

    func test_saveResults_onSuccess_returnsTrue() async {
        sut.email = "guest@example.com"
        apiClient.responses["auth/guest/claim_email"] = .success(User(id: 1, email: "guest@example.com", phone: nil, authProvider: "email"))

        let succeeded = await sut.saveResults()

        XCTAssertTrue(succeeded)
        XCTAssertNil(sut.errorMessage)
    }

    func test_saveResults_onServerFailure_setsErrorMessage() async {
        sut.email = "guest@example.com"
        apiClient.responses["auth/guest/claim_email"] = .failure(
            APIClientError.server(code: "validation_failed", message: "Email has already been taken", field: "email", statusCode: 422)
        )

        let succeeded = await sut.saveResults()

        XCTAssertFalse(succeeded)
        XCTAssertEqual(sut.errorMessage, "Email has already been taken")
    }

    // MARK: - activate

    func test_activate_withBlankDisplayName_failsWithoutCallingAPI() async {
        sut.displayName = ""

        let succeeded = await sut.activate()

        XCTAssertFalse(succeeded)
        XCTAssertTrue(apiClient.requestedPaths.isEmpty)
    }

    func test_activate_onSuccess_persistsActiveSessionToKeychain() async {
        sut.displayName = "Alex"
        apiClient.responses["auth/activate"] = .success(
            AuthResponse(accessToken: "permanent-access", refreshToken: "permanent-refresh", user: User(id: 1, email: "a@b.com", phone: nil, authProvider: "email"))
        )

        let succeeded = await sut.activate()

        XCTAssertTrue(succeeded)
        XCTAssertEqual(keychain.storedSession?.accessToken, "permanent-access")
        XCTAssertEqual(keychain.storedSession?.refreshToken, "permanent-refresh")
        XCTAssertEqual(keychain.storedSession?.accountType, .active)
    }

    func test_activate_onFailure_doesNotTouchKeychain() async {
        sut.displayName = "Alex"
        apiClient.responses["auth/activate"] = .failure(APIClientError.unauthorized)

        let succeeded = await sut.activate()

        XCTAssertFalse(succeeded)
        XCTAssertEqual(keychain.saveCallCount, 0)
    }
}
