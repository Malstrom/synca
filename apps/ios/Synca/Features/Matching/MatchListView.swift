import SwiftUI

/// Concept — not yet built. Design source: row 5, first screen ("Match list —
/// concept"). Not wired into `AppRouter`/the tab bar on purpose — reachable only
/// via SwiftUI previews or a future debug menu.
struct MatchListView: View {
    @State private var viewModel = MatchListViewModel()

    var body: some View {
        VStack(spacing: 0) {
            Text("Matches")
                .font(.syncaH2)
                .foregroundColor(.syncaText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, Spacing.space8)
                .padding(.bottom, 16)

            Group {
                if viewModel.isLoading {
                    LoadingView()
                } else if let errorMessage = viewModel.errorMessage {
                    ErrorView(message: errorMessage) { Task { await viewModel.load() } }
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(viewModel.matches) { match in
                                NavigationLink(value: AppDestination.matchDetail(matchId: match.id)) {
                                    MatchRow(match: match)
                                }
                                .buttonStyle(.plain)
                                Divider().overlay(Color.syncaDivider)
                            }
                        }
                    }
                }
            }
        }
        .background(Color.syncaBackground)
        .task { await viewModel.load() }
    }
}

private struct MatchRow: View {
    let match: Match

    var body: some View {
        HStack(spacing: 12) {
            AvatarPlaceholder(diameter: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text(match.participants.first?.profile?.displayName ?? "—")
                    .font(.syncaBody)
                    .foregroundColor(.syncaText)
                SyncaTag(
                    text: match.status == "accepted" ? "Confirmed" : "Suggested",
                    style: match.status == "accepted" ? .accent : .accent2
                )
            }

            Spacer()

            MiniCompatibilityRing(score: match.compatibilityScore)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.syncaNeutral500)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}

private struct MiniCompatibilityRing: View {
    let score: Double

    var body: some View {
        ZStack {
            Circle().stroke(Color.syncaNeutral800, lineWidth: 3.5)
            Circle()
                .trim(from: 0, to: CGFloat(min(max(score, 0), 100)) / 100)
                .stroke(Color.syncaAccent, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(score.rounded()))")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.syncaText)
        }
        .frame(width: 34, height: 34)
    }
}

#Preview {
    NavigationStack {
        MatchListView()
    }
    .preferredColorScheme(.dark)
}
