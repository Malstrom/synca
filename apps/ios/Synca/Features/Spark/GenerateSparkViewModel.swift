import Foundation
import UIKit
import Observation

/// Backs `GenerateQRView` only — registered users starting a Spark.
/// See docs/features/spark-v1.md § QR flow (10-minute default expiry).
@MainActor
@Observable
final class GenerateSparkViewModel {
    private let apiClient: APIClientProtocol
    private let proximityService: SparkProximityService
    private let sessionDurationSeconds: Int

    var isLoading = false
    var errorMessage: String?
    private(set) var sparkSession: SparkSession?
    private(set) var qrImage: UIImage?
    var remainingSeconds: Int

    init(
        apiClient: APIClientProtocol = DemoMode.apiClient,
        proximityService: SparkProximityService = SparkProximityService(),
        sessionDurationSeconds: Int = 10 * 60
    ) {
        self.apiClient = apiClient
        self.proximityService = proximityService
        self.sessionDurationSeconds = sessionDurationSeconds
        self.remainingSeconds = sessionDurationSeconds
    }

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
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Couldn't start a Spark. Please try again."
        }
    }

    func tick() {
        guard remainingSeconds > 0 else { return }
        remainingSeconds -= 1
    }

    var formattedRemaining: String {
        String(format: "%02d:%02d", remainingSeconds / 60, remainingSeconds % 60)
    }
}
