import Foundation
import Observation

/// Backs `PreferencesView` — the same 5-question set `SparkViewModel` asks
/// mid-Spark, but standalone and re-answerable from the Profile tab. Until
/// this existed the questionnaire was only reachable once, inside a guest's
/// first Spark, so a registered user had no way to ever change the
/// preferences their compatibility score is computed from.
@MainActor
@Observable
final class PreferencesViewModel {
    private let apiClient: APIClientProtocol

    var selectedOptionIndexes: [Int?]
    private(set) var currentQuestionIndex = 0
    var isLoading = false
    var errorMessage: String?

    let questions = SparkQuestionnaire.questions

    init(apiClient: APIClientProtocol = DemoMode.apiClient) {
        self.apiClient = apiClient
        self.selectedOptionIndexes = Array(repeating: nil, count: SparkQuestionnaire.questions.count)
    }

    var currentQuestion: SparkQuestion { questions[currentQuestionIndex] }
    var isLastQuestion: Bool { currentQuestionIndex == questions.count - 1 }
    var isCurrentQuestionAnswered: Bool { selectedOptionIndexes[currentQuestionIndex] != nil }

    func selectOption(_ index: Int) {
        selectedOptionIndexes[currentQuestionIndex] = index
    }

    func goBack() {
        guard currentQuestionIndex > 0 else { return }
        currentQuestionIndex -= 1
    }

    /// Returns true once the last answer has been saved, so the view can pop.
    func advance() async -> Bool {
        guard isCurrentQuestionAnswered else { return false }
        guard isLastQuestion else {
            currentQuestionIndex += 1
            return false
        }
        return await save()
    }

    private func save() async -> Bool {
        guard !isLoading else { return false }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            _ = try await apiClient.upsertPreferences(
                SparkQuestionnaire.preferenceProfile(from: selectedOptionIndexes)
            )
            return true
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Couldn't save your preferences. Please try again."
            return false
        }
    }
}
