import SwiftUI

/// Screen 1 of the guest Spark flow — the app's front door for anyone without an
/// active session. Design source: row 1 / screen A of the Claude Design handoff
/// ("1 · App opens — connect Apple Health").
struct ConnectHealthView: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel = SignalsViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: Radius.lg)
                    .fill(Color.syncaWarmBg)
                    .frame(width: 56, height: 56)
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 22))
                    .foregroundColor(.syncaWarmSoft)
            }
            .padding(.top, Spacing.space8)
            .padding(.bottom, 26)

            Text("STEP 1 OF 2")
                .syncaEyebrowStyle()
                .foregroundColor(.syncaAccent)
                .padding(.bottom, 8)

            Text("Understand yourself before anyone else does")
                .font(.syncaH3)
                .foregroundColor(.syncaText)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 14)

            Text("Synca reads your sleep, activity, and rhythm from Apple Health.")
                .font(.syncaSmall)
                .foregroundColor(.syncaText.opacity(0.7))
                .padding(.bottom, 8)

            Text("Raw data never leaves your phone — only a summary is shared.")
                .font(.syncaSmall)
                .foregroundColor(.syncaText.opacity(0.7))

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.syncaCaption)
                    .foregroundColor(.syncaError)
                    .padding(.top, Spacing.space4)
            }

            Spacer(minLength: Spacing.space8)

            SyncaButton(title: "Connect Apple Health", action: connect, isLoading: viewModel.isLoading)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.syncaBackground)
        .navigationBarBackButtonHidden(true)
    }

    private func connect() {
        Task {
            if let summary = await viewModel.connectAppleHealth() {
                router.navigate(to: .sparkFlow(pendingHealthSummary: summary))
            }
        }
    }
}

#Preview {
    NavigationStack {
        ConnectHealthView()
    }
    .environment(AppRouter())
    .preferredColorScheme(.dark)
}
