# frozen_string_literal: true

require "test_helper"

class CompatibilityServiceTest < ActiveSupport::TestCase
  setup do
    @alice_health = health_summaries(:alice_health)
    @bob_health   = health_summaries(:bob_health)
  end

  # --- result shape ---

  test "returns a result with total score and four domain scores" do
    result = CompatibilityService.call(@alice_health, @bob_health)

    assert_respond_to result, :total
    assert_respond_to result, :sleep
    assert_respond_to result, :activity
    assert_respond_to result, :lifestyle
    assert_respond_to result, :preferences
  end

  test "total score is between 0 and 100" do
    result = CompatibilityService.call(@alice_health, @bob_health)

    assert_operator result.total, :>=, 0
    assert_operator result.total, :<=, 100
  end

  test "all domain scores are between 0 and 100" do
    result = CompatibilityService.call(@alice_health, @bob_health)

    [ result.sleep, result.activity, result.lifestyle, result.preferences ].each do |score|
      assert_operator score, :>=, 0
      assert_operator score, :<=, 100
    end
  end

  test "total is the weighted sum of domain scores" do
    result = CompatibilityService.call(@alice_health, @bob_health)

    expected_total = (
      result.sleep       * CompatibilityService::WEIGHT_SLEEP       +
      result.activity    * CompatibilityService::WEIGHT_ACTIVITY    +
      result.lifestyle   * CompatibilityService::WEIGHT_LIFESTYLE   +
      result.preferences * CompatibilityService::WEIGHT_PREFERENCES
    ).round(2)

    assert_in_delta expected_total, result.total, 0.01
  end

  test "weights sum to 1.0" do
    total_weight = CompatibilityService::WEIGHT_SLEEP +
                   CompatibilityService::WEIGHT_ACTIVITY +
                   CompatibilityService::WEIGHT_LIFESTYLE +
                   CompatibilityService::WEIGHT_PREFERENCES

    assert_in_delta 1.0, total_weight, 0.0001
  end

  # --- sleep domain ---

  test "sleep score is 100 when both users have identical chronotype and sleep duration" do
    identical_health = build_health_summary(
      chronotype: "early_bird",
      avg_sleep_duration_minutes: 480,
      routine_stability_index: 0.9,
      sleep_start_local: Time.zone.parse("2000-01-01 22:00"),
      sleep_end_local:   Time.zone.parse("2000-01-01 06:00")
    )

    result = CompatibilityService.call(identical_health, identical_health)

    assert_equal 100, result.sleep
  end

  test "sleep score is lower when chronotypes differ" do
    early_bird_health = build_health_summary(chronotype: "early_bird", avg_sleep_duration_minutes: 480)
    night_owl_health  = build_health_summary(chronotype: "night_owl",  avg_sleep_duration_minutes: 480)

    result_same     = CompatibilityService.call(early_bird_health, early_bird_health)
    result_opposite = CompatibilityService.call(early_bird_health, night_owl_health)

    assert_operator result_same.sleep, :>, result_opposite.sleep
  end

  test "sleep score penalizes large difference in avg_sleep_duration_minutes" do
    short_sleep_health = build_health_summary(chronotype: "intermediate", avg_sleep_duration_minutes: 300)
    long_sleep_health  = build_health_summary(chronotype: "intermediate", avg_sleep_duration_minutes: 600)

    result_same  = CompatibilityService.call(short_sleep_health, short_sleep_health)
    result_diff  = CompatibilityService.call(short_sleep_health, long_sleep_health)

    assert_operator result_same.sleep, :>, result_diff.sleep
  end

  # --- activity domain ---

  test "activity score is 100 when both users have identical activity_level" do
    same_activity_health = build_health_summary(chronotype: "intermediate", activity_level: "high")

    result = CompatibilityService.call(same_activity_health, same_activity_health)

    assert_equal 100, result.activity
  end

  test "activity score is lower when activity levels differ" do
    high_activity_health = build_health_summary(chronotype: "intermediate", activity_level: "high")
    low_activity_health  = build_health_summary(chronotype: "intermediate", activity_level: "low")

    result_same = CompatibilityService.call(high_activity_health, high_activity_health)
    result_diff = CompatibilityService.call(high_activity_health, low_activity_health)

    assert_operator result_same.activity, :>, result_diff.activity
  end

  # --- lifestyle domain ---

  test "lifestyle score is 100 when both users have identical routine_stability_index" do
    stable_health = build_health_summary(
      chronotype: "intermediate",
      routine_stability_index: 0.9
    )

    result = CompatibilityService.call(stable_health, stable_health)

    assert_equal 100, result.lifestyle
  end

  test "lifestyle score is lower when routine_stability_index differs significantly" do
    stable_health   = build_health_summary(chronotype: "intermediate", routine_stability_index: 0.95)
    unstable_health = build_health_summary(chronotype: "intermediate", routine_stability_index: 0.1)

    result_same = CompatibilityService.call(stable_health, stable_health)
    result_diff = CompatibilityService.call(stable_health, unstable_health)

    assert_operator result_same.lifestyle, :>, result_diff.lifestyle
  end

  # --- nil safety ---

  test "handles nil routine_stability_index gracefully" do
    health_without_stability = build_health_summary(
      chronotype: "intermediate",
      routine_stability_index: nil
    )

    result = CompatibilityService.call(health_without_stability, health_without_stability)

    assert_operator result.total, :>=, 0
    assert_operator result.total, :<=, 100
  end

  test "handles nil avg_sleep_duration_minutes gracefully" do
    health_without_sleep_duration = build_health_summary(
      chronotype: "early_bird",
      avg_sleep_duration_minutes: nil
    )

    result = CompatibilityService.call(health_without_sleep_duration, health_without_sleep_duration)

    assert_operator result.total, :>=, 0
    assert_operator result.total, :<=, 100
  end

  # --- symmetry ---

  test "score is symmetric: call(a, b) == call(b, a)" do
    result_ab = CompatibilityService.call(@alice_health, @bob_health)
    result_ba = CompatibilityService.call(@bob_health, @alice_health)

    assert_in_delta result_ab.total, result_ba.total, 0.01
  end

  private

    def build_health_summary(attributes)
      HealthSummary.new(
        {
          source:         "apple_health",
          effective_from: Date.today,
          activity_level: "medium",
          recovery_score: "medium"
        }.merge(attributes)
      )
    end
end
