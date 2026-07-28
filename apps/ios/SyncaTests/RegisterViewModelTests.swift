import XCTest
@testable import Synca

@MainActor
final class RegisterViewModelTests: XCTestCase {
    private var apiClient: MockAPIClient!
    private var keychain: MockKeychainService!
    private var sut: RegisterViewModel!

    override func setUp() {
        super.setUp()
        apiClient = MockAPIClient()
        keychain = MockKeychainService()
        sut = RegisterViewModel(apiClient: apiClient, keychain: keychain)
    }

    override func tearDown() {
        sut = nil
        keychain = nil
        apiClient = nil
        super.tearDown()
    }

    func test_register_withBlankEmail_failsWithoutCallingAPI() async {
        sut.email = ""
        sut.password = "password123"
        sut.displayName = "Alex"

        let succeeded = await sut.register()

        XCTAssertFalse(succeeded)
        XCTAssertTrue(apiClient.requestedPaths.isEmpty)
    }

    func test_register_withTooShortPassword_failsWithoutCallingAPI() async {
        sut.email = "alex@example.com"
        sut.password = "short"
        sut.displayName = "Alex"

        let succeeded = await sut.register()

        XCTAssertFalse(succeeded)
        XCTAssertTrue(apiClient.requestedPaths.isEmpty)
    }

    func test_register_withBlankDisplayName_failsWithoutCallingAPI() async {
        sut.email = "alex@example.com"
        sut.password = "password123"
        sut.displayName = ""

        let succeeded = await sut.register()

        XCTAssertFalse(succeeded)
        XCTAssertTrue(apiClient.requestedPaths.isEmpty)
    }

    func test_register_onSuccess_persistsActiveSessionAndUpdatesProfile() async {
        sut.email = "alex@example.com"
        sut.password = "password123"
        sut.displayName = "Alex"
        apiClient.responses["auth/register"] = .success(
            AuthResponse(accessToken: "access-token", refreshToken: "refresh-token", user: User(id: 1, email: "alex@example.com", phone: nil, authProvider: "email"))
        )
        apiClient.responses["me/profile"] = .success(
            ProfileResponse(profile: Profile(displayName: "Alex", birthDate: nil, gender: nil, bio: nil, city: nil, photoUrlMain: nil, photoUrls: nil, trustScore: nil, sparkVerified: nil))
        )

        let succeeded = await sut.register()

        XCTAssertTrue(succeeded)
        XCTAssertEqual(keychain.storedSession?.accessToken, "access-token")
        XCTAssertEqual(keychain.storedSession?.refreshToken, "refresh-token")
        XCTAssertEqual(keychain.storedSession?.accountType, .active)
        XCTAssertTrue(apiClient.requestedPaths.contains("me/profile"))
        XCTAssertNil(sut.errorMessage)
    }

    func test_register_onSuccess_evenIfProfileUpdateFails_stillSucceeds() async {
        sut.email = "alex@example.com"
        sut.password = "password123"
        sut.displayName = "Alex"
        apiClient.responses["auth/register"] = .success(
            AuthResponse(accessToken: "access-token", refreshToken: "refresh-token", user: User(id: 1, email: "alex@example.com", phone: nil, authProvider: "email"))
        )
        apiClient.responses["me/profile"] = .failure(APIClientError.network("offline"))

        let succeeded = await sut.register()

        XCTAssertTrue(succeeded)
        XCTAssertEqual(keychain.storedSession?.accountType, .active)
    }

    func test_register_onEmailTaken_setsErrorMessageAndDoesNotTouchKeychain() async {
        sut.email = "alex@example.com"
        sut.password = "password123"
        sut.displayName = "Alex"
        apiClient.responses["auth/register"] = .failure(
            APIClientError.server(code: "email_taken", message: "Email has already been taken", field: "email", statusCode: 422)
        )

        let succeeded = await sut.register()

        XCTAssertFalse(succeeded)
        XCTAssertEqual(sut.errorMessage, "Email has already been taken")
        XCTAssertEqual(keychain.saveCallCount, 0)
    }
}
