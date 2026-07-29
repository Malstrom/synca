import SwiftUI

/// "Start a Spark — create a QR" — registered users only. Design source: row 2
/// ("2 · Start a Spark — create a QR"). Reached from the Dashboard's
/// "Start a Spark" button and the Spark tab.
struct GenerateQRView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router
    @State private var viewModel = GenerateSparkViewModel()
    @State private var isPulsing = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            SyncaTag(text: "REGISTERED USER", style: .outline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, Spacing.space8)
                .padding(.bottom, 16)

            Text("Start a Spark")
                .font(.syncaH4)
                .foregroundColor(.syncaText)
                .padding(.bottom, 6)

            // Not the system Camera app: the QR encodes a synca.app universal
            // link, but there's no associated-domains entitlement (and no such
            // domain yet), so it has to be scanned from inside Synca.
            Text("Have them scan this from the Synca app")
                .font(.syncaSmall)
                .foregroundColor(.syncaText.opacity(0.7))
                .padding(.bottom, 30)

            qrCode

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.syncaCaption)
                    .foregroundColor(.syncaError)
                    .multilineTextAlignment(.center)
                    .padding(.top, 16)
            } else {
                VStack(spacing: 6) {
                    Text("Expires in \(viewModel.formattedRemaining)")
                        .font(.syncaSmall)
                        .foregroundColor(.syncaAccent)
                    Text("Waiting for them to scan…")
                        .font(.syncaCaption)
                        .foregroundColor(.syncaText.opacity(0.5))
                }
                .padding(.top, 28)
            }

            Spacer()

            SyncaButton(title: "Cancel", action: { dismiss() }, style: .secondary)
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.syncaBackground)
        .multilineTextAlignment(.center)
        .task { await viewModel.generate() }
        .onReceive(timer) { _ in viewModel.tick() }
        .onAppear { isPulsing = true }
        .onDisappear { viewModel.stopPolling() }
        .onChange(of: viewModel.joinedSession) { _, joined in
            // Someone scanned the QR — the initiator still owes their own
            // answers before the Spark can be scored, so go straight there.
            guard let joined else { return }
            router.navigate(to: .sparkFlow(pendingHealthSummary: nil, joinedSession: joined))
        }
    }

    private var qrCode: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26)
                .stroke(Color.syncaAccent, lineWidth: 2)
                .scaleEffect(isPulsing ? 1.06 : 1.0)
                .opacity(isPulsing ? 0 : 0.6)
                .animation(.easeOut(duration: 2).repeatForever(autoreverses: false), value: isPulsing)

            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .frame(width: 186, height: 186)
                .shadow(color: .black.opacity(0.4), radius: 12, y: 6)

            if let qrImage = viewModel.qrImage {
                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .frame(width: 150, height: 150)
            } else {
                ProgressView()
            }
        }
        .frame(width: 186, height: 186)
    }
}

#Preview {
    NavigationStack {
        GenerateQRView()
    }
    .environment(AppRouter())
    .preferredColorScheme(.dark)
}
