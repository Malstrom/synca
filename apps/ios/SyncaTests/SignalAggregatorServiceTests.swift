import XCTest
import HealthKit
@testable import Synca

/// HealthKit inputs → expected metric outputs — priority TDD target, see
/// docs/conventions/ios.md § TDD. Never touches a real `HKHealthStore`.
final class SignalAggregatorServiceTests: XCTestCase {
    private var healthStore: MockHealthKitStore!
    private var sut: SignalAggregatorService!

    override func setUp() {
        super.setUp()
        healthStore = MockHealthKitStore()
        sut = SignalAggregatorService(healthStore: healthStore)
    }

    override func tearDown() {
        sut = nil
        healthStore = nil
        super.tearDown()
    }

    func test_isHealthDataAvailable_reflectsStore() {
        healthStore.isHealthDataAvailable = false
        XCTAssertFalse(sut.isHealthDataAvailable)
    }

    func test_requestAuthorization_delegatesToStore() async throws {
        try await sut.requestAuthorization()
        XCTAssertTrue(healthStore.didRequestAuthorization)
    }

    func test_aggregate_withConsistentEarlyNights_computesEarlyBirdAndHighStability() async throws {
        let calendar = Calendar(identifier: .gregorian)
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!

        var samples: [HKCategorySample] = []
        for dayOffset in 0..<5 {
            let wakeDay = calendar.date(byAdding: .day, value: -dayOffset, to: calendar.startOfDay(for: Date()))!
            let onset = calendar.date(byAdding: .hour, value: -1, to: wakeDay)! // 23:00 the previous day
            let wake = calendar.date(byAdding: .hour, value: 7, to: wakeDay)!   // 07:00 that day
            samples.append(HKCategorySample(
                type: sleepType,
                value: HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                start: onset,
                end: wake
            ))
        }
        healthStore.categorySamplesByIdentifier[sleepType.identifier] = samples

        let summary = try await sut.aggregate()

        XCTAssertEqual(summary.chronotype, .earlyBird)
        XCTAssertEqual(summary.avgSleepDurationMinutes, 480)
        XCTAssertEqual(summary.sleepStartLocal, "23:00")
        XCTAssertEqual(summary.sleepEndLocal, "07:00")
        XCTAssertEqual(summary.routineStabilityIndex, 1.0)
    }

    func test_aggregate_withConsistentLateNights_computesNightOwl() async throws {
        let calendar = Calendar(identifier: .gregorian)
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!

        var samples: [HKCategorySample] = []
        for dayOffset in 0..<5 {
            let wakeDay = calendar.date(byAdding: .day, value: -dayOffset, to: calendar.startOfDay(for: Date()))!
            let onset = calendar.date(byAdding: .hour, value: 1, to: wakeDay)! // 01:00
            let wake = calendar.date(byAdding: .hour, value: 9, to: wakeDay)!  // 09:00
            samples.append(HKCategorySample(
                type: sleepType,
                value: HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                start: onset,
                end: wake
            ))
        }
        healthStore.categorySamplesByIdentifier[sleepType.identifier] = samples

        let summary = try await sut.aggregate()

        XCTAssertEqual(summary.chronotype, .nightOwl)
    }

    func test_aggregate_withNoSleepSamples_leavesSleepFieldsNil() async throws {
        let summary = try await sut.aggregate()

        XCTAssertNil(summary.chronotype)
        XCTAssertNil(summary.avgSleepDurationMinutes)
        XCTAssertNil(summary.routineStabilityIndex)
    }

    func test_aggregate_withHighStepCount_reportsHighActivityLevel() async throws {
        let stepType = HKObjectType.quantityType(forIdentifier: .stepCount)!
        // 30-day total so the /30-day average lands at 12,000/day (> 10,000 = high).
        let quantity = HKQuantity(unit: .count(), doubleValue: 12000 * 30)
        let sample = HKQuantitySample(type: stepType, quantity: quantity, start: Date(), end: Date())
        healthStore.quantitySamplesByIdentifier[stepType.identifier] = [sample]

        let summary = try await sut.aggregate()

        XCTAssertEqual(summary.activityLevel, .high)
    }

    func test_aggregate_withNoStepSamples_reportsLowActivityLevel() async throws {
        let summary = try await sut.aggregate()
        XCTAssertEqual(summary.activityLevel, .low)
    }

    func test_aggregate_setsEffectiveFromToToday() async throws {
        let summary = try await sut.aggregate()

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        XCTAssertEqual(summary.effectiveFrom, formatter.string(from: Date()))
    }
}
