import XCTest
@testable import Synca

final class APIClientTests: XCTestCase {
    private var session: URLSession!
    private var keychain: MockKeychainService!
    private var sut: APIClient!

    override func setUp() {
        super.setUp()
        session = MockURLProtocol.makeSession()
        keychain = MockKeychainService()
        sut = APIClient(session: session, baseURL: URL(string: "https://test.synca.app/api/v1")!, keychain: keychain)
    }

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        sut = nil
        keychain = nil
        session = nil
        super.tearDown()
    }

    func test_request_decodesSnakeCaseResponse() async throws {
        keychain.storedSession = StoredSession(accessToken: "token", refreshToken: nil, accountType: .guest)
        let json = """
        {"access_token":"abc123","token_type":"Bearer","expires_in":900,"account_type":"guest"}
        """
        MockURLProtocol.requestHandler = { _ in
            (HTTPURLResponse(url: URL(string: "https://test.synca.app")!, statusCode: 201, httpVersion: nil, headerFields: nil)!, Data(json.utf8))
        }

        let response: GuestAuthResponse = try await sut.request(APIEndpoint(path: "auth/guest", method: .post, requiresAuth: false))

        XCTAssertEqual(response.accessToken, "abc123")
        XCTAssertEqual(response.expiresIn, 900)
        XCTAssertEqual(response.accountType, .guest)
    }

    func test_request_injectsBearerToken_whenAuthRequired() async throws {
        keychain.storedSession = StoredSession(accessToken: "my-token", refreshToken: nil, accountType: .active)
        var capturedAuthHeader: String?
        MockURLProtocol.requestHandler = { request in
            capturedAuthHeader = request.value(forHTTPHeaderField: "Authorization")
            let json = """
            {"user":{"id":1,"email":"a@b.com"},"profile":null,"health_summary":null}
            """
            return (HTTPURLResponse(url: URL(string: "https://test.synca.app")!, statusCode: 200, httpVersion: nil, headerFields: nil)!, Data(json.utf8))
        }

        let _: MeResponse = try await sut.request(APIEndpoint(path: "me", method: .get))

        XCTAssertEqual(capturedAuthHeader, "Bearer my-token")
    }

    func test_request_throwsUnauthorized_whenNoTokenAndAuthRequired() async {
        keychain.storedSession = nil

        do {
            let _: MeResponse = try await sut.request(APIEndpoint(path: "me", method: .get))
            XCTFail("Expected unauthorized error")
        } catch let error as APIClientError {
            XCTAssertEqual(error, .unauthorized)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_request_on401_clearsKeychainAndPostsNotification() async {
        keychain.storedSession = StoredSession(accessToken: "stale-token", refreshToken: nil, accountType: .active)
        MockURLProtocol.requestHandler = { _ in
            let json = """
            {"error":{"code":"invalid_token","message":"Token is invalid or expired"}}
            """
            return (HTTPURLResponse(url: URL(string: "https://test.synca.app")!, statusCode: 401, httpVersion: nil, headerFields: nil)!, Data(json.utf8))
        }

        let expectation = expectation(forNotification: APIClient.unauthorizedNotification, object: nil)

        do {
            let _: MeResponse = try await sut.request(APIEndpoint(path: "me", method: .get))
            XCTFail("Expected unauthorized error")
        } catch {
            // expected
        }

        await fulfillment(of: [expectation], timeout: 1)
        XCTAssertEqual(keychain.clearCallCount, 1)
        XCTAssertNil(keychain.loadSession())
    }

    func test_request_decodesServerErrorEnvelope() async {
        keychain.storedSession = StoredSession(accessToken: "token", refreshToken: nil, accountType: .guest)
        MockURLProtocol.requestHandler = { _ in
            let json = """
            {"error":{"code":"validation_failed","message":"Email has already been taken","field":"email"}}
            """
            return (HTTPURLResponse(url: URL(string: "https://test.synca.app")!, statusCode: 422, httpVersion: nil, headerFields: nil)!, Data(json.utf8))
        }

        do {
            let _: MeResponse = try await sut.request(APIEndpoint(path: "me", method: .get))
            XCTFail("Expected server error")
        } catch let error as APIClientError {
            guard case .server(let code, let message, let field, let statusCode) = error else {
                return XCTFail("Expected .server case, got \(error)")
            }
            XCTAssertEqual(code, "validation_failed")
            XCTAssertEqual(message, "Email has already been taken")
            XCTAssertEqual(field, "email")
            XCTAssertEqual(statusCode, 422)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_requestBody_encodesToSnakeCase() async throws {
        keychain.storedSession = StoredSession(accessToken: "token", refreshToken: nil, accountType: .guest)
        var capturedBody: Data?
        MockURLProtocol.requestHandler = { request in
            capturedBody = request.httpBodyDataForTesting
            let json = """
            {"sparks":[]}
            """
            return (HTTPURLResponse(url: URL(string: "https://test.synca.app")!, statusCode: 200, httpVersion: nil, headerFields: nil)!, Data(json.utf8))
        }

        struct Body: Encodable { let spark: Inner }
        struct Inner: Encodable { let sessionCode: String }
        let endpoint = APIEndpoint(path: "sparks/join", method: .post, body: Body(spark: Inner(sessionCode: "834920")))
        let _: SparkListResponse = try await sut.request(endpoint)

        let bodyString = capturedBody.flatMap { String(data: $0, encoding: .utf8) }
        XCTAssertEqual(bodyString, "{\"spark\":{\"session_code\":\"834920\"}}")
    }
}

private extension URLRequest {
    /// `URLSession` sometimes moves a small in-memory body from `httpBody` to
    /// `httpBodyStream` before handing the request to a custom `URLProtocol` —
    /// read whichever one is actually populated.
    var httpBodyDataForTesting: Data? {
        if let httpBody { return httpBody }
        guard let stream = httpBodyStream else { return nil }
        stream.open()
        defer { stream.close() }
        var data = Data()
        let bufferSize = 4096
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        while stream.hasBytesAvailable {
            let bytesRead = stream.read(&buffer, maxLength: bufferSize)
            if bytesRead <= 0 { break }
            data.append(buffer, count: bytesRead)
        }
        return data
    }
}
