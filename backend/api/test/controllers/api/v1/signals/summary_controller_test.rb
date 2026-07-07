# frozen_string_literal: true

require "test_helper"

class Api::V1::Signals::SummaryControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:alice)
    @health_summary = health_summaries(:alice_health)
    @preference_profile = preference_profiles(:alice_preferences)
    @headers = { "Authorization" => "Bearer #{JwtService.encode(user_id: @user.id)}" }
  end

  test "GET /api/v1/signals/me/summary with active health_summary → 200" do
    get api_v1_signals_me_summary_path, headers: @headers

    assert_response :success

    expected_window = "#{@health_summary.peak_energy_start_local}–#{@health_summary.peak_energy_end_local}"
    assert_equal expected_window, response.parsed_body.dig("summary", "peak_energy_window")
    assert_equal @health_summary.avg_sleep_duration_minutes, response.parsed_body.dig("summary", "avg_sleep_duration_minutes")
    assert_equal @health_summary.activity_level, response.parsed_body.dig("summary", "activity_tier")

    case @health_summary.chronotype
    when "early_bird" then expected_label = "Early bird"
    when "intermediate" then expected_label = "Flexible"
    when "night_owl" then expected_label = "Night owl"
    end
    assert_equal expected_label, response.parsed_body.dig("summary", "chronotype_label")

    case @health_summary.routine_stability_index
    when 0.0...0.4 then expected_tier = "low"
    when 0.4...0.7 then expected_tier = "medium"
    when 0.7..1.0 then expected_tier = "high"
    end
    assert_equal expected_tier, response.parsed_body.dig("summary", "routine_stability_tier")

    if @preference_profile.self_chronotype.present?
      expected_aligned = @preference_profile.self_chronotype == "depends" ||
                         chronotype_mapping(@preference_profile.self_chronotype) == @health_summary.chronotype
      assert_equal expected_aligned, response.parsed_body.dig("summary", "self_report_alignment", "aligned")

      unless expected_aligned
        assert_equal I18n.t("self_report_alignment.note",
          self_chronotype: self_chronotype_label(@preference_profile.self_chronotype),
          chronotype: expected_label),
          response.parsed_body.dig("summary", "self_report_alignment", "note")
      end
    else
      assert_nil response.parsed_body.dig("summary", "self_report_alignment")
    end
  end

  test "GET /api/v1/signals/me/summary without active health_summary → 404" do
    @health_summary.update!(effective_to: Time.current)
    get api_v1_signals_me_summary_path, headers: @headers

    assert_response :not_found
    assert_equal "no_signals", response.parsed_body["code"]
    assert_equal I18n.t("signals_summary.no_signals"), response.parsed_body["message"]
  end

  test "GET /api/v1/signals/me/summary without auth → 401" do
    get api_v1_signals_me_summary_path

    assert_response :unauthorized
  end

  private

    def chronotype_mapping(self_chronotype)
      case self_chronotype
      when "morning" then "early_bird"
      when "night" then "night_owl"
      end
    end

    def self_chronotype_label(self_chronotype)
      case self_chronotype
      when "morning" then "morning"
      when "night" then "night"
      when "depends" then "depends"
      end
    end
end