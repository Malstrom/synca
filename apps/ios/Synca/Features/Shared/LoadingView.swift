import SwiftUI

struct LoadingView: View {
    var message: String = "Loading..."

    var body: some View {
        VStack(spacing: Spacing.space4) {
            ProgressView().tint(.syncaAccent)
            Text(message)
                .font(.syncaCaption)
                .foregroundColor(.syncaText.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.syncaBackground)
    }
}

#Preview {
    LoadingView()
}
