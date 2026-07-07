# frozen_string_literal: true

require "test_helper"

class HealthSummaryContractTest < ActiveSupport::TestCase
  def contract
    HealthSummaryContract.new
  end

  def valid_params
    {
      health_summary: {
        effective_from: "2026-05-01",
        chronotype: "early_bird",
        source: "apple_health",
        avg_sleep_duration_minutes: 450,
        routine_stability_index: 0.82,
        activity_level: "medium",
        recovery_score: "medium",
        sleep_start_local: "23:00",
        sleep_end_local: "07:00",
        peak_energy_start_local: "09:00",
        peak_energy_end_local: "12:00"
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

  # --- effective_from ---

  test "missing effective_from returns failure" do
    params = valid_params.deep_dup
    params[:health_summary].delete(:effective_from)
    assert contract.call(params).failure?
  end

  test "blank effective_from returns failure" do
    params = valid_params.deep_dup
    params[:health_summary][:effective_from] = ""
    assert contract.call(params).failure?
  end

  # --- effective_to rule ---

  test "effective_to before effective_from returns failure" do
    params = valid_params.deep_dup
    params[:health_summary][:effective_to] = "2026-01-01"
    result = contract.call(params)
    assert result.failure?
    assert_includes result.errors.to_h.dig(:health_summary, :effective_to),
      I18n.t("contracts.errors.effective_to.after_effective_from")
  end

  # --- chronotype ---

  test "invalid chronotype returns failure" do
    params = valid_params.deep_dup
    params[:health_summary][:chronotype] = "morning"
    assert contract.call(params).failure?
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

  # --- activity_level ---

  test "invalid activity_level returns failure" do
    params = valid_params.deep_dup
    params[:health_summary][:activity_level] = "extreme"
    assert contract.call(params).failure?
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

  # --- recovery_score ---

  test "invalid recovery_score returns failure" do
    params = valid_params.deep_dup
    params[:health_summary][:recovery_score] = "extreme"
    assert contract.call(params).failure?
  end

  test "recovery_score medium is valid" do
    params = valid_params.deep_dup
    params[:health_summary][:recovery_score] = "medium"
    assert contract.call(params).success?
  end

  # --- source ---

  test "invalid source returns failure" do
    params = valid_params.deep_dup
    params[:health_summary][:source] = "garmin"
    assert contract.call(params).failure?
  end

  test "source apple_health is valid" do
    params = valid_params.deep_dup
    params[:health_summary][:source] = "apple_health"
    assert contract.call(params).success?
  end

  test "source health_connect is valid" do
    params = valid_params.deep_dup
    params[:health_summary][:source] = "health_connect"
    assert contract.call(params).success?
  end

  # --- numeric bounds ---

  test "avg_sleep_duration_minutes zero returns failure" do
    params = valid_params.deep_dup
    params[:health_summary][:avg_sleep_duration_minutes] = 0
    assert contract.call(params).failure?
  end

  test "avg_sleep_duration_minutes positive returns success" do
    params = valid_params.deep_dup
    params[:health_summary][:avg_sleep_duration_minutes] = 1
    assert contract.call(params).success?
  end

  test "routine_stability_index below 0 returns failure" do
    params = valid_params.deep_dup
    params[:health_summary][:routine_stability_index] = -0.1
    assert contract.call(params).failure?
  end

  test "routine_stability_index above 1 returns failure" do
    params = valid_params.deep_dup
    params[:health_summary][:routine_stability_index] = 1.1
    assert contract.call(params).failure?
  end

  test "routine_stability_index at boundaries 0.0 and 1.0 returns success" do
    params = valid_params.deep_dup
    params[:health_summary][:routine_stability_index] = 0.0
    assert contract.call(params).success?

    params[:health_summary][:routine_stability_index] = 1.0
    assert contract.call(params).success?
  end
end
