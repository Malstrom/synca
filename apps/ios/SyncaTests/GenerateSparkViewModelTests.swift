import XCTest
@testable import Synca

@MainActor
final class GenerateSparkViewModelTests: XCTestCase {
    private var apiClient: MockAPIClient!
    private var sut: GenerateSparkViewModel!

    private func session(id: Int = 1, status: SparkStatus) -> SparkSession {
        SparkSession(id: id, sessionCode: "834920", qrToken: "qr-token", status: status, startedAt: nil, locationLat: nil, locationLng: nil)
    }

    override func setUp() {
        super.setUp()
        apiClient = MockAPIClient()
        sut = GenerateSparkViewModel(apiClient: apiClient, pollInterval: 1_000_000)
    }

    override func tearDown() {
        sut.stopPolling()
        sut = nil
        apiClient = nil
        super.tearDown()
    }

    func test_generate_createsSparkAndRendersQRCode() async {
        apiClient.responses["sparks"] = .success(session(status: .pending))

        await sut.generate()

        XCTAssertEqual(sut.sparkSession?.id, 1)
        XCTAssertNotNil(sut.qrImage)
        XCTAssertNil(sut.errorMessage)
    }

    func test_generate_onFailure_setsErrorMessage() async {
        apiClient.responses["sparks"] = .failure(APIClientError.network("offline"))

        await sut.generate()

        XCTAssertNil(sut.sparkSession)
        XCTAssertNotNil(sut.errorMessage)
    }

    func test_polling_whileStillPending_doesNotAdvance() async throws {
        apiClient.responses["sparks/1"] = .success(session(status: .pending))

        sut.startPolling(sparkId: 1)
        try await Task.sleep(nanoseconds: 20_000_000)

        XCTAssertNil(sut.joinedSession)
    }

    func test_polling_whenPartnerJoins_exposesJoinedSession() async throws {
        // Without this the initiator would sit on the QR forever and the Spark
        // could never be scored — SparkScoringJob needs both sides' answers.
        apiClient.responseSequences["sparks/1"] = [
            .success(session(status: .pending)),
            .success(session(status: .active))
        ]

        sut.startPolling(sparkId: 1)
        try await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertEqual(sut.joinedSession?.status, .active)
    }

    func test_polling_survivesATransientRequestFailure() async throws {
        apiClient.responseSequences["sparks/1"] = [
            .failure(APIClientError.network("dropped")),
            .success(session(status: .active))
        ]

        sut.startPolling(sparkId: 1)
        try await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertEqual(sut.joinedSession?.status, .active)
    }

    func test_defaultCountdownMatchesServerExpiryWindow() {
        // Settings.spark.expiry_minutes on the backend is 15.
        XCTAssertEqual(sut.remainingSeconds, 15 * 60)
        XCTAssertEqual(sut.formattedRemaining, "15:00")
    }
}
