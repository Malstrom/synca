# frozen_string_literal: true

require "test_helper"

class HealthSummaryContractTest < ActiveSupport::TestCase
  def contract
    HealthSummaryContract.new
  end

  def valid_params
    {
      health_summary: {
        effective_from:             "2026-05-01",
        chronotype:                 "early_bird",
        source:                     "apple_health",
        avg_sleep_duration_minutes: 450,
        routine_stability_index:    0.82,
        activity_level:             "medium",
        recovery_score:             "medium",
        sleep_start_local:          "23:00",
        sleep_end_local:            "07:00",
        peak_energy_start_local:    "09:00",
        peak_energy_end_local:      "12:00"
      }
    }
  end

  # --- happy path ---

  test "valid params with all fields returns success" do
    result = contract.call(valid_params)
    assert result.success?
  end

  test "valid params with only required fields returns success" do
    result = contract.call({ health_summary: { effective_from: "2026-06-01" } })
    assert result.success?
  end

  test "coerces effective_from string to Date" do
    result = contract.call(valid_params)
    assert_instance_of Date, result.to_h[:health_summary][:effective_from]
  end

  test "coerces effective_to string to Date when present" do
    params = valid_params.deep_dup
    params[:health_summary][:effective_to] = "2026-12-31"
    result = contract.call(params)
    assert result.success?
    assert_instance_of Date, result.to_h[:health_summary][:effective_to]
  end

  test "optional fields may be nil" do
    params = { health_summary: { effective_from: "2026-06-01", chronotype: nil, activity_level: nil, recovery_score: nil } }
    result = contract.call(params)
    assert result.success?
  end

  # --- effective_from validation ---

  test "missing effective_from returns failure" do
    params = valid_params.deep_dup
    params[:health_summary].delete(:effective_from)
    result = contract.call(params)
    assert result.failure?
  end

  test "blank effective_from returns failure" do
    params = valid_params.deep_dup
    params[:health_summary][:effective_from] = ""
    result = contract.call(params)
    assert result.failure?
  end

  # --- chronotype validation ---

  test "invalid chronotype returns failure with descriptive message" do
    params = valid_params.deep_dup
    params[:health_summary][:chronotype] = "morning"
    result = contract.call(params)
    assert result.failure?
    assert_match(/early_bird, intermediate or night_owl/, result.errors.first.text)
  end

  test "chronotype early_bird is valid" do
    params = valid_params.deep_dup
    params[:health_summary][:chronotype] = "early_bird"
    assert contract.call(params).success?
  end

  test "chronotype intermediate is valid" do
    params = valid_params.deep_dup
    params[:health_summary][:chronotype] = "intermediate"
    assert contract.call(params).success?
  end

  test "chronotype night_owl is valid" do
    params = valid_params.deep_dup
    params[:health_summary][:chronotype] = "night_owl"
    assert contract.call(params).success?
  end

  # --- activity_level validation ---

  test "invalid activity_level returns failure" do
    params = valid_params.deep_dup
    params[:health_summary][:activity_level] = "extreme"
    result = contract.call(params)
    assert result.failure?
    assert_match(/low, medium or high/, result.errors.first.text)
  end

  test "activity_level low is valid" do
    params = valid_params.deep_dup
    params[:health_summary][:activity_level] = "low"
    assert contract.call(params).success?
  end

  test "activity_level high is valid" do
    params = valid_params.deep_dup
    params[:health_summary][:activity_level] = "high"
    assert contract.call(params).success?
  end

  # --- recovery_score validation ---

  test "invalid recovery_score returns failure" do
    params = valid_params.deep_dup
    params[:health_summary][:recovery_score] = "extreme"
    result = contract.call(params)
    assert result.failure?
    assert_match(/low, medium or high/, result.errors.first.text)
  end

  test "recovery_score medium is valid" do
    params = valid_params.deep_dup
    params[:health_summary][:recovery_score] = "medium"
    assert contract.call(params).success?
  end
end
