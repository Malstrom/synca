# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    module Signals
      class SummaryControllerTest < ActionDispatch::IntegrationTest
        setup do
          @user = users(:alice)
          @health_summary = health_summaries(:alice_health)
          @preference_profile = preference_profiles(:alice_preferences)
        end

        test "GET /api/v1/signals/me/summary with health summary" do
          get api_v1_signals_me_summary_path,
            headers: { "Authorization" => "Bearer #{jwt_for(@user)}" }

          assert_response :success
          assert_equal "Early bird", response.parsed_body.dig("summary", "chronotype_label")
          assert_equal "06:00–08:00", response.parsed_body.dig("summary", "peak_energy_window")
          assert_equal "high", response.parsed_body.dig("summary", "routine_stability_tier")
          assert_equal "medium", response.parsed_body.dig("summary", "activity_tier")
          assert_equal 437, response.parsed_body.dig("summary", "avg_sleep_duration_minutes")
          assert_nil response.parsed_body.dig("summary", "self_report_alignment")
        end

        test "GET /api/v1/signals/me/summary with mismatched chronotype" do
          @preference_profile.update!(self_chronotype: "night")

          get api_v1_signals_me_summary_path,
            headers: { "Authorization" => "Bearer #{jwt_for(@user)}" }

          assert_response :success
          assert_equal false, response.parsed_body.dig("summary", "self_report_alignment", "aligned")
          assert_equal "You declared night but your data shows early_bird.", response.parsed_body.dig("summary", "self_report_alignment", "note")
        end

        test "GET /api/v1/signals/me/summary with no health summary" do
          @health_summary.destroy!

          get api_v1_signals_me_summary_path,
            headers: { "Authorization" => "Bearer #{jwt_for(@user)}" }

          assert_response :not_found
          assert_equal "no_signals", response.parsed_body["code"]
          assert_equal "No health data found. Connect Apple Health to see your profile.", response.parsed_body["message"]
        end

        test "GET /api/v1/signals/me/summary without auth" do
          get api_v1_signals_me_summary_path

          assert_response :unauthorized
        end
      end
    end
  end
end