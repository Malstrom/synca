import Foundation
import HealthKit

/// Abstracts `HKHealthStore` so `SignalAggregatorService` is testable without ever
/// touching a real health store — per apps/ios/.calvin/conventions.yml:
/// "Never hit real HKHealthStore in tests — use HealthKitProtocol mock."
protocol HealthKitProtocol {
    var isHealthDataAvailable: Bool { get }

    func requestAuthorization(toRead types: Set<HKObjectType>) async throws

    /// Category samples (e.g. sleep analysis) in `[start, end]`, oldest first.
    func categorySamples(for type: HKCategoryType, start: Date, end: Date) async throws -> [HKCategorySample]

    /// Raw quantity samples (e.g. step count, active energy) in `[start, end]`, oldest first.
    func quantitySamples(for type: HKQuantityType, start: Date, end: Date) async throws -> [HKQuantitySample]
}

enum HealthKitError: Error {
    case notAvailable
    case authorizationDenied
}

/// Thin wrapper around the real `HKHealthStore`. All aggregation logic lives in
/// `SignalAggregatorService` — this type only fetches samples.
final class HealthKitStore: HealthKitProtocol {
    private let store = HKHealthStore()

    var isHealthDataAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func requestAuthorization(toRead types: Set<HKObjectType>) async throws {
        guard isHealthDataAvailable else { throw HealthKitError.notAvailable }
        try await store.requestAuthorization(toShare: [], read: types)
    }

    func categorySamples(for type: HKCategoryType, start: Date, end: Date) async throws -> [HKCategorySample] {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: (samples as? [HKCategorySample]) ?? [])
                }
            }
            store.execute(query)
        }
    }

    func quantitySamples(for type: HKQuantityType, start: Date, end: Date) async throws -> [HKQuantitySample] {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: (samples as? [HKQuantitySample]) ?? [])
                }
            }
            store.execute(query)
        }
    }
}
