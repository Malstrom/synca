import SwiftUI

/// Screen 5 of the guest Spark flow — design source: row 1 / screen E
/// ("5 · Save results — moved after the Spark, not before", per Igor's review).
struct SaveResultsView: View {
    let sparkId: Int

    @Environment(AppRouter.self) private var router
    @State private var viewModel = AuthViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Save your results")
                .font(.syncaH2)
                .foregroundColor(.syncaText)
                .padding(.top, Spacing.space8)
                .padding(.bottom, 8)

            Text("Enter your email so you don't lose this Spark — no spam, ever.")
                .font(.syncaSmall)
                .foregroundColor(.syncaText.opacity(0.7))
                .frame(maxWidth: 280, alignment: .leading)
                .padding(.bottom, 28)

            SyncaTextField(
                label: "Email",
                placeholder: "you@email.com",
                text: $viewModel.email,
                keyboardType: .emailAddress,
                textContentType: .emailAddress,
                autocapitalization: .never
            )

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.syncaCaption)
                    .foregroundColor(.syncaError)
                    .padding(.top, Spacing.space3)
            }

            Spacer(minLength: Spacing.space8)

            VStack(spacing: 10) {
                SyncaButton(title: "Continue", action: continueTapped, isLoading: viewModel.isLoading)
                Text("Your health data never leaves your phone")
                    .font(.syncaCaption)
                    .foregroundColor(.syncaText.opacity(0.45))
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.syncaBackground)
        .navigationBarBackButtonHidden(true)
    }

    private func continueTapped() {
        Task {
            if await viewModel.saveResults() {
                router.navigate(to: .activation)
            }
        }
    }
}

#Preview {
    SaveResultsView(sparkId: 1)
        .environment(AppRouter())
        .preferredColorScheme(.dark)
}
