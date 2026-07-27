import Foundation
import HealthKit

/// Requests read-only HealthKit permissions and aggregates the last 30 days of
/// sleep/activity data on-device — per docs/conventions/ios.md § HealthKit
/// Integration and docs/features/signals-v1.md § Health signals.
///
/// No `HKSample` ever leaves this type: `aggregate()` returns a `HealthSummary`
/// containing only derived numbers/labels, which is what gets sent to
/// `PUT /me/health_summary`.
@MainActor
final class SignalAggregatorService {
    private let healthStore: HealthKitProtocol
    private let aggregationWindowDays = 30

    static let readTypes: Set<HKObjectType> = [
        HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
        HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
        HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
    ]

    init(healthStore: HealthKitProtocol = HealthKitStore()) {
        self.healthStore = healthStore
    }

    var isHealthDataAvailable: Bool { healthStore.isHealthDataAvailable }

    func requestAuthorization() async throws {
        try await healthStore.requestAuthorization(toRead: Self.readTypes)
    }

    /// Aggregates the last 30 days into a `HealthSummary` ready for
    /// `PUT /me/health_summary`. `effectiveFrom` is always today.
    func aggregate() async throws -> HealthSummary {
        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -aggregationWindowDays, to: end) ?? end

        async let sleepSamplesTask = healthStore.categorySamples(
            for: HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            start: start,
            end: end
        )
        async let stepSamplesTask = healthStore.quantitySamples(
            for: HKObjectType.quantityType(forIdentifier: .stepCount)!,
            start: start,
            end: end
        )
        async let energySamplesTask = healthStore.quantitySamples(
            for: HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            start: start,
            end: end
        )

        let sleepSamples = try await sleepSamplesTask
        let stepSamples = try await stepSamplesTask
        let energySamples = try await energySamplesTask

        let sleepMetrics = Self.sleepMetrics(from: sleepSamples)
        let activityLevel = Self.activityLevel(fromDailyAverageSteps: Self.dailyAverage(of: stepSamples, over: aggregationWindowDays))
        let peakEnergyWindow = Self.peakEnergyWindow(from: energySamples)

