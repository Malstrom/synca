import XCTest
@testable import Synca

@MainActor
final class ProfileViewModelTests: XCTestCase {
    private var apiClient: MockAPIClient!
    private var healthStore: MockHealthKitStore!
    private var sut: ProfileViewModel!

    override func setUp() {
        super.setUp()
        apiClient = MockAPIClient()
        healthStore = MockHealthKitStore()
        let signalsViewModel = SignalsViewModel(aggregatorService: SignalAggregatorService(healthStore: healthStore))
        sut = ProfileViewModel(apiClient: apiClient, signalsViewModel: signalsViewModel)
    }

    override func tearDown() {
        sut = nil
        healthStore = nil
        apiClient = nil
        super.tearDown()
    }

    func test_connectHealth_whenHealthDataUnavailable_setsErrorMessageWithoutCallingAPI() async {
        healthStore.isHealthDataAvailable = false

        let succeeded = await sut.connectHealth()

        XCTAssertFalse(succeeded)
        XCTAssertEqual(sut.errorMessage, "Apple Health isn't available on this device.")
        XCTAssertFalse(apiClient.requestedPaths.contains("me/health_summary"))
    }

    func test_connectHealth_onSuccess_uploadsSummaryAndReloadsProfile() async {
        let summary = HealthSummary(
            chronotype: nil, source: nil, effectiveFrom: "2026-07-01", effectiveTo: nil,
            sleepStartLocal: nil, sleepEndLocal: nil, avgSleepDurationMinutes: nil,
            routineStabilityIndex: nil, activityLevel: nil, peakEnergyStartLocal: nil,
            peakEnergyEndLocal: nil, recoveryScore: nil
        )
        apiClient.responses["me/health_summary"] = .success(HealthSummaryResponse(healthSummary: summary))
        apiClient.responses["me"] = .success(
            MeResponse(user: User(id: 1, email: "a@b.com", phone: nil, authProvider: "email"), profile: nil, healthSummary: nil)
        )
        apiClient.responses["signals/me/summary"] = .failure(APIClientError.server(code: "no_signals", message: "No signals", field: nil, statusCode: 404))

        let succeeded = await sut.connectHealth()

        XCTAssertTrue(succeeded)
        XCTAssertTrue(healthStore.didRequestAuthorization)
        XCTAssertTrue(apiClient.requestedPaths.contains("me/health_summary"))
        XCTAssertNil(sut.errorMessage)
    }
}
