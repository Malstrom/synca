import Foundation
import HealthKit
@testable import Synca

/// Never touches a real `HKHealthStore` — per
/// apps/ios/.calvin/conventions.yml: "Never hit real HKHealthStore in tests —
/// use HealthKitProtocol mock." Keyed by HealthKit identifier so
/// `SignalAggregatorService`'s parallel sleep/steps/energy queries each get
/// their own scripted samples.
final class MockHealthKitStore: HealthKitProtocol {
    var isHealthDataAvailable = true
    var categorySamplesByIdentifier: [String: [HKCategorySample]] = [:]
    var quantitySamplesByIdentifier: [String: [HKQuantitySample]] = [:]
    private(set) var didRequestAuthorization = false

    func requestAuthorization(toRead types: Set<HKObjectType>) async throws {
        didRequestAuthorization = true
    }

    func categorySamples(for type: HKCategoryType, start: Date, end: Date) async throws -> [HKCategorySample] {
        categorySamplesByIdentifier[type.identifier] ?? []
    }

    func quantitySamples(for type: HKQuantityType, start: Date, end: Date) async throws -> [HKQuantitySample] {
        quantitySamplesByIdentifier[type.identifier] ?? []
    }
}
