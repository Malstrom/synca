# frozen_string_literal: true

require "test_helper"

class Api::V1::Signals::SummaryControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user    = users(:alice)
    @health  = health_summaries(:alice_health)
    @headers = { "Authorization" => "Bearer #{JwtService.encode(user_id: @user.id)}" }
  end

  test "GET /api/v1/signals/me/summary returns 200 with correct payload" do
    get api_v1_signals_me_summary_path, headers: @headers

    assert_response :success
    summary = response.parsed_body["summary"]

    assert_equal Chronotype.label(@health.chronotype),                           summary["chronotype_label"]
    assert_equal Chronotype.routine_stability_tier(@health.routine_stability_index), summary["routine_stability_tier"]
    assert_equal @health.activity_level,                                         summary["activity_tier"]
    assert_equal @health.avg_sleep_duration_minutes,                             summary["avg_sleep_duration_minutes"]
    assert_nil   summary["peak_energy_window"]
  end

  test "GET /api/v1/signals/me/summary returns self_report_alignment aligned for alice" do
    get api_v1_signals_me_summary_path, headers: @headers

    alignment = response.parsed_body.dig("summary", "self_report_alignment")
    assert_equal true, alignment["aligned"]
    assert_nil alignment["note"]
  end

  test "GET /api/v1/signals/me/summary without active health_summary returns 404" do
    @health.update!(effective_to: Time.current)
    get api_v1_signals_me_summary_path, headers: @headers

    assert_response :not_found
    assert_equal "no_signals",                          response.parsed_body["code"]
    assert_equal I18n.t("signals_summary.no_signals"),  response.parsed_body["message"]
  end

  test "GET /api/v1/signals/me/summary without auth returns 401" do
    get api_v1_signals_me_summary_path

    assert_response :unauthorized
  end
end