        return HealthSummary(
            chronotype: sleepMetrics.chronotype,
            source: "apple_health",
            effectiveFrom: Self.dateFormatter.string(from: end),
            effectiveTo: nil,
            sleepStartLocal: sleepMetrics.sleepStartLocal,
            sleepEndLocal: sleepMetrics.sleepEndLocal,
            avgSleepDurationMinutes: sleepMetrics.avgDurationMinutes,
            routineStabilityIndex: sleepMetrics.routineStabilityIndex,
            activityLevel: activityLevel,
            peakEnergyStartLocal: peakEnergyWindow?.startLocal,
            peakEnergyEndLocal: peakEnergyWindow?.endLocal,
            recoveryScore: nil
        )
    }

    // MARK: - Sleep

    private struct SleepMetrics {
        var chronotype: Chronotype?
        var sleepStartLocal: String?
        var sleepEndLocal: String?
        var avgDurationMinutes: Int?
        var routineStabilityIndex: Double?
    }

    /// One "night" per calendar day the sleep period ends on. Onset = earliest
    /// asleep/inBed sample start that day's night; wake = latest sample end.
    private static func sleepMetrics(from samples: [HKCategorySample]) -> SleepMetrics {
        let asleepValues: Set<Int> = [
            HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
            HKCategoryValueSleepAnalysis.asleepCore.rawValue,
            HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
            HKCategoryValueSleepAnalysis.asleepREM.rawValue
        ]
        let asleepSamples = samples.filter { asleepValues.contains($0.value) }
        guard !asleepSamples.isEmpty else { return SleepMetrics() }

        let calendar = Calendar.current
        var nightsByDay: [Date: (onset: Date, wake: Date, minutes: Double)] = [:]

        for sample in asleepSamples {
            // A night "belongs" to the day its wake time falls on (sleep after
            // midnight is still last night's sleep from the user's perspective).
            let nightKey = calendar.startOfDay(for: sample.endDate)
            let minutes = sample.endDate.timeIntervalSince(sample.startDate) / 60
            if var existing = nightsByDay[nightKey] {
                existing.onset = min(existing.onset, sample.startDate)
                existing.wake = max(existing.wake, sample.endDate)
                existing.minutes += minutes
                nightsByDay[nightKey] = existing
            } else {
                nightsByDay[nightKey] = (onset: sample.startDate, wake: sample.endDate, minutes: minutes)
            }
        }

        let nights = Array(nightsByDay.values)
        guard !nights.isEmpty else { return SleepMetrics() }

        let avgDuration = nights.map(\.minutes).reduce(0, +) / Double(nights.count)
        let onsetMinutesOfDay = nights.map { minutesSinceMidnight($0.onset, calendar: calendar) }
        let wakeMinutesOfDay = nights.map { minutesSinceMidnight($0.wake, calendar: calendar) }

        let avgOnsetMinutes = circularAverageMinutes(onsetMinutesOfDay)
        let avgWakeMinutes = circularAverageMinutes(wakeMinutesOfDay)
        let stability = routineStabilityIndex(fromCircularMinutes: onsetMinutesOfDay)

        return SleepMetrics(
            chronotype: chronotype(forSleepMidpointMinutes: sleepMidpointMinutes(onset: avgOnsetMinutes, wake: avgWakeMinutes)),
            sleepStartLocal: hhmm(fromMinutesSinceMidnight: avgOnsetMinutes),
            sleepEndLocal: hhmm(fromMinutesSinceMidnight: avgWakeMinutes),
            avgDurationMinutes: Int(avgDuration.rounded()),
            routineStabilityIndex: stability
        )
    }

    /// Onset clock time is circular (23:50 and 00:10 are 20 minutes apart, not
    /// 23h40m) — shift times after noon back by 24h before averaging/measuring
    /// spread, which is the simple, defensible approximation for a population
    /// that mostly falls asleep in the evening/night window.
    private static func minutesSinceMidnight(_ date: Date, calendar: Calendar) -> Double {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let minutes = Double((components.hour ?? 0) * 60 + (components.minute ?? 0))
        return minutes < 12 * 60 ? minutes + 24 * 60 : minutes
    }

    private static func circularAverageMinutes(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        let sum = values.reduce(0, +)
        return (sum / Double(values.count)).truncatingRemainder(dividingBy: 24 * 60)
    }

    private static func routineStabilityIndex(fromCircularMinutes values: [Double]) -> Double? {
        guard values.count > 1 else { return nil }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        let stddevMinutes = variance.squareRoot()
        // 0 minutes variance -> 1.0 (perfectly regular); 180+ minutes -> 0.0 (chaotic).
        return max(0, min(1, 1 - stddevMinutes / 180))
    }

    private static func sleepMidpointMinutes(onset: Double, wake: Double) -> Double {
        let wakeAdjusted = wake < onset ? wake + 24 * 60 : wake
        return ((onset + wakeAdjusted) / 2).truncatingRemainder(dividingBy: 24 * 60)
    }

    /// Midpoint before 03:30 -> early bird, after 04:30 -> night owl, else intermediate.
    private static func chronotype(forSleepMidpointMinutes midpoint: Double) -> Chronotype {
        let normalized = midpoint > 12 * 60 ? midpoint - 24 * 60 : midpoint
        if normalized < 3 * 60 + 30 { return .earlyBird }
        if normalized > 4 * 60 + 30 { return .nightOwl }
        return .intermediate
    }

    private static func hhmm(fromMinutesSinceMidnight minutes: Double) -> String {
        let normalized = Int(minutes.rounded()) % (24 * 60)
        let hour = normalized / 60
        let minute = normalized % 60
        return String(format: "%02d:%02d", hour, minute)
    }

    // MARK: - Activity

    private static func dailyAverage(of samples: [HKQuantitySample], over days: Int) -> Double {
        guard !samples.isEmpty else { return 0 }
        let total = samples.reduce(0.0) { $0 + $1.quantity.doubleValue(for: .count()) }
        return total / Double(days)
    }

    private static func activityLevel(fromDailyAverageSteps steps: Double) -> ActivityLevel {
        if steps < 5000 { return .low }
        if steps < 10000 { return .medium }
        return .high
    }

    private struct PeakWindow {
        let startLocal: String
        let endLocal: String
    }

    /// Buckets active-energy samples by hour of day across the whole window and
    /// returns the 2-hour span with the highest average energy.
    private static func peakEnergyWindow(from samples: [HKQuantitySample]) -> PeakWindow? {
        guard !samples.isEmpty else { return nil }
        let calendar = Calendar.current
        var totalsByHour = [Double](repeating: 0, count: 24)

        for sample in samples {
            let hour = calendar.component(.hour, from: sample.startDate)
            totalsByHour[hour] += sample.quantity.doubleValue(for: .kilocalorie())
        }

        var bestStartHour = 0
        var bestTotal = -Double.infinity
        for hour in 0..<24 {
            let windowTotal = totalsByHour[hour] + totalsByHour[(hour + 1) % 24]
            if windowTotal > bestTotal {
                bestTotal = windowTotal
                bestStartHour = hour
            }
        }
        guard bestTotal > 0 else { return nil }

        let endHour = (bestStartHour + 2) % 24
        return PeakWindow(
            startLocal: String(format: "%02d:00", bestStartHour),
            endLocal: String(format: "%02d:00", endHour)
        )
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar(identifier: .gregorian)
        return formatter
    }()
}
