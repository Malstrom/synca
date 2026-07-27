import SwiftUI

/// Concept — not yet built. Design source: row 5, second screen ("Match detail
/// — concept"). See `MatchListView`.
struct MatchDetailView: View {
    let matchId: Int

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = MatchDetailViewModel()

    var body: some View {
        ScrollView {
            Group {
                if viewModel.isLoading {
                    LoadingView().frame(minHeight: 400)
                } else if let errorMessage = viewModel.errorMessage {
                    ErrorView(message: errorMessage) { Task { await viewModel.load(matchId: matchId) } }
                        .frame(minHeight: 400)
                } else if let match = viewModel.match {
                    content(for: match)
                }
            }
        }
        .background(Color.syncaBackground)
        .task { await viewModel.load(matchId: matchId) }
    }

    private func content(for match: Match) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.syncaText)
                }
                Text(match.participants.first?.profile?.displayName ?? "—")
                    .font(.syncaH4)
                    .foregroundColor(.syncaText)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, Spacing.space8)
            .padding(.bottom, 20)

            VStack(spacing: 14) {
                CompatibilityRing(score: Int(match.compatibilityScore.rounded()), diameter: 130)
                SyncaTag(text: "SYNCA CONFIRMED · SPARK", style: .accent)
            }
            .padding(.bottom, 22)

            VStack(spacing: 10) {
                ForEach(viewModel.dimensions, id: \.label) { dimension in
                    DimensionBar(label: dimension.label, value: dimension.value)
                }
            }
            .padding(.horizontal, 20)

            Spacer(minLength: 20)

            SyncaButton(title: "Propose a Moment", action: {})
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
        }
    }
}

private struct DimensionBar: View {
    let label: String
    let value: Double

    var body: some View {
        SyncaCard {
            HStack {
                Text(label).font(.syncaSmall).foregroundColor(.syncaText)
                Spacer()
                Text("\(Int(value.rounded()))%").font(.syncaSmall).foregroundColor(.syncaAccent)
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(Color.syncaNeutral800)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.syncaAccent)
                        .frame(width: proxy.size.width * CGFloat(min(max(value, 0), 100)) / 100)
                }
            }
            .frame(height: 6)
        }
    }
}

#Preview {
    NavigationStack {
        MatchDetailView(matchId: 1)
    }
    .preferredColorScheme(.dark)
}
