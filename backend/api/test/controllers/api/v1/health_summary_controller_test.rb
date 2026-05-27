# frozen_string_literal: true

require "test_helper"

class Api::V1::HealthSummaryControllerTest < ApiTestCase
  setup do
    @user = users(:alice)
    @headers = auth_headers(@user)
    @valid_params = {
      health_summary: {
        chronotype:                 "early_bird",
        source:                     "apple_health",
        effective_from:             "2026-05-01",
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

  test "PUT /me/health_summary updates existing record and returns 200" do
    put_json "/api/v1/me/health_summary",
      params: @valid_params,
      headers: @headers

    assert_response :ok
    assert_equal "early_bird", json.dig(:health_summary, :chronotype)
    assert_equal 450,          json.dig(:health_summary, :avg_sleep_duration_minutes)
    assert_in_delta 0.82,      json.dig(:health_summary, :routine_stability_index), 0.001
  end

  test "PUT /me/health_summary creates record when it does not exist yet" do
    @user.health_summary.destroy

    put_json "/api/v1/me/health_summary",
      params: @valid_params,
      headers: @headers

    assert_response :ok
    assert_equal "early_bird", json.dig(:health_summary, :chronotype)
    assert_equal "apple_health", json.dig(:health_summary, :source)
  end

  test "PUT /me/health_summary persists the updated values in the database" do
    put_json "/api/v1/me/health_summary",
      params: { health_summary: @valid_params[:health_summary].merge(chronotype: "night_owl") },
      headers: @headers

    assert_response :ok
    assert_equal "night_owl", @user.health_summary.reload.chronotype
  end

  test "PUT /me/health_summary returns full health_summary payload" do
    put_json "/api/v1/me/health_summary",
      params: @valid_params,
      headers: @headers

    assert_response :ok
    payload = json[:health_summary]
    assert payload.key?(:chronotype)
    assert payload.key?(:source)
    assert payload.key?(:effective_from)
    assert payload.key?(:avg_sleep_duration_minutes)
    assert payload.key?(:routine_stability_index)
    assert payload.key?(:activity_level)
    assert payload.key?(:recovery_score)
    assert payload.key?(:sleep_start_local)
    assert payload.key?(:sleep_end_local)
    assert payload.key?(:peak_energy_start_local)
    assert payload.key?(:peak_energy_end_local)
  end

  # --- validation errors ---

  test "PUT /me/health_summary with invalid chronotype returns 422" do
    put_json "/api/v1/me/health_summary",
      params: { health_summary: @valid_params[:health_summary].merge(chronotype: "unknown") },
      headers: @headers

    assert_response :unprocessable_entity
  end

  test "PUT /me/health_summary with negative avg_sleep_duration_minutes returns 422" do
    put_json "/api/v1/me/health_summary",
      params: { health_summary: @valid_params[:health_summary].merge(avg_sleep_duration_minutes: -10) },
      headers: @headers

    assert_response :unprocessable_entity
    assert_equal "validation_failed", json.dig(:error, :code)
  end

  test "PUT /me/health_summary with routine_stability_index above 1 returns 422" do
    put_json "/api/v1/me/health_summary",
      params: { health_summary: @valid_params[:health_summary].merge(routine_stability_index: 1.5) },
      headers: @headers

    assert_response :unprocessable_entity
    assert_equal "validation_failed", json.dig(:error, :code)
  end

  test "PUT /me/health_summary with routine_stability_index below 0 returns 422" do
    put_json "/api/v1/me/health_summary",
      params: { health_summary: @valid_params[:health_summary].merge(routine_stability_index: -0.1) },
      headers: @headers

    assert_response :unprocessable_entity
    assert_equal "validation_failed", json.dig(:error, :code)
  end

  test "PUT /me/health_summary without effective_from returns 422" do
    params_without_date = @valid_params.deep_dup
    params_without_date[:health_summary].delete(:effective_from)

    put_json "/api/v1/me/health_summary",
      params: params_without_date,
      headers: @headers

    assert_response :unprocessable_entity
    assert_equal "validation_failed", json.dig(:error, :code)
  end

  test "PUT /me/health_summary with effective_to before effective_from returns 422" do
    put_json "/api/v1/me/health_summary",
      params: { health_summary: @valid_params[:health_summary].merge(
        effective_from: "2026-05-10",
        effective_to:   "2026-05-01"
      ) },
      headers: @headers

    assert_response :unprocessable_entity
    assert_equal "validation_failed", json.dig(:error, :code)
  end

  # --- auth ---

  test "PUT /me/health_summary without token returns 401" do
    put_json "/api/v1/me/health_summary", params: @valid_params

    assert_response :unauthorized
  end
end
