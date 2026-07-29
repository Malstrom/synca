import XCTest
@testable import Synca

/// Session state machine: pending (scanning) → joined (questionnaire) → scored
/// (result) — priority TDD target, see docs/conventions/ios.md § TDD.
@MainActor
final class SparkViewModelTests: XCTestCase {
    private var apiClient: MockAPIClient!
    private var keychain: MockKeychainService!
    private var sut: SparkViewModel!

    private let pendingHealthSummary = HealthSummary(effectiveFrom: "2026-07-27")

    override func setUp() {
        super.setUp()
        apiClient = MockAPIClient()
        keychain = MockKeychainService()
        sut = SparkViewModel(
            pendingHealthSummary: pendingHealthSummary,
            apiClient: apiClient,
            keychain: keychain,
            pollInterval: 1_000_000,
            maxPollAttempts: 3
        )
    }

    override func tearDown() {
        sut = nil
        keychain = nil
        apiClient = nil
        super.tearDown()
    }

    // MARK: - Join

    func test_join_whenNoGuestSession_createsOneBeforeJoining() async {
        keychain.storedSession = nil
        apiClient.responses["auth/guest"] = .success(
            GuestAuthResponse(accessToken: "guest-token", tokenType: "Bearer", expiresIn: 900, accountType: .guest)
        )
        apiClient.responses["me/health_summary"] = .success(HealthSummaryResponse(healthSummary: pendingHealthSummary))
        apiClient.responses["sparks/join"] = .success(sparkSession(id: 42, status: .active))

        await sut.join(qrToken: "token-abc")

        XCTAssertEqual(keychain.storedSession?.accessToken, "guest-token")
        XCTAssertEqual(keychain.storedSession?.accountType, .guest)
        XCTAssertEqual(sut.sparkSession?.id, 42)
        XCTAssertEqual(sut.step, .questionnaire)
        XCTAssertNil(sut.errorMessage)
    }

    func test_join_whenGuestSessionAlreadyExists_doesNotCreateAnotherOne() async {
        keychain.storedSession = StoredSession(accessToken: "existing-token", refreshToken: nil, accountType: .guest)
        apiClient.responses["me/health_summary"] = .success(HealthSummaryResponse(healthSummary: pendingHealthSummary))
        apiClient.responses["sparks/join"] = .success(sparkSession(id: 7, status: .active))

        await sut.join(sessionCode: "834920")

        XCTAssertFalse(apiClient.requestedPaths.contains("auth/guest"))
        XCTAssertEqual(keychain.storedSession?.accessToken, "existing-token")
    }

    func test_join_onFailure_setsErrorMessageAndStaysOnScanningStep() async {
        keychain.storedSession = StoredSession(accessToken: "token", refreshToken: nil, accountType: .guest)
        apiClient.responses["me/health_summary"] = .success(HealthSummaryResponse(healthSummary: pendingHealthSummary))
        apiClient.responses["sparks/join"] = .failure(
            APIClientError.server(code: "invalid_code", message: "That code doesn't match an active Spark.", field: nil, statusCode: 422)
        )

        await sut.join(sessionCode: "000000")

        XCTAssertEqual(sut.step, .scanning)
        XCTAssertEqual(sut.errorMessage, "That code doesn't match an active Spark.")
        XCTAssertNil(sut.sparkSession)
    }

    // MARK: - Questionnaire

    func test_advance_doesNothing_whenCurrentQuestionUnanswered() {
        sut.advance()
        XCTAssertEqual(sut.currentQuestionIndex, 0)
    }

    func test_advance_movesToNextQuestion_whenAnswered() {
        // Starts on `.scanning`; only a join (or an initiator resuming with a
        // joined session) puts the flow on the questionnaire — `advance()`
        // moves between questions, it never changes the step.
        let sut = SparkViewModel(
            joinedSession: SparkSession(id: 1, sessionCode: "834920", qrToken: nil, status: .active, startedAt: nil, locationLat: nil, locationLng: nil),
            apiClient: apiClient,
            keychain: keychain
        )
        XCTAssertEqual(sut.step, .questionnaire)

        sut.selectOption(1)
        sut.advance()

        XCTAssertEqual(sut.currentQuestionIndex, 1)
        XCTAssertEqual(sut.step, .questionnaire)
    }

