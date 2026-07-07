# frozen_string_literal: true

require "test_helper"

class Api::V1::Signals::SummaryControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:alice)
    @health_summary = health_summaries(:alice_health)
    @preference_profile = preference_profiles(:alice_preferences)
    @token = JwtService.encode(user_id: @user.id)
  end

  test "GET /api/v1/signals/me/summary with active health_summary → 200" do
    get api_v1_signals_me_summary_path, headers: { "Authorization" => "Bearer #{@token}" }

    assert_response :success

    expected_window = "#{@health_summary.peak_energy_start_local}–#{@health_summary.peak_energy_end_local}"
    assert_equal expected_window, response.parsed_body.dig("summary", "peak_energy_window")
    assert_equal @health_summary.avg_sleep_duration_minutes, response.parsed_body.dig("summary", "avg_sleep_duration_minutes")
    assert_equal @health_summary.activity_level, response.parsed_body.dig("summary", "activity_tier")

    assert_equal I18n.t("chronotype_labels.#{@health_summary.chronotype}"),
                 response.parsed_body.dig("summary", "chronotype_label")

    case @health_summary.routine_stability_index
    when 0.0...0.4
      assert_equal "low", response.parsed_body.dig("summary", "routine_stability_tier")
    when 0.4...0.7
      assert_equal "medium", response.parsed_body.dig("summary", "routine_stability_tier")
    when 0.7..1.0
      assert_equal "high", response.parsed_body.dig("summary", "routine_stability_tier")
    end

    if @preference_profile.self_chronotype.present?
      expected_aligned = @preference_profile.self_chronotype == "depends" ||
                         (@preference_profile.self_chronotype == "morning" && @health_summary.chronotype == "early_bird") ||
                         (@preference_profile.self_chronotype == "night" && @health_summary.chronotype == "night_owl")

      assert_equal expected_aligned, response.parsed_body.dig("summary", "self_report_alignment", "aligned")

      unless expected_aligned
        assert_equal I18n.t("self_report_alignment.note",
                            self_chronotype: I18n.t("self_chronotype_labels.#{@preference_profile.self_chronotype}"),
                            chronotype: I18n.t("chronotype_labels.#{@health_summary.chronotype}")),
                     response.parsed_body.dig("summary", "self_report_alignment", "note")
      end
    else
      assert_nil response.parsed_body.dig("summary", "self_report_alignment")
    end
  end

  test "GET /api/v1/signals/me/summary with no active health_summary → 404" do
    @health_summary.update!(effective_to: Time.current)
    get api_v1_signals_me_summary_path, headers: { "Authorization" => "Bearer #{@token}" }

    assert_response :not_found
    assert_equal "no_signals", response.parsed_body["code"]
    assert_equal I18n.t("signals_summary.no_signals"), response.parsed_body["message"]
  end

  test "GET /api/v1/signals/me/summary without auth → 401" do
    get api_v1_signals_me_summary_path
    assert_response :unauthorized
  end
end
