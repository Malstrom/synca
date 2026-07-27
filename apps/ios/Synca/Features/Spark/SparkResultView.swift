import SwiftUI

/// Screen 4 of the guest Spark flow — design source: row 1 / screen D
/// ("4 · Spark result — now with photos & a recap"), the screen Igor asked to
/// make richer. Photos are Phase 1 (see `AvatarPlaceholder`); the recap uses the
/// dimension percentages `GET /sparks/:id/result` actually returns rather than
/// literal per-user bedtime/step values — see
/// docs/product/decisions.md#spark-result-recap-data-source.
struct SparkResultView: View {
    @Bindable var viewModel: SparkViewModel
    @Environment(AppRouter.self) private var router

    var body: some View {
        ScrollView {
            content
                .padding(.horizontal, 22)
                .padding(.top, Spacing.space8)
                .padding(.bottom, 28)
                .frame(maxWidth: .infinity)
        }
        .background(Color.syncaBackground)
        .navigationBarBackButtonHidden(true)
        .task { if viewModel.result == nil { await viewModel.pollForResult() } }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isPollingResult && viewModel.result == nil {
            LoadingView(message: "Scoring your Spark…")
                .frame(minHeight: 400)
        } else if let errorMessage = viewModel.errorMessage, viewModel.result == nil {
            ErrorView(message: errorMessage) {
                Task { await viewModel.pollForResult() }
            }
            .frame(minHeight: 400)
        } else if let result = viewModel.result {
            resultContent(result)
        }
    }

    private func resultContent(_ result: SparkResult) -> some View {
        let score = Int(result.compatibilityScore.rounded())
        let tier = CompatibilityTier(score: score)

        return VStack(spacing: 0) {
            OverlappingAvatarPair()
                .padding(.bottom, 14)

            SyncaTag(text: "SYNCA CONFIRMED · SPARK", style: .accent)
                .padding(.bottom, 18)

            CompatibilityRing(score: score)
                .padding(.bottom, 20)

            Text(tier.headline)
                .font(.syncaH4)
                .foregroundColor(.syncaText)
                .padding(.bottom, 6)

            Text(tier.subtext)
                .font(.syncaSmall)
                .foregroundColor(.syncaText.opacity(0.7))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
                .padding(.bottom, 18)

            recapCard(result)
                .padding(.bottom, 20)

            SyncaButton(title: "Save this connection", action: {
                guard let sparkId = viewModel.sparkSession?.id else { return }
                router.navigate(to: .saveResults(sparkId: sparkId))
            })
        }
    }

    private func recapCard(_ result: SparkResult) -> some View {
        SyncaCard {
            SyncaCardKicker(text: "RECAP")
            VStack(spacing: 8) {
                ForEach(recapRows(result), id: \.label) { row in
                    HStack {
                        Text(row.label)
                            .font(.syncaSmall)
                            .foregroundColor(.syncaText.opacity(0.75))
                        Spacer()
                        Text(row.valueText)
                            .font(.syncaSmall)
                            .foregroundColor(.syncaAccent)
                    }
                }
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
    }

    private struct RecapRow { let label: String; let valueText: String }

    private func recapRows(_ result: SparkResult) -> [RecapRow] {
        // `dimensions` is decoded through JSONDecoder.synca's .convertFromSnakeCase,
        // which also rewrites dictionary keys ("sleep_rhythm" -> "sleepRhythm") —
        // look up the camelCase form, not the wire-format snake_case one.
        let order: [(key: String, label: String)] = [
            ("sleepRhythm", "Sleep rhythm"),
            ("energyOverlap", "Energy overlap"),
            ("lifestyle", "Lifestyle")
        ]
        return order.compactMap { key, label in
            guard let value = result.dimensions[key] else { return nil }
            return RecapRow(label: label, valueText: "\(Int(value.rounded()))%")
        }
    }
}

#Preview {
    let viewModel = SparkViewModel(pendingHealthSummary: HealthSummary(effectiveFrom: "2026-07-27"))
    return SparkResultView(viewModel: viewModel)
        .environment(AppRouter())
        .preferredColorScheme(.dark)
}
