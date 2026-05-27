# frozen_string_literal: true

# Computes a weighted compatibility score (0-100) between two HealthSummary records.
# Domains and weights are defined in docs/product/matching.md.
class CompatibilityService
  WEIGHT_SLEEP       = 0.35
  WEIGHT_ACTIVITY    = 0.30
  WEIGHT_LIFESTYLE   = 0.20
  WEIGHT_PREFERENCES = 0.15

  # Numeric value for each chronotype used to measure distance.
  CHRONOTYPE_VALUE = {
    "early_bird"   => 0,
    "intermediate" => 1,
    "night_owl"    => 2
  }.freeze

  # Numeric value for each activity level used to measure distance.
  ACTIVITY_LEVEL_VALUE = {
    "low"    => 0,
    "medium" => 1,
    "high"   => 2
  }.freeze

  Result = Data.define(:total, :sleep, :activity, :lifestyle, :preferences)

  def self.call(first_health_summary, second_health_summary)
    new(first_health_summary, second_health_summary).call
  end

  def initialize(first_health_summary, second_health_summary)
    @first  = first_health_summary
    @second = second_health_summary
  end

  def call
    sleep_score       = compute_sleep_score
    activity_score    = compute_activity_score
    lifestyle_score   = compute_lifestyle_score
    preferences_score = compute_preferences_score

    total = (
      sleep_score       * WEIGHT_SLEEP       +
      activity_score    * WEIGHT_ACTIVITY    +
      lifestyle_score   * WEIGHT_LIFESTYLE   +
      preferences_score * WEIGHT_PREFERENCES
    ).round(2)

    Result.new(
      total:       total,
      sleep:       sleep_score,
      activity:    activity_score,
      lifestyle:   lifestyle_score,
      preferences: preferences_score
    )
  end

  private

    # Sleep domain (35%) — chronotype alignment + sleep duration proximity
    def compute_sleep_score
      chronotype_score      = score_from_enum_distance(CHRONOTYPE_VALUE, @first.chronotype, @second.chronotype, max_distance: 2)
      sleep_duration_score  = score_from_minute_difference(@first.avg_sleep_duration_minutes, @second.avg_sleep_duration_minutes, max_diff: 180)

      average(chronotype_score, sleep_duration_score)
    end

    # Activity domain (30%) — activity level alignment
    def compute_activity_score
      score_from_enum_distance(ACTIVITY_LEVEL_VALUE, @first.activity_level, @second.activity_level, max_distance: 2)
    end

    # Lifestyle domain (20%) — routine stability proximity
    def compute_lifestyle_score
      score_from_float_difference(
        @first.routine_stability_index,
        @second.routine_stability_index,
        max_diff: 1.0
      )
    end

    # Preferences domain (15%) — reserved for dealbreakers and stated preferences.
    # Returns 100 for MVP since PreferenceProfile filtering happens upstream in MatchingService.
    def compute_preferences_score
      100
    end

    # Converts an enum distance into a 0-100 score.
    # Distance 0 → 100, distance max_distance → 0.
    def score_from_enum_distance(value_map, first_value, second_value, max_distance:)
      first_numeric  = value_map[first_value.to_s]  || 0
      second_numeric = value_map[second_value.to_s] || 0
      distance       = (first_numeric - second_numeric).abs
      ((1.0 - distance.to_f / max_distance) * 100).clamp(0, 100).round(2)
    end

    # Converts a difference in minutes into a 0-100 score.
    # Returns 100 when either value is nil (no penalty for missing data).
    def score_from_minute_difference(first_minutes, second_minutes, max_diff:)
      return 100 if first_minutes.nil? || second_minutes.nil?

      diff = (first_minutes - second_minutes).abs
      ((1.0 - diff.to_f / max_diff) * 100).clamp(0, 100).round(2)
    end

    # Converts a float difference (0.0–1.0 range) into a 0-100 score.
    # Returns 100 when either value is nil (no penalty for missing data).
    def score_from_float_difference(first_value, second_value, max_diff:)
      return 100 if first_value.nil? || second_value.nil?

      diff = (first_value - second_value).abs
      ((1.0 - diff.to_f / max_diff) * 100).clamp(0, 100).round(2)
    end

    def average(*scores)
      scores.sum.to_f / scores.size
    end
end
