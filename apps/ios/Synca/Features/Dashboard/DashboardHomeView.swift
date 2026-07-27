import SwiftUI

/// Home tab — design source: row 4, first screen ("Home — Home / Spark / Profile tabs").
struct DashboardHomeView: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel = DashboardViewModel()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Synca")
                    .font(.syncaH4)
                    .foregroundColor(.syncaText)
                Spacer()
                Circle().fill(Color.syncaAccent800).frame(width: 32, height: 32)
            }
            .padding(.horizontal, 20)
            .padding(.top, Spacing.space8)
            .padding(.bottom, 14)

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    SyncaButton(title: "Start a Spark", action: { router.navigate(to: .generateQR) })

                    VStack(alignment: .leading, spacing: 10) {
                        Text("YOUR SPARKS").syncaEyebrowStyle().foregroundColor(.syncaAccent)

                        if viewModel.sparks.isEmpty {
                            Text(viewModel.isLoading ? "Loading…" : "No Sparks yet — start one above.")
                                .font(.syncaCaption)
                                .foregroundColor(.syncaText.opacity(0.5))
                        } else {
                            ForEach(viewModel.sparks) { spark in
                                SparkHistoryRow(spark: spark)
                            }
                        }
                    }

                    comingSoonCard
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
        .task { await viewModel.load() }
    }

    private var comingSoonCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("COMING SOON").syncaEyebrowStyle().foregroundColor(.syncaAccent)
            Text("Algorithm-based matching — surfacing compatible people without a Spark.")
                .font(.syncaSmall)
                .foregroundColor(.syncaText.opacity(0.7))
        }
        .padding(Spacing.space3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md)
                .stroke(Color.syncaDivider, style: StrokeStyle(lineWidth: 1, dash: [4]))
        )
    }
}

private struct SparkHistoryRow: View {
    let spark: SparkHistoryEntry

    var body: some View {
        HStack(spacing: 12) {
            OverlappingAvatarPair(diameter: 32, borderColor: .syncaSurface, borderWidth: 2)

            VStack(alignment: .leading, spacing: 3) {
                Text(titleText)
                    .font(.custom("Inter-Medium", size: 14))
                    .foregroundColor(.syncaText)
                SyncaTag(text: tagText, style: tagStyle)
            }

            Spacer()
        }
        .padding(Spacing.space3)
        .background(Color.syncaSurface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
    }

    private var titleText: String {
        guard let score = spark.compatibilityScore else { return "In progress" }
        let dateText = spark.startedAt.map { DateFormatter.sparkShortDate.string(from: $0) } ?? ""
        return dateText.isEmpty ? "\(Int(score.rounded()))%" : "\(Int(score.rounded()))% · \(dateText)"
    }

    private var tagText: String {
        guard let score = spark.compatibilityScore else { return "Pending" }
        return score >= 50 ? "Confirmed" : "Low match"
    }

    private var tagStyle: SyncaTag.Style {
        guard let score = spark.compatibilityScore else { return .neutral }
        return score >= 50 ? .accent : .neutral
    }
}

extension DateFormatter {
    static let sparkShortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
}

#Preview {
    DashboardHomeView()
        .environment(AppRouter())
        .background(Color.syncaBackground)
        .preferredColorScheme(.dark)
}
