import Foundation
import Observation

/// Session state machine for the whole in-app Spark flow — scan/join →
/// questionnaire → result. One instance backs `SparkFlowView` and its three
/// step views (`ScanQRView`, `SparkQuestionnaireView`, `SparkResultView`); this
/// is the multi-screen exception to "one ViewModel per screen" the same way
/// `AuthViewModel` spans Auth's screens — see docs/architecture/ios-structure.md.
/// Priority TDD target — see docs/conventions/ios.md § TDD.
@MainActor
@Observable
final class SparkViewModel {
    enum Step: Equatable {
        case scanning
        case questionnaire
        case result
    }

    private let apiClient: APIClientProtocol
    private let keychain: KeychainServiceProtocol
    private let proximityService: SparkProximityService
    private let pendingHealthSummary: HealthSummary
    private let pollInterval: UInt64
    private let maxPollAttempts: Int

    var step: Step = .scanning
    var isLoading = false
    var errorMessage: String?
    var manualCode: String = ""
    var isPollingResult = false

    private(set) var currentQuestionIndex = 0
    var selectedOptionIndexes: [Int?]

    private(set) var sparkSession: SparkSession?
    private(set) var result: SparkResult?

    let questions = SparkQuestionnaire.questions

    init(
        pendingHealthSummary: HealthSummary,
        apiClient: APIClientProtocol = APIClient.shared,
        keychain: KeychainServiceProtocol = KeychainService.shared,
        proximityService: SparkProximityService = SparkProximityService(),
        pollInterval: UInt64 = 2_000_000_000,
        maxPollAttempts: Int = 10
    ) {
        self.pendingHealthSummary = pendingHealthSummary
        self.apiClient = apiClient
        self.keychain = keychain
        self.proximityService = proximityService
        self.pollInterval = pollInterval
        self.maxPollAttempts = maxPollAttempts
        self.selectedOptionIndexes = Array(repeating: nil, count: SparkQuestionnaire.questions.count)
    }

    var currentQuestion: SparkQuestion { questions[currentQuestionIndex] }
    var isLastQuestion: Bool { currentQuestionIndex == questions.count - 1 }
    var isCurrentQuestionAnswered: Bool { selectedOptionIndexes[currentQuestionIndex] != nil }

    // MARK: - Scan / join

    func codeScanned(_ rawValue: String) {
        guard let token = proximityService.extractQRToken(from: rawValue) else { return }
        Task { await join(qrToken: token) }
    }

    func submitManualCode() {
        let trimmed = manualCode.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        Task { await join(sessionCode: trimmed) }
    }

    func join(qrToken: String? = nil, sessionCode: String? = nil) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await ensureGuestSession()
            try await apiClient.updateHealthSummary(pendingHealthSummary)
            let session = try await apiClient.joinSpark(sessionCode: sessionCode, qrToken: qrToken)
            sparkSession = session
            step = .questionnaire
        } catch {
            errorMessage = Self.message(for: error)
        }
    }

    /// Opens an anonymous guest session if none exists yet — see
    /// docs/product/decisions.md#spark-guest-anonymous-identity. A session
    /// created earlier in this run (e.g. a retry) is reused as-is.
    private func ensureGuestSession() async throws {
        if keychain.loadSession() != nil { return }
        let guestSession = try await apiClient.createGuestSession(email: nil)
        try keychain.save(StoredSession(accessToken: guestSession.accessToken, refreshToken: nil, accountType: guestSession.accountType))
    }

    // MARK: - Questionnaire

    func selectOption(_ index: Int) {
        selectedOptionIndexes[currentQuestionIndex] = index
    }

    func advance() {
        guard isCurrentQuestionAnswered else { return }
        if isLastQuestion {
            Task { await submitQuestionnaire() }
        } else {
            currentQuestionIndex += 1
        }
    }

    private func submitQuestionnaire() async {
        guard let sparkSession, !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let answers = selectedOptionIndexes.map { $0 ?? 0 }
            let preferences = SparkQuestionnaire.preferenceProfile(from: selectedOptionIndexes)
            async let statusTask = apiClient.submitSparkAnswers(sparkId: sparkSession.id, answers: answers)
            async let preferencesTask = apiClient.upsertPreferences(preferences)
            _ = try await (statusTask, preferencesTask)
            step = .result
            await pollForResult()
        } catch {
            errorMessage = Self.message(for: error)
        }
    }

    // MARK: - Result

    func pollForResult() async {
        guard let sparkSession else { return }
        isPollingResult = true
        errorMessage = nil
        defer { isPollingResult = false }

        for attempt in 0..<maxPollAttempts {
            do {
                result = try await apiClient.sparkResult(sparkId: sparkSession.id)
                return
            } catch let error as APIClientError where error.serverCode == "spark_not_completed" {
                if attempt < maxPollAttempts - 1 {
                    try? await Task.sleep(nanoseconds: pollInterval)
                }
            } catch {
                errorMessage = Self.message(for: error)
                return
            }
        }
        errorMessage = "Still waiting on your Spark partner to finish. Try again in a moment."
    }

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? "Something went wrong. Please try again."
    }
}
