import SwiftUI

/// Screen 2 of the guest Spark flow — design source: row 1 / screen B
/// ("2 · Scan QR to join a Spark").
struct ScanQRView: View {
    @Bindable var viewModel: SparkViewModel
    @Environment(AppRouter.self) private var router
    @State private var showManualEntry = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                ZStack {
                    Circle().fill(Color.syncaWarm).frame(width: 16, height: 16)
                    Image(systemName: "checkmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.syncaBackground)
                }
                Text("Apple Health connected")
                    .font(.syncaCaption)
                    .foregroundColor(.syncaText.opacity(0.7))
            }
            .padding(.top, Spacing.space8)
            .padding(.bottom, 24)

            Text("Scan their QR code")
                .font(.syncaH4)
                .foregroundColor(.syncaText)
                .padding(.bottom, 6)

            Text("Point your camera at the code on their screen to start a Spark")
                .font(.syncaSmall)
                .foregroundColor(.syncaText.opacity(0.7))
                .padding(.bottom, 22)

            ZStack {
                RoundedRectangle(cornerRadius: 24).fill(Color.syncaSurface)

                if showManualEntry {
                    manualEntryContent
                } else {
                    QRCameraScannerView { value in viewModel.codeScanned(value) }
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                    QRViewfinderCorners()
                }
            }
            .frame(minHeight: 260, maxHeight: .infinity)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.syncaCaption)
                    .foregroundColor(.syncaError)
                    .padding(.top, Spacing.space3)
            }

            SyncaButton(
                title: showManualEntry ? "Scan instead" : "Enter code manually",
                action: { showManualEntry.toggle() },
                style: .secondary
            )
            .padding(.top, 20)

            HStack(spacing: 10) {
                Rectangle().fill(Color.syncaDivider).frame(height: 1)
                Text("OR").font(.syncaCaption).foregroundColor(.syncaText.opacity(0.5))
                Rectangle().fill(Color.syncaDivider).frame(height: 1)
            }
            .padding(.vertical, 18)

            SyncaButton(title: "Go to my profile instead", action: { router.navigate(to: .login) }, style: .ghost)

            Text("Requires signing in with your email")
                .font(.syncaCaption)
                .foregroundColor(.syncaText.opacity(0.5))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.syncaBackground)
        .navigationBarBackButtonHidden(true)
        .overlay {
            if viewModel.isLoading {
                LoadingView(message: "Joining Spark…")
            }
        }
    }

    private var manualEntryContent: some View {
        VStack(spacing: 12) {
            SyncaTextField(label: "Session code", placeholder: "834920", text: $viewModel.manualCode, keyboardType: .numberPad)
            SyncaButton(title: "Join", action: { viewModel.submitManualCode() })
        }
        .padding(20)
    }
}

/// Four L-shaped brackets over the camera preview, matching the prototype's
/// viewfinder corners.
private struct QRViewfinderCorners: View {
    var body: some View {
        GeometryReader { proxy in
            ForEach(0..<4, id: \.self) { index in
                CornerBracket()
                    .stroke(Color.syncaAccent, lineWidth: 3)
                    .frame(width: 28, height: 28)
                    .rotationEffect(.degrees(Double(index) * 90))
                    .position(cornerPosition(index, in: proxy.size))
            }
        }
        .allowsHitTesting(false)
    }

    private func cornerPosition(_ index: Int, in size: CGSize) -> CGPoint {
        let inset: CGFloat = 22 + 14
        switch index {
        case 0: return CGPoint(x: inset, y: inset)
        case 1: return CGPoint(x: size.width - inset, y: inset)
        case 2: return CGPoint(x: size.width - inset, y: size.height - inset)
        default: return CGPoint(x: inset, y: size.height - inset)
        }
    }
}

private struct CornerBracket: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}

#Preview {
    ScanQRView(viewModel: SparkViewModel(pendingHealthSummary: HealthSummary(effectiveFrom: "2026-07-27")))
        .environment(AppRouter())
        .preferredColorScheme(.dark)
}
