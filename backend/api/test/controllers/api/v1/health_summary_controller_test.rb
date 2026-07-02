# frozen_string_literal: true

require "test_helper"

class Api::V1::HealthSummaryControllerTest < ApiTestCase
  setup do
    @user = users(:alice)
    @headers = auth_headers(@user)

    @valid_params = {
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

  def parsed_health_summary
    JSON.parse(json[:health_summary], symbolize_names: true)
  end

  # --- happy path ---

  test "PUT /me/health_summary returns 200 with health_summary payload" do
    put_json "/api/v1/me/health_summary",
      params: @valid_params,
      headers: @headers

    assert_response :ok
    payload = parsed_health_summary
    assert_equal "early_bird", payload[:chronotype]
    assert_equal 450, payload[:avg_sleep_duration_minutes]
    assert_in_delta 0.82, payload[:routine_stability_index], 0.001
  end

  test "PUT /me/health_summary creates record when user has none" do
    @user.health_summary.destroy

    put_json "/api/v1/me/health_summary",
      params: @valid_params,
      headers: @headers

    assert_response :ok
    payload = parsed_health_summary
    assert_equal "early_bird", payload[:chronotype]
    assert_equal "apple_health", payload[:source]
  end

  test "PUT /me/health_summary persists updated values in db" do
    put_json "/api/v1/me/health_summary",
      params: { health_summary: @valid_params[:health_summary].merge(chronotype: "night_owl") },
      headers: @headers

    assert_response :ok
    assert_equal "night_owl", @user.health_summary.reload.chronotype
  end

  test "PUT /me/health_summary response contains all expected keys" do
    put_json "/api/v1/me/health_summary",
      params: @valid_params,
      headers: @headers

    payload = parsed_health_summary
    %i[
      chronotype source effective_from effective_to
      avg_sleep_duration_minutes routine_stability_index
      activity_level recovery_score
      sleep_start_local sleep_end_local
      peak_energy_start_local peak_energy_end_local
    ].each { |key| assert payload.key?(key), "missing key: #{key}" }
  end

  test "PUT /me/health_summary with only required field returns 200" do
    put_json "/api/v1/me/health_summary",
      params: { health_summary: { effective_from: "2026-06-01" } },
      headers: @headers

    assert_response :ok
  end

  # --- contract validation errors (caught before service) ---

  test "PUT /me/health_summary without effective_from returns 422 with validation_failed" do
    params = @valid_params.deep_dup
    params[:health_summary].delete(:effective_from)

    put_json "/api/v1/me/health_summary",
      params: params,
      headers: @headers

    assert_response :unprocessable_entity
    assert_equal "validation_failed", json.dig(:error, :code)
  end

  test "PUT /me/health_summary with invalid chronotype returns 422" do
    put_json "/api/v1/me/health_summary",
      params: { health_summary: @valid_params[:health_summary].merge(chronotype: "invalid") },
      headers: @headers

    assert_response :unprocessable_entity
    assert_equal "validation_failed", json.dig(:error, :code)
    assert json.dig(:error, :field).present?
  end

  test "PUT /me/health_summary with invalid activity_level returns 422" do
    put_json "/api/v1/me/health_summary",
      params: { health_summary: @valid_params[:health_summary].merge(activity_level: "extreme") },
      headers: @headers

    assert_response :unprocessable_entity
    assert_equal "validation_failed", json.dig(:error, :code)
  end

  # --- service validation errors (model-level, caught after contract) ---

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

  # --- auth ---

  test "PUT /me/health_summary without token returns 401" do
    put_json "/api/v1/me/health_summary", params: @valid_params
    assert_response :unauthorized
  end
end
