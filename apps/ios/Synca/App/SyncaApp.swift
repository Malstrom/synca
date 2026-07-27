import SwiftUI

@main
struct SyncaApp: App {
    @State private var router = AppRouter()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(router)
                .preferredColorScheme(.dark) // Nocturne is dark-only for MVP — see docs/design/ui-system.md
        }
    }
}
