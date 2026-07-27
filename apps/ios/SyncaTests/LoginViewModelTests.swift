import XCTest
@testable import Synca

@MainActor
final class LoginViewModelTests: XCTestCase {
    private var apiClient: MockAPIClient!
    private var keychain: MockKeychainService!
    private var sut: LoginViewModel!

    override func setUp() {
        super.setUp()
        apiClient = MockAPIClient()
        keychain = MockKeychainService()
        sut = LoginViewModel(apiClient: apiClient, keychain: keychain)
    }

    override func tearDown() {
        sut = nil
        keychain = nil
        apiClient = nil
        super.tearDown()
    }

    func test_login_withBlankFields_failsWithoutCallingAPI() async {
        sut.email = ""
        sut.password = ""

        let succeeded = await sut.login()

        XCTAssertFalse(succeeded)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(apiClient.requestedPaths.isEmpty)
    }

    func test_login_onSuccess_persistsActiveSessionToKeychain() async {
        sut.email = "alex@example.com"
        sut.password = "password123"
        apiClient.responses["auth/login"] = .success(
            AuthResponse(accessToken: "access-token", refreshToken: "refresh-token", user: User(id: 1, email: "alex@example.com", phone: nil, authProvider: "email"))
        )

        let succeeded = await sut.login()

        XCTAssertTrue(succeeded)
        XCTAssertEqual(keychain.storedSession?.accessToken, "access-token")
        XCTAssertEqual(keychain.storedSession?.refreshToken, "refresh-token")
        XCTAssertEqual(keychain.storedSession?.accountType, .active)
        XCTAssertNil(sut.errorMessage)
    }

    func test_login_onInvalidCredentials_setsErrorMessageAndDoesNotTouchKeychain() async {
        sut.email = "alex@example.com"
        sut.password = "wrong-password"
        apiClient.responses["auth/login"] = .failure(
            APIClientError.server(code: "invalid_credentials", message: "Email or password is incorrect", field: nil, statusCode: 401)
        )

        let succeeded = await sut.login()

        XCTAssertFalse(succeeded)
        XCTAssertEqual(sut.errorMessage, "Email or password is incorrect")
        XCTAssertEqual(keychain.saveCallCount, 0)
    }
}
