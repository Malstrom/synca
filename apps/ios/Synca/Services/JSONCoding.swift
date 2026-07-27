import Foundation

/// Shared coder configuration: snake_case wire format, camelCase Swift models,
/// ISO8601 for genuine `Date` fields. Short date/time-only fields (`effective_from`,
/// `sleep_start_local`, ...) are modeled as `String`, so they're unaffected by the
/// date strategy — see docs/conventions/ios.md § Data & Persistence.
///
/// Rails' default JSON datetime format includes fractional seconds
/// ("2026-07-27T10:15:00.123Z"), which the plain `.iso8601` strategy's
/// `ISO8601DateFormatter` (no `.withFractionalSeconds`) fails to parse — try
/// fractional seconds first, fall back to whole seconds.
private let iso8601WithFractionalSeconds: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
}()

private let iso8601WholeSeconds: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter
}()

extension JSONDecoder {
    static let synca: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            if let date = iso8601WithFractionalSeconds.date(from: dateString) ?? iso8601WholeSeconds.date(from: dateString) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Expected ISO8601 date, got \(dateString)")
        }
        return decoder
    }()
}

extension JSONEncoder {
    static let synca: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(iso8601WithFractionalSeconds.string(from: date))
        }
        return encoder
    }()
}
