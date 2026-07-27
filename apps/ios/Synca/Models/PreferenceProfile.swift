import Foundation

enum TemperaturePreference: String, Codable, CaseIterable {
    case cool, warm
    case noPreference = "no_preference"
}

enum MovementPreference: String, Codable, CaseIterable {
    case veryLittle = "very_little"
    case moderate
    case aLot = "a_lot"
    case asMuchAsPossible = "as_much_as_possible"
}

enum SelfChronotype: String, Codable, CaseIterable {
    case morning, night, depends
}

/// Backs the 5-question declared-preferences questionnaire, which — per the design
/// review — also doubles as the Spark on-the-spot questionnaire. One field per
/// question, in the order defined in docs/features/signals-v1.md § Questionnaire.
struct PreferenceProfile: Codable, Equatable {
    var sleepTogetherImportance: Int?
    var temperaturePreference: TemperaturePreference?
    var movementPreference: MovementPreference?
    var rhythmImportance: Int?
    var selfChronotype: SelfChronotype?
}

/// `PATCH /signals/preferences` request body wraps under `preferences:`.
struct PreferenceProfileUpdateRequest: Codable {
    let preferences: PreferenceProfile
}
