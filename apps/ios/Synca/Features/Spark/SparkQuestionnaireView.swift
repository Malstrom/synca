import SwiftUI

/// Screen 3 of the guest Spark flow — design source: row 1 / screen C
/// ("3 · Spark questionnaire — same 5 questions, no separate onboarding page").
/// One shared question set doubles as declared-preferences setup and Spark
/// scoring input, per the design review (see `SparkQuestionnaire`).
struct SparkQuestionnaireView: View {
    @Bindable var viewModel: SparkViewModel

    var body: some View {
        let question = viewModel.currentQuestion

        VStack(alignment: .leading, spacing: 0) {
            SyncaTag(text: "SPARK QUESTIONNAIRE", style: .accent)
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

            Text(SparkQuestionnaire.eyebrow(forQuestionAt: viewModel.currentQuestionIndex, context: .spark))
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

            Text("One questionnaire, used both to set your preferences and to score this Spark")
                .font(.syncaCaption)
                .foregroundColor(.syncaText.opacity(0.5))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.syncaCaption)
                    .foregroundColor(.syncaError)
                    .padding(.bottom, 8)
            }

            SyncaButton(
                title: viewModel.isLastQuestion ? "See my result" : "Next",
                action: { viewModel.advance() },
                isLoading: viewModel.isLoading,
                isDisabled: !viewModel.isCurrentQuestionAnswered
            )
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.syncaBackground)
        .navigationBarBackButtonHidden(true)
        .animation(.default, value: viewModel.currentQuestionIndex)
    }
}

/// Shared with `PreferencesView`, which asks the same question set outside a
/// Spark — hence not private to this file.
struct QuestionOptionRow: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? Color.syncaAccent : Color.syncaDivider, lineWidth: 1.5)
                    if isSelected {
                        Circle().fill(Color.syncaAccent).padding(3)
                    }
                }
                .frame(width: 18, height: 18)

                Text(label)
                    .font(.syncaSmall)
                    .foregroundColor(isSelected ? .syncaAccent : .syncaText)

                Spacer()
            }
            .padding(14)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md)
                    .stroke(isSelected ? Color.syncaAccent : Color.syncaDivider, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SparkQuestionnaireView(viewModel: SparkViewModel(pendingHealthSummary: HealthSummary(effectiveFrom: "2026-07-27")))
        .preferredColorScheme(.dark)
}
