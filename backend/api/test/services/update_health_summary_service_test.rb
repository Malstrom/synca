# frozen_string_literal: true

require "test_helper"

# UpdateHealthSummaryService receives already-validated attrs from HealthSummaryContract.
# Failure scenarios (invalid enum values, out-of-range numerics) are tested in
# health_summary_contract_test.rb and health_summary_controller_test.rb.
class UpdateHealthSummaryServiceTest < ActiveSupport::TestCase
  include Dry::Monads[:result]

  setup do
    @user = users(:alice)
  end

  def valid_attrs
    {
      effective_from:             Date.parse("2026-05-01"),
      chronotype:                 "early_bird",
      source:                     "apple_health",
      avg_sleep_duration_minutes: 450,
      routine_stability_index:    0.82,
      activity_level:             "medium",
      recovery_score:             "medium"
    }
  end

  test "returns Success with the health_summary record on valid attrs" do
    result = UpdateHealthSummaryService.call(current_user: @user, attrs: valid_attrs)
    assert result.success?, "expected Success, got #{result.inspect}"
  end

  test "Success wraps the persisted HealthSummary" do
    result = UpdateHealthSummaryService.call(current_user: @user, attrs: valid_attrs)
    assert result.success?, "expected Success, got #{result.inspect}"

    health_summary = result.value!
    assert_instance_of HealthSummary, health_summary
    assert health_summary.persisted?
  end

  test "updates an existing health_summary" do
    result = UpdateHealthSummaryService.call(
      current_user: @user,
      attrs: valid_attrs.merge(chronotype: "night_owl")
    )

    assert result.success?, "expected Success, got #{result.inspect}"
    assert_equal "night_owl", result.value!.reload.chronotype
  end

  test "creates health_summary when user has none" do
    user_without_summary = users(:charlie)

    result = UpdateHealthSummaryService.call(current_user: user_without_summary, attrs: valid_attrs)
    assert result.success?, "expected Success, got #{result.inspect}"
    assert result.value!.persisted?
  end
end
