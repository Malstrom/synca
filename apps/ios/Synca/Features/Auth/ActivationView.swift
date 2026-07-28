import SwiftUI

/// "Guest account activation" — design source: row 3 ("Almost there").
/// Also the target of the magic-link deep link for a guest who closed the app
/// before activating in-session — see docs/api/openapi.yaml § /auth/activate.
struct ActivationView: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel = AuthViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Almost there")
                .font(.syncaH3)
                .foregroundColor(.syncaText)
                .padding(.top, Spacing.space8)
                .padding(.bottom, 8)

            Text("Set a name so your Spark match knows who they connected with.")
                .font(.syncaSmall)
                .foregroundColor(.syncaText.opacity(0.7))
                .frame(maxWidth: 280, alignment: .leading)
                .padding(.bottom, 28)

            VStack(spacing: 12) {
                SyncaTextField(
                    label: "Display name",
                    placeholder: "e.g. Alex",
                    text: $viewModel.displayName,
                    textContentType: .name
                )
                SyncaTextField(
                    label: "Password",
                    placeholder: "••••••••",
                    text: $viewModel.password,
                    textContentType: .newPassword,
                    isSecure: true
                )
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.syncaCaption)
                    .foregroundColor(.syncaError)
                    .padding(.top, Spacing.space3)
            }

            Spacer(minLength: Spacing.space8)

            VStack(spacing: 8) {
                SyncaButton(title: "Activate my account", action: activateTapped, isLoading: viewModel.isLoading)
                Text("Your Spark result is saved once you activate")
                    .font(.syncaCaption)
                    .foregroundColor(.syncaText.opacity(0.5))
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.syncaBackground)
        .navigationBarBackButtonHidden(true)
        .alert(
            "Activation failed",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            ),
            presenting: viewModel.errorMessage
        ) { _ in
            Button("OK") { viewModel.errorMessage = nil }
        } message: { message in
            Text(message)
        }
    }

    private func activateTapped() {
        Task {
            if await viewModel.activate() {
                router.resetToDashboard()
            }
        }
    }
}

#Preview {
    ActivationView()
        .environment(AppRouter())
        .preferredColorScheme(.dark)
}
