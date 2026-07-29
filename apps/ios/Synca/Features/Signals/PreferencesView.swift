import SwiftUI

/// "Your preferences" — the 5-question set on its own, reached from the Profile
/// tab. Same questions as the in-Spark questionnaire (see `SparkQuestionnaire`),
/// but answerable any time and as often as the user likes: they feed
/// `PATCH /signals/preferences`, which every future Spark is scored against.
struct PreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = PreferencesViewModel()

    var body: some View {
        let question = viewModel.currentQuestion

        VStack(alignment: .leading, spacing: 0) {
            SyncaTag(text: "YOUR PREFERENCES", style: .accent)
                .padding(.top, Spacing.space8)
                .padding(.bottom, 18)

            HStack(spacing: 6) {
                ForEach(0..<viewModel.questions.count, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(index <= viewModel.currentQuestionIndex ? Color.syncaAccent : Color.syncaNeutral800)
                        .frame(height: 4)
                }
            }
            .padding(.bottom, 22)

            Text(SparkQuestionnaire.eyebrow(forQuestionAt: viewModel.currentQuestionIndex, context: .preferences))
                .syncaEyebrowStyle()
                .foregroundColor(.syncaAccent)

            Text(question.title)
                .font(.syncaH4)
                .foregroundColor(.syncaText)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)
                .padding(.bottom, 26)

            VStack(spacing: 12) {
                ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                    QuestionOptionRow(
                        label: option.label,
                        isSelected: viewModel.selectedOptionIndexes[viewModel.currentQuestionIndex] == index,
                        action: { viewModel.selectOption(index) }
                    )
                }
            }

            Spacer(minLength: 16)

            SyncaButton(
                title: viewModel.isLastQuestion ? "Save preferences" : "Next",
                action: advanceTapped,
                isLoading: viewModel.isLoading,
                isDisabled: !viewModel.isCurrentQuestionAnswered
            )

            if viewModel.currentQuestionIndex > 0 {
                SyncaButton(title: "Back", action: { viewModel.goBack() }, style: .ghost)
                    .padding(.top, 8)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.syncaBackground)
        .animation(.default, value: viewModel.currentQuestionIndex)
        .alert(
            "Couldn't save",
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

    private func advanceTapped() {
        Task {
            if await viewModel.advance() { dismiss() }
        }
    }
}

#Preview {
    NavigationStack {
        PreferencesView()
    }
    .preferredColorScheme(.dark)
}
