import Foundation
import Observation

/// Backs the Dashboard "Home" tab content — the "YOUR SPARKS" list.
@MainActor
@Observable
final class DashboardViewModel {
    private let apiClient: APIClientProtocol

    var isLoading = false
    private(set) var sparks: [SparkHistoryEntry] = []

    init(apiClient: APIClientProtocol = DemoMode.apiClient) {
        self.apiClient = apiClient
    }

    /// `GET /sparks` is marked "needed — not yet implemented" in
    /// docs/api/openapi.yaml — fail soft to an empty list rather than blocking
    /// the whole Dashboard behind an endpoint that doesn't exist on a real
    /// server yet.
    func load() async {
        isLoading = true
        defer { isLoading = false }
        sparks = (try? await apiClient.listSparks()) ?? []
    }
}
