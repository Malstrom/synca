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
          @token = JwtService.encode(user_id: @user.id)
        end

        test "GET /api/v1/signals/me/summary with active health_summary" do
          get api_v1_signals_me_summary_path, headers: { "Authorization" => "Bearer #{@token}" }

          assert_response :success
          assert_equal "Early bird", response.parsed_body["summary"]["chronotype_label"]
          assert_equal "06:00–08:00", response.parsed_body["summary"]["peak_energy_window"]
          assert_equal "high", response.parsed_body["summary"]["routine_stability_tier"]
          assert_equal "moderate", response.parsed_body["summary"]["activity_tier"]
          assert_equal 437, response.parsed_body["summary"]["avg_sleep_duration_minutes"]
          assert_equal true, response.parsed_body["summary"]["self_report_alignment"]["aligned"]
        end

        test "GET /api/v1/signals/me/summary with no health_summary" do
          @health_summary.update!(effective_to: Time.current)
          get api_v1_signals_me_summary_path, headers: { "Authorization" => "Bearer #{@token}" }

          assert_response :not_found
          assert_equal "no_signals", response.parsed_body["code"]
          assert_equal I18n.t("errors.no_signals"), response.parsed_body["message"]
        end

        test "GET /api/v1/signals/me/summary without auth" do
          get api_v1_signals_me_summary_path

          assert_response :unauthorized
        end
      end
    end
  end
end
