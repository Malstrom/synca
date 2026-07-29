import SwiftUI

/// Owns the single `SparkViewModel` instance for the whole scan → questionnaire →
/// result sequence and swaps step content in place, rather than pushing three
/// separate `navigationDestination`s — the three steps share one in-flight Spark
/// session and must not be recreated per screen. See `SparkViewModel`.
struct SparkFlowView: View {
    @State private var viewModel: SparkViewModel

    init(pendingHealthSummary: HealthSummary? = nil, joinedSession: SparkSession? = nil) {
        _viewModel = State(initialValue: SparkViewModel(
            pendingHealthSummary: pendingHealthSummary,
            joinedSession: joinedSession
        ))
    }

    var body: some View {
        Group {
            switch viewModel.step {
            case .scanning:
                ScanQRView(viewModel: viewModel)
            case .questionnaire:
                SparkQuestionnaireView(viewModel: viewModel)
            case .result:
                SparkResultView(viewModel: viewModel)
            }
        }
        .animation(.default, value: viewModel.step)
    }
}
