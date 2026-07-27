import SwiftUI

/// Root of the navigation tree. Decides between the guest Spark flow and the
/// Dashboard on launch (Keychain token check), then owns the single
/// `NavigationStack` all `AppDestination` pushes travel through.
/// See docs/design/ui-system.md § Navigation Map.
struct RootView: View {
    @Environment(AppRouter.self) private var router
    private let keychain: KeychainServiceProtocol = KeychainService.shared

    var body: some View {
        @Bindable var router = router

        NavigationStack(path: $router.path) {
            Group {
                switch router.rootScreen {
                case .loading:
                    LoadingView()
                case .guestSparkFlow:
                    ConnectHealthView()
                case .dashboard:
                    DashboardContainerView()
                }
            }
            .navigationDestination(for: AppDestination.self) { destination in
                destinationView(for: destination)
            }
        }
        .tint(.syncaAccent)
        .task { determineRootScreen() }
        .onReceive(NotificationCenter.default.publisher(for: APIClient.unauthorizedNotification)) { _ in
            router.resetToGuestFlow()
        }
    }

    /// No token, or a still-guest token → the guest Spark flow always restarts at
    /// Connect Apple Health. Resuming a Spark session that was left mid-flow
    /// (docs/product/phases/phase-0.md § UC-02) is out of scope for this pass —
    /// the qr_token itself stays valid server-side within its expiry window either way.
    private func determineRootScreen() {
        if let session = keychain.loadSession(), session.accountType == .active {
            router.rootScreen = .dashboard
        } else {
            router.rootScreen = .guestSparkFlow
        }
    }

    @ViewBuilder
    private func destinationView(for destination: AppDestination) -> some View {
        switch destination {
        case .sparkFlow(let pendingHealthSummary):
            SparkFlowView(pendingHealthSummary: pendingHealthSummary)
        case .saveResults(let sparkId):
            SaveResultsView(sparkId: sparkId)
        case .activation:
            ActivationView()
        case .generateQR:
            GenerateQRView()
        case .matchDetail(let matchId):
            MatchDetailView(matchId: matchId)
        case .login:
            LoginView()
        }
    }
}
