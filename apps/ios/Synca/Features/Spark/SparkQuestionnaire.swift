import Foundation

struct SparkQuestionOption {
    let label: String
}

struct SparkQuestion {
    let eyebrow: String
    let title: String
    let options: [SparkQuestionOption]
}

/// The 5-question set from docs/features/signals-v1.md § Questionnaire. Per the
/// design review, this single set now serves double duty — declared-preferences
/// setup AND the Spark on-the-spot questionnaire — asked once, right after
/// scanning and before the result. See docs/api/openapi.yaml § /signals/preferences.
enum SparkQuestionnaire {
    private static let eyebrowSuffix = "RIGHT AFTER SCANNING, BEFORE YOUR RESULT"

    static let questions: [SparkQuestion] = [
        SparkQuestion(
            eyebrow: "QUESTION 1 OF 5 · \(eyebrowSuffix)",
            title: "Is it important to you to fall asleep at the same time as your partner?",
            options: ["Not important", "Slightly important", "Moderately important", "Important", "Very important"].map(SparkQuestionOption.init)
        ),
        SparkQuestion(
            eyebrow: "QUESTION 2 OF 5 · \(eyebrowSuffix)",
            title: "Do you prefer sleeping in a cool or warm environment?",
            options: ["Cool", "Warm", "No preference"].map(SparkQuestionOption.init)
        ),
        SparkQuestion(
            eyebrow: "QUESTION 3 OF 5 · \(eyebrowSuffix)",
            title: "How much daily movement feels right for you?",
            options: ["Very little", "Moderate", "A lot", "As much as possible"].map(SparkQuestionOption.init)
        ),
        SparkQuestion(
            eyebrow: "QUESTION 4 OF 5 · \(eyebrowSuffix)",
            title: "How important is it that the people close to you share your daily rhythm?",
            options: ["Not important", "Slightly important", "Moderately important", "Important", "Very important"].map(SparkQuestionOption.init)
        ),
        SparkQuestion(
            eyebrow: "QUESTION 5 OF 5 · \(eyebrowSuffix)",
            title: "Do you consider yourself more of a morning person or a night person?",
            options: ["Morning person", "Night person", "Depends"].map(SparkQuestionOption.init)
        )
    ]

    /// Maps the 5 selected option indexes to the typed `PATCH /signals/preferences`
    /// payload. Selections are `nil` only for an in-progress questionnaire — by the
    /// time this is called every index has been answered.
    static func preferenceProfile(from selections: [Int?]) -> PreferenceProfile {
        var profile = PreferenceProfile()
        if let value = selections[0] { profile.sleepTogetherImportance = value + 1 }
        if let value = selections[1] { profile.temperaturePreference = [.cool, .warm, .noPreference][value] }
        if let value = selections[2] { profile.movementPreference = [.veryLittle, .moderate, .aLot, .asMuchAsPossible][value] }
        if let value = selections[3] { profile.rhythmImportance = value + 1 }
        if let value = selections[4] { profile.selfChronotype = [.morning, .night, .depends][value] }
        return profile
    }
}
