import SwiftUI

struct ErrorView: View {
    let message: String
    var retryAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: Spacing.space4) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title)
                .foregroundColor(.syncaError)
            Text(message)
                .font(.syncaBody)
                .multilineTextAlignment(.center)
                .foregroundColor(.syncaText)
            if let retryAction {
                SyncaButton(title: "Retry", action: retryAction, style: .secondary)
            }
        }
        .padding(Spacing.space6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.syncaBackground)
    }
}

#Preview {
    ErrorView(message: "Check your connection and try again.") {}
}
