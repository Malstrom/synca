# frozen_string_literal: true

require "test_helper"

class Api::V1::Signals::SummaryControllerTest < ApiTestCase
  setup do
    @user = users(:alice)
    @headers = auth_headers(@user)
  end

  test "success" do
    get api_v1_signals_me_summary_path, headers: @headers

    assert_response :success
    assert_equal "Early bird", response.parsed_body["summary"]["chronotype_label"]
    assert_equal "06:00–08:00", response.parsed_body["summary"]["peak_energy_window"]
    assert_equal "high", response.parsed_body["summary"]["routine_stability_tier"]
    assert_equal "medium", response.parsed_body["summary"]["activity_tier"]
    assert_equal 437, response.parsed_body["summary"]["avg_sleep_duration_minutes"]
    assert_equal false, response.parsed_body["summary"]["self_report_alignment"]["aligned"]
    assert response.parsed_body["summary"]["self_report_alignment"]["note"].present?
  end

  test "no health summary" do
    user = users(:bob)
    headers = auth_headers(user)

    get api_v1_signals_me_summary_path, headers: headers

    assert_response :not_found
    assert_equal "no_signals", response.parsed_body["error"]["code"]
  end

  test "unauthorized" do
    get api_v1_signals_me_summary_path

    assert_response :unauthorized
  end
end