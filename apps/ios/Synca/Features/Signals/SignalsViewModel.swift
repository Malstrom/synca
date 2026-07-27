import Foundation
import Observation

/// Backs `ConnectHealthView` only. Requests HealthKit permission and aggregates
/// the last 30 days into a `HealthSummary` — held in memory and handed to
/// `SparkFlowView` via `AppDestination.sparkFlow(pendingHealthSummary:)`, not
/// uploaded yet: there is no authenticated session at this point in the guest
/// flow (see docs/product/decisions.md#spark-guest-anonymous-identity). The
/// upload happens once `SparkViewModel` has a guest session, right before joining.
@MainActor
@Observable
final class SignalsViewModel {
    private let aggregatorService: SignalAggregatorService

    var isLoading = false
    var errorMessage: String?

    init(aggregatorService: SignalAggregatorService = SignalAggregatorService()) {
        self.aggregatorService = aggregatorService
    }

    /// Per docs/product/decisions.md#signals-partial-spark-scoring, Spark is
    /// blocked in MVP if Apple Health isn't connected — so this has no "skip"
    /// path, only retry.
    func connectAppleHealth() async -> HealthSummary? {
        errorMessage = nil

        guard aggregatorService.isHealthDataAvailable else {
            errorMessage = "Apple Health isn't available on this device."
            return nil
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await aggregatorService.requestAuthorization()
            return try await aggregatorService.aggregate()
        } catch {
            errorMessage = "We couldn't read your Apple Health data. Please try again."
            return nil
        }
    }
}
