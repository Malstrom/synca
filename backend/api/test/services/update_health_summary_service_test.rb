# frozen_string_literal: true

require "test_helper"

class UpdateHealthSummaryServiceTest < ActiveSupport::TestCase
  include Dry::Monads[:result]

  setup do
    @user = users(:alice)
  end

  def valid_params
    {
      "health_summary" => {
        "effective_from"             => "2026-05-01",
        "chronotype"                 => "early_bird",
        "source"                     => "apple_health",
        "avg_sleep_duration_minutes" => 450,
        "routine_stability_index"    => 0.82,
        "activity_level"             => "medium",
        "recovery_score"             => "medium"
      }
    }
  end

  test "returns Success with the health_summary record on valid params" do
    result = UpdateHealthSummaryService.call(current_user: @user, params: valid_params)
    assert result.success?, "expected Success, got #{result.inspect}"
  end

  test "Success wraps the persisted HealthSummary" do
    result = UpdateHealthSummaryService.call(current_user: @user, params: valid_params)
    assert result.success?
    assert_instance_of HealthSummary, result.value!
    assert result.value!.persisted?
  end

  test "updates an existing health_summary" do
    params = valid_params.deep_merge("health_summary" => { "chronotype" => "night_owl" })
    result = UpdateHealthSummaryService.call(current_user: @user, params: params)
    assert result.success?
    assert_equal "night_owl", result.value!.reload.chronotype
  end

  test "creates health_summary when user has none" do
    result = UpdateHealthSummaryService.call(current_user: users(:charlie), params: valid_params)
    assert result.success?
    assert result.value!.persisted?
  end

  test "contract invalid — unknown chronotype" do
    params = valid_params.deep_merge("health_summary" => { "chronotype" => "vampire" })
    result = UpdateHealthSummaryService.call(current_user: @user, params: params)
    assert result.failure?
    assert_equal :contract_invalid, result.failure.first
  end
end
