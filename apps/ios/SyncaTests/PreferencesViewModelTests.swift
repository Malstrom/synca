import XCTest
@testable import Synca

@MainActor
final class PreferencesViewModelTests: XCTestCase {
    private var apiClient: MockAPIClient!
    private var sut: PreferencesViewModel!

    override func setUp() {
        super.setUp()
        apiClient = MockAPIClient()
        sut = PreferencesViewModel(apiClient: apiClient)
    }

    override func tearDown() {
        sut = nil
        apiClient = nil
        super.tearDown()
    }

    private func answerAllButLast() async {
        for index in 0..<(sut.questions.count - 1) {
            sut.selectOption(index % sut.currentQuestion.options.count)
            _ = await sut.advance()
        }
    }

    func test_advance_doesNothing_whenCurrentQuestionUnanswered() async {
        let finished = await sut.advance()

        XCTAssertFalse(finished)
        XCTAssertEqual(sut.currentQuestionIndex, 0)
        XCTAssertTrue(apiClient.requestedPaths.isEmpty)
    }

    func test_advance_movesThroughQuestionsWithoutSavingUntilTheLast() async {
        await answerAllButLast()

        XCTAssertEqual(sut.currentQuestionIndex, sut.questions.count - 1)
        XCTAssertTrue(sut.isLastQuestion)
        XCTAssertFalse(apiClient.requestedPaths.contains("signals/preferences"))
    }

    func test_advance_onLastQuestion_savesPreferencesAndReportsCompletion() async {
        apiClient.responses["signals/preferences"] = .success(PreferenceProfile())
        await answerAllButLast()
        sut.selectOption(0)

        let finished = await sut.advance()

        XCTAssertTrue(finished)
        XCTAssertTrue(apiClient.requestedPaths.contains("signals/preferences"))
        XCTAssertNil(sut.errorMessage)
    }

    func test_advance_onLastQuestion_whenSaveFails_setsErrorAndDoesNotComplete() async {
        apiClient.responses["signals/preferences"] = .failure(APIClientError.network("offline"))
        await answerAllButLast()
        sut.selectOption(0)

        let finished = await sut.advance()

        XCTAssertFalse(finished)
        XCTAssertNotNil(sut.errorMessage)
    }

    func test_goBack_returnsToThePreviousQuestion() async {
        sut.selectOption(0)
        _ = await sut.advance()
        XCTAssertEqual(sut.currentQuestionIndex, 1)

        sut.goBack()

        XCTAssertEqual(sut.currentQuestionIndex, 0)
    }

    func test_goBack_onFirstQuestion_staysPut() {
        sut.goBack()

        XCTAssertEqual(sut.currentQuestionIndex, 0)
    }
}
