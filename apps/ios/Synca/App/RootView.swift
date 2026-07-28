import SwiftUI

/// Root of the navigation tree. Decides between the entry choice screen and the
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
                case .entry:
                    EntryView()
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
            router.sessionExpiredMessage = APIClientError.unauthorized.errorDescription
            router.resetToEntry()
        }
        .alert(
            "Session expired",
            isPresented: Binding(
                get: { router.sessionExpiredMessage != nil },
                set: { if !$0 { router.sessionExpiredMessage = nil } }
            ),
            presenting: router.sessionExpiredMessage
        ) { _ in
            Button("OK") { router.sessionExpiredMessage = nil }
        } message: { message in
            Text(message)
        }
    }

    /// No token, or a still-guest token → the entry choice screen (scan / create
    /// account / sign in). Resuming a Spark session that was left mid-flow
    /// (docs/product/phases/phase-0.md § UC-02) is out of scope for this pass —
    /// the qr_token itself stays valid server-side within its expiry window either way.
    private func determineRootScreen() {
        if let session = keychain.loadSession(), session.accountType == .active {
            router.rootScreen = .dashboard
        } else {
            router.rootScreen = .entry
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
        case .register:
            RegisterView()
        }
    }
}
