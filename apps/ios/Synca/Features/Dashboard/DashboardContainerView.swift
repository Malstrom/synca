import SwiftUI

/// Root of the logged-in experience. Owns the custom tab bar's selection state;
/// see `SyncaTabBar` for why this isn't a system `TabView`.
struct DashboardContainerView: View {
    @Environment(AppRouter.self) private var router
    @State private var selectedTab: DashboardTab = .home

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch selectedTab {
                case .home:
                    DashboardHomeView()
                case .profile:
                    ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            SyncaTabBar(selectedTab: $selectedTab, onSparkTapped: { router.navigate(to: .generateQR) })
        }
        .background(Color.syncaBackground)
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    DashboardContainerView()
        .environment(AppRouter())
        .preferredColorScheme(.dark)
}