    func test_init_withJoinedSession_startsOnQuestionnaireWithThatSession() {
        let session = SparkSession(id: 42, sessionCode: nil, qrToken: nil, status: .active, startedAt: nil, locationLat: nil, locationLng: nil)

        let sut = SparkViewModel(joinedSession: session, apiClient: apiClient, keychain: keychain)

        XCTAssertEqual(sut.step, .questionnaire)
        XCTAssertEqual(sut.sparkSession, session)
    }

    func test_join_withoutPendingHealthSummary_skipsTheHealthUpload() async {
        keychain.storedSession = StoredSession(accessToken: "t", refreshToken: nil, accountType: .active)
        let sut = SparkViewModel(apiClient: apiClient, keychain: keychain)
        apiClient.responses["sparks/join"] = .success(
            SparkSession(id: 7, sessionCode: "834920", qrToken: nil, status: .active, startedAt: nil, locationLat: nil, locationLng: nil)
        )

        await sut.join(sessionCode: "834920")

        XCTAssertFalse(apiClient.requestedPaths.contains("me/health_summary"))
        XCTAssertEqual(sut.step, .questionnaire)
    }

    func test_advance_onLastQuestion_submitsAnswersAndPreferencesThenPolls() async throws {
        await joinSuccessfully(sparkId: 5)

        for index in 0..<(sut.questions.count - 1) {
            sut.selectOption(index)
            sut.advance()
            try await Task.sleep(nanoseconds: 10_000_000)
        }

        apiClient.responses["sparks/5/submit_answers"] = .success(SubmitSparkAnswersResponse(status: .active))
        apiClient.responses["signals/preferences"] = .success(PreferenceProfile())
        apiClient.responses["sparks/5/result"] = .success(
            SparkResult(compatibilityScore: 84, dimensions: ["sleep_rhythm": 90], rewards: [])
        )

        sut.selectOption(2)
        sut.advance()
        try await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertTrue(apiClient.requestedPaths.contains("sparks/5/submit_answers"))
        XCTAssertTrue(apiClient.requestedPaths.contains("signals/preferences"))
        XCTAssertEqual(sut.step, .result)
        XCTAssertEqual(sut.result?.compatibilityScore, 84)
    }

    // MARK: - Result polling

    func test_pollForResult_retriesOnSparkNotCompleted_thenSucceeds() async {
        await joinSuccessfully(sparkId: 9)

        // FIFO sequence: two "not completed yet" responses, then a real result —
        // deterministic, no race against the poll loop's own timing.
        let notCompletedYet: Result<Any, Error> = .failure(
            APIClientError.server(code: "spark_not_completed", message: "Spark not completed yet", field: nil, statusCode: 422)
        )
        let completed: Result<Any, Error> = .success(SparkResult(compatibilityScore: 72, dimensions: [:], rewards: []))
        apiClient.responseSequences["sparks/9/result"] = [notCompletedYet, notCompletedYet, completed]

        await sut.pollForResult()

        XCTAssertEqual(sut.result?.compatibilityScore, 72)
        XCTAssertNil(sut.errorMessage)
    }

    func test_pollForResult_exhaustingAttempts_setsWaitingErrorMessage() async {
        await joinSuccessfully(sparkId: 11)
        apiClient.responses["sparks/11/result"] = .failure(
            APIClientError.server(code: "spark_not_completed", message: "Spark not completed yet", field: nil, statusCode: 422)
        )

        await sut.pollForResult()

        XCTAssertNil(sut.result)
        XCTAssertEqual(sut.errorMessage, "Still waiting on your Spark partner to finish. Try again in a moment.")
    }

    // MARK: - Helpers

    private func joinSuccessfully(sparkId: Int) async {
        keychain.storedSession = StoredSession(accessToken: "token", refreshToken: nil, accountType: .guest)
        apiClient.responses["me/health_summary"] = .success(HealthSummaryResponse(healthSummary: pendingHealthSummary))
        apiClient.responses["sparks/join"] = .success(sparkSession(id: sparkId, status: .active))
        await sut.join(qrToken: "token-abc")
    }

    private func sparkSession(id: Int, status: SparkStatus) -> SparkSession {
        SparkSession(id: id, sessionCode: "834920", qrToken: "token-abc", status: status, startedAt: nil, locationLat: nil, locationLng: nil)
    }
}
