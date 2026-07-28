import SwiftUI

/// Reached from `EntryView`'s "Create account" button — for a brand-new user
/// who wants an account without going through a Spark session first (e.g. the
/// very first user, with no partner around yet to scan a QR code with).
struct RegisterView: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel = RegisterViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Create account")
                .font(.syncaH3)
                .foregroundColor(.syncaText)
                .padding(.top, Spacing.space8)
                .padding(.bottom, 8)

            Text("Set up your profile so you're ready when you Spark with someone.")
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
                    textContentType: .newPassword,
                    isSecure: true
                )
            }

            Spacer(minLength: Spacing.space8)

            SyncaButton(title: "Create account", action: createAccountTapped, isLoading: viewModel.isLoading)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.syncaBackground)
        .alert(
            "Couldn't create account",
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

    private func createAccountTapped() {
        Task {
            if await viewModel.register() {
                router.resetToDashboard()
            }
        }
    }
}

#Preview {
    NavigationStack {
        RegisterView()
    }
    .environment(AppRouter())
    .preferredColorScheme(.dark)
}
