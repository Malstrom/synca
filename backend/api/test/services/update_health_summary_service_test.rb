# frozen_string_literal: true

require "test_helper"

class UpdateHealthSummaryServiceTest < ActiveSupport::TestCase
  include Dry::Monads[:result]

  setup do
    @user = users(:alice)
  end

  def valid_attrs
    {
      effective_from: Date.parse("2026-05-01"),
      chronotype: "early_bird",
      source: "apple_health",
      avg_sleep_duration_minutes: 450,
      routine_stability_index: 0.82,
      activity_level: "medium",
      recovery_score: "medium"
    }
  end

  # --- Success path ---

  test "returns Success with the health_summary record on valid attrs" do
    result = UpdateHealthSummaryService.call(current_user: @user, attrs: valid_attrs)
    assert_pattern { result => Success }
  end

  test "Success wraps the persisted HealthSummary" do
    result = UpdateHealthSummaryService.call(current_user: @user, attrs: valid_attrs)
    assert_pattern { result => Success[hs] }
    assert_instance_of HealthSummary, hs
    assert hs.persisted?
  end

  test "updates an existing health_summary" do
    result = UpdateHealthSummaryService.call(
      current_user: @user,
      attrs: valid_attrs.merge(chronotype: "night_owl")
    )
    assert_pattern { result => Success[hs] }
    assert_equal "night_owl", hs.reload.chronotype
  end

  test "creates health_summary when user has none" do
    user_without_summary = users(:charlie)
    result = UpdateHealthSummaryService.call(current_user: user_without_summary, attrs: valid_attrs)
    assert_pattern { result => Success[hs] }
    assert hs.persisted?
  end

  # --- Failure path ---

  test "returns Failure(:validation_failed) when model validation fails" do
    result = UpdateHealthSummaryService.call(
      current_user: @user,
      attrs: valid_attrs.merge(avg_sleep_duration_minutes: -1)
    )
    assert_pattern { result => Failure[:validation_failed, _] }
  end

  test "Failure carries a non-blank error message" do
    result = UpdateHealthSummaryService.call(
      current_user: @user,
      attrs: valid_attrs.merge(avg_sleep_duration_minutes: -1)
    )
    assert_pattern { result => Failure[:validation_failed, message] }
    assert message.present?
  end
end
