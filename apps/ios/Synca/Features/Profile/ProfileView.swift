import SwiftUI

/// Profile tab — "My Health". Design source: row 4, second screen ("Profile —
/// My Health").
struct ProfileView: View {
    @State private var viewModel = ProfileViewModel()

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Circle().fill(Color.syncaAccent800).frame(width: 56, height: 56)
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayName)
                        .font(.custom("Inter-Medium", size: 18))
                        .foregroundColor(.syncaText)
                    Text("My Health")
                        .font(.syncaCaption)
                        .foregroundColor(.syncaText.opacity(0.6))
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, Spacing.space8)
            .padding(.bottom, 16)

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if let summary = viewModel.signalsSummary {
                        rhythmSection(summary)
                    } else if viewModel.isLoading {
                        LoadingView()
                            .frame(minHeight: 300)
                    } else {
                        noSignalsPrompt
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
        .task { await viewModel.load() }
    }

    private var displayName: String {
        guard let name = viewModel.profile?.displayName, !name.isEmpty else { return "—" }
        return name
    }

    @ViewBuilder
    private func rhythmSection(_ summary: SignalsSummary) -> some View {
        Text("YOUR RHYTHM").syncaEyebrowStyle().foregroundColor(.syncaAccent)
        Text(summary.chronotypeLabel)
            .font(.syncaH2)
            .foregroundColor(.syncaText)
            .padding(.bottom, 4)

        peakEnergyCard(summary)

        HStack(spacing: 12) {
            SyncaCard {
                SyncaCardKicker(text: "SLEEP AVG")
                SyncaCardTitle(text: sleepAverageText(summary))
            }
            .frame(maxWidth: .infinity)

            SyncaCard {
                SyncaCardKicker(text: "ROUTINE STABILITY")
                SyncaCardTitle(text: summary.routineStabilityTier?.capitalized ?? "—")
            }
            .frame(maxWidth: .infinity)
        }

        // Needed — not yet implemented server-side, see
        // docs/product/decisions.md#signals-steps-resting-hr-in-summary.
        if summary.avgDailySteps != nil || summary.avgRestingHeartRateBpm != nil {
            HStack(spacing: 12) {
                if let steps = summary.avgDailySteps {
                    SyncaCard {
                        SyncaCardKicker(text: "DAILY STEPS")
                        SyncaCardTitle(text: steps.formatted())
                    }
                    .frame(maxWidth: .infinity)
                }

                if let restingHeartRate = summary.avgRestingHeartRateBpm {
                    SyncaCard {
                        SyncaCardKicker(text: "RESTING HR")
                        SyncaCardTitle(text: "\(restingHeartRate) bpm")
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }

        if let note = summary.selfReportAlignment.note {
            selfReportCheckCard(note)
        }
    }

    private func peakEnergyCard(_ summary: SignalsSummary) -> some View {
        SyncaCard {
            SyncaCardKicker(text: "PEAK ENERGY WINDOW")
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(0..<24, id: \.self) { hour in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(isPeakHour(hour, summary: summary) ? Color.syncaWarm : Color.syncaNeutral700)
                        .frame(width: 5, height: barHeight(hour, summary: summary))
                }
            }
            .frame(height: 34, alignment: .bottom)
            .padding(.top, 4)

            if let window = summary.peakEnergyWindow {
                SyncaCardTitle(text: window, size: 15).padding(.top, 4)
            }
        }
    }

    private func selfReportCheckCard(_ note: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.space2) {
            SyncaCardKicker(text: "SELF-REPORT CHECK")
            Text(note)
                .font(.syncaSmall)
                .foregroundColor(.syncaText)
        }
        .padding(Spacing.space3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.syncaAccent900)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md)
                .stroke(Color.syncaAccent700, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
    }

    private var noSignalsPrompt: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Connect Apple Health to see your rhythm")
                .font(.custom("Inter-Medium", size: 17))
                .foregroundColor(.syncaText)
            Text("Synca reads your sleep, activity, and rhythm from Apple Health. Raw data never leaves your phone.")
                .font(.syncaSmall)
                .foregroundColor(.syncaText.opacity(0.7))
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.syncaCaption)
                    .foregroundColor(.syncaError)
            }
            SyncaButton(title: "Connect Apple Health", action: connectHealthTapped, isLoading: viewModel.isLoading)
        }
        .padding(.top, 40)
    }

    private func connectHealthTapped() {
        Task { await viewModel.connectHealth() }
    }

    // MARK: - Peak energy bar chart

    /// The summary only returns a window string ("21:00–23:00"), not per-hour
    /// energy values — this renders a smooth curve centered on that window
    /// rather than fabricating hourly data.
    private func peakHourRange(_ summary: SignalsSummary) -> Range<Int>? {
        guard let window = summary.peakEnergyWindow else { return nil }
        let parts = window.split(separator: "–")
        guard parts.count == 2,
              let start = Int(parts[0].prefix(2)),
              let end = Int(parts[1].prefix(2)) else { return nil }
        return start..<max(start + 1, end)
    }

    private func isPeakHour(_ hour: Int, summary: SignalsSummary) -> Bool {
        peakHourRange(summary)?.contains(hour) ?? false
    }

    private func barHeight(_ hour: Int, summary: SignalsSummary) -> CGFloat {
        guard let range = peakHourRange(summary) else { return 10 }
        let center = Double(range.lowerBound + range.upperBound) / 2
        let distance = abs(Double(hour) - center)
        let normalized = max(0, 1 - distance / 10)
        return 6 + CGFloat(normalized) * 28
    }

    private func sleepAverageText(_ summary: SignalsSummary) -> String {
        guard let minutes = summary.avgSleepDurationMinutes else { return "—" }
        return "\(minutes / 60)h \(minutes % 60)m"
    }
}

#Preview {
    ProfileView()
        .background(Color.syncaBackground)
        .preferredColorScheme(.dark)
}
