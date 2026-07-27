import SwiftUI

enum DashboardTab {
    case home, profile
}

/// Custom 3-icon bottom bar — Home / Spark / Profile, per Igor's review comment
/// ("il menu dovrebbe avere la home, li spark, il profilo utante"). Not a system
/// `TabView`: the middle item is a shortcut into `GenerateQRView`, not a tab with
/// its own persistent content, so a hand-drawn bar (matching the prototype,
/// which also just lays out 3 SVGs) is the right fit.
struct SyncaTabBar: View {
    @Binding var selectedTab: DashboardTab
    var onSparkTapped: () -> Void

    var body: some View {
        HStack {
            tabButton(systemImage: "house", tab: .home)
            Spacer()
            Button(action: onSparkTapped) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.syncaNeutral500)
            }
            .accessibilityLabel("Start a Spark")
            Spacer()
            tabButton(systemImage: "person.crop.circle", tab: .profile)
        }
        .padding(.horizontal, 44)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .overlay(Rectangle().fill(Color.syncaDivider).frame(height: 1), alignment: .top)
        .background(Color.syncaBackground)
    }

    private func tabButton(systemImage: String, tab: DashboardTab) -> some View {
        Button(action: { selectedTab = tab }) {
            Image(systemName: systemImage)
                .font(.system(size: 20))
                .foregroundColor(selectedTab == tab ? .syncaAccent : .syncaNeutral500)
        }
        .accessibilityLabel(tab == .home ? "Home" : "Profile")
    }
}
