import SwiftUI

/// First screen shown when there's no active session — lets a brand-new user
/// choose between joining a Spark (scanning a partner's QR code), creating an
/// account directly, or signing in to an existing one. Added because the
/// guest-Spark flow alone left the very first user (nobody yet to scan a QR
/// with, and QR generation is registered-users-only) with no way in at all.
struct EntryView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            Text("Welcome to Synca")
                .font(.syncaH2)
                .foregroundColor(.syncaText)
                .padding(.bottom, 8)

            Text("Scan a partner's Spark QR code, create an account, or sign in.")
                .font(.syncaSmall)
                .foregroundColor(.syncaText.opacity(0.7))
                .frame(maxWidth: 280, alignment: .leading)

            Spacer()

            VStack(spacing: 12) {
                SyncaButton(title: "Scan a Spark QR code", action: { router.rootScreen = .guestSparkFlow })
                SyncaButton(title: "Create account", action: { router.navigate(to: .register) }, style: .secondary)
                SyncaButton(title: "Sign in", action: { router.navigate(to: .login) }, style: .ghost)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.syncaBackground)
    }
}

#Preview {
    NavigationStack {
        EntryView()
    }
    .environment(AppRouter())
    .preferredColorScheme(.dark)
}
