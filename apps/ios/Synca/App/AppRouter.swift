import SwiftUI
import Observation

/// Programmatic `NavigationStack` routing — the iOS equivalent of `redirect_to` in
/// a Rails controller. Views never push routes directly, they call
/// `router.navigate(to:)`. See docs/architecture/ios-structure.md § AppRouter.
///
/// `sparkFlow` is a single destination that internally drives
/// scan → questionnaire → result as steps of one `SparkViewModel` state machine,
/// rather than three separate pushes — see `Features/Spark/SparkFlowView.swift`
/// for why (they need to share one in-flight Spark session, not be recreated
/// per screen).
enum AppDestination: Hashable {
    case sparkFlow(pendingHealthSummary: HealthSummary)
    case saveResults(sparkId: Int)
    case activation
    case generateQR
    case matchDetail(matchId: Int)
    /// "Go to my profile instead" shortcut on the Scan QR screen, for a
    /// returning user with a full account — see `LoginView`.
    case login
}

@Observable
final class AppRouter {
    enum RootScreen {
        case loading
        case guestSparkFlow
        case dashboard
    }

    var path = NavigationPath()
    var rootScreen: RootScreen = .loading

    func navigate(to destination: AppDestination) {
        path.append(destination)
    }

    func popToRoot() {
        path.removeLast(path.count)
    }

    /// Sends the user back to the guest entry point (Connect Apple Health) — used
    /// on launch when there's no active session, and on a 401 from any authenticated
    /// call (see `APIClient.unauthorizedNotification`).
    func resetToGuestFlow() {
        popToRoot()
        rootScreen = .guestSparkFlow
    }

    /// Used after activation succeeds, and on launch when a valid active-account
    /// session is already in the Keychain.
    func resetToDashboard() {
        popToRoot()
        rootScreen = .dashboard
    }
}
