import Foundation
import UIKit
import Observation

/// Backs `GenerateQRView` only — registered users starting a Spark.
/// See docs/features/spark-v1.md § QR flow.
///
/// Polls `GET /sparks/:id` while the QR is on screen: the initiator has no
/// other way to learn that someone scanned it, and without that they'd sit on
/// the QR forever while the partner waits on a result that can never be scored
/// (`SparkScoringJob` only runs once *both* sides have answered).
@MainActor
@Observable
final class GenerateSparkViewModel {
    private let apiClient: APIClientProtocol
    private let proximityService: SparkProximityService
    private let sessionDurationSeconds: Int
    private let pollInterval: UInt64

    var isLoading = false
    var errorMessage: String?
    private(set) var sparkSession: SparkSession?
    private(set) var qrImage: UIImage?
    /// Set once a partner has joined — `GenerateQRView` watches this and moves
    /// the initiator on to the questionnaire.
    private(set) var joinedSession: SparkSession?
    var remainingSeconds: Int

    private var pollTask: Task<Void, Never>?

    init(
        apiClient: APIClientProtocol = DemoMode.apiClient,
        proximityService: SparkProximityService = SparkProximityService(),
        // Matches the server-side window (`Settings.spark.expiry_minutes`, 15) —
        // SparkExpireJob flips the Spark to `expired` past it.
        sessionDurationSeconds: Int = 15 * 60,
        pollInterval: UInt64 = 2_000_000_000
    ) {
        self.apiClient = apiClient
        self.proximityService = proximityService
        self.sessionDurationSeconds = sessionDurationSeconds
        self.pollInterval = pollInterval
        self.remainingSeconds = sessionDurationSeconds
    }

    // No `deinit` cancel: `pollTask` is `@MainActor`-isolated and can't be
    // touched from a nonisolated deinit. The loop holds `self` weakly and
    // returns as soon as it's gone, so a dropped view model stops polling on
    // its own — `GenerateQRView.onDisappear` cancels it promptly.

    func generate() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let session = try await apiClient.createSpark()
            sparkSession = session
            if let qrToken = session.qrToken {
                qrImage = proximityService.qrCodeImage(forQRToken: qrToken)
            }
            remainingSeconds = sessionDurationSeconds
            startPolling(sparkId: session.id)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Couldn't start a Spark. Please try again."
        }
    }

    /// Transient failures (a dropped request mid-poll) are deliberately
    /// swallowed: the partner may still be about to scan, and surfacing an
    /// error under a perfectly valid QR would just be noise. The countdown is
    /// what ends the wait.
    func startPolling(sparkId: Int) {
        pollTask?.cancel()
        pollTask = Task { [weak self, pollInterval] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: pollInterval)
                guard !Task.isCancelled, let self else { return }
                guard let session = try? await self.apiClient.spark(id: sparkId) else { continue }
                if session.status != .pending {
                    self.joinedSession = session
                    return
                }
            }
        }
    }

    func stopPolling() {
        pollTask?.cancel()
        pollTask = nil
    }

    func tick() {
        guard remainingSeconds > 0 else { return }
        remainingSeconds -= 1
        if remainingSeconds == 0 { stopPolling() }
    }

    var formattedRemaining: String {
        String(format: "%02d:%02d", remainingSeconds / 60, remainingSeconds % 60)
    }
}
