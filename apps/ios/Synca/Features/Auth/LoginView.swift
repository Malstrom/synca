import SwiftUI

/// Reached from the Scan QR screen's "Go to my profile instead" shortcut —
/// design source: Igor's comment on the Scan QR screen ("dovrebbe esserci una
/// scelta ho scan del qr code o vai al mio profilo, ma a quel punto bisogna
/// mettere la mail insomma avere una authorizzazione"). Backed by the already-
/// implemented `POST /auth/login`.
struct LoginView: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel = LoginViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Sign in")
                .font(.syncaH3)
                .foregroundColor(.syncaText)
                .padding(.top, Spacing.space8)
                .padding(.bottom, 8)

            Text("Sign in to see your profile, past Sparks, and matches.")
                .font(.syncaSmall)
                .foregroundColor(.syncaText.opacity(0.7))
                .frame(maxWidth: 280, alignment: .leading)
                .padding(.bottom, 28)

            VStack(spacing: 12) {
                SyncaTextField(
                    label: "Email",
                    placeholder: "you@email.com",
                    text: $viewModel.email,
                    keyboardType: .emailAddress,
                    textContentType: .emailAddress,
                    autocapitalization: .never
                )
                SyncaTextField(
                    label: "Password",
                    placeholder: "••••••••",
                    text: $viewModel.password,
                    textContentType: .password,
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

            SyncaButton(title: "Sign in", action: signInTapped, isLoading: viewModel.isLoading)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.syncaBackground)
    }

    private func signInTapped() {
        Task {
            if await viewModel.login() {
                router.resetToDashboard()
            }
        }
    }
}

#Preview {
    NavigationStack {
        LoginView()
    }
    .environment(AppRouter())
    .preferredColorScheme(.dark)
}
