# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    module Signals
      class SummaryControllerTest < ActionDispatch::IntegrationTest
        setup do
          @user = users(:one)
          @health_summary = health_summaries(:one)
          @preference_profile = preference_profiles(:one)
          @headers = { "Authorization" => "Bearer #{@user.jwt_token}" }
        end

        test "GET /api/v1/signals/me/summary returns 200 with summary" do
          get api_v1_signals_me_summary_path, headers: @headers

          assert_response :success
          assert_equal "Early bird", response.parsed_body.dig("summary", "chronotype_label")
          assert_equal "07:00–09:00", response.parsed_body.dig("summary", "peak_energy_window")
          assert_equal "high", response.parsed_body.dig("summary", "routine_stability_tier")
          assert_equal "moderate", response.parsed_body.dig("summary", "activity_tier")
          assert_equal 437, response.parsed_body.dig("summary", "avg_sleep_duration_minutes")
          assert_nil response.parsed_body.dig("summary", "self_report_alignment")
        end

        test "GET /api/v1/signals/me/summary returns 404 when no health_summary" do
          @health_summary.destroy
          get api_v1_signals_me_summary_path, headers: @headers

          assert_response :not_found
          assert_equal "no_signals", response.parsed_body["code"]
        end

        test "GET /api/v1/signals/me/summary returns 401 when unauthenticated" do
          get api_v1_signals_me_summary_path

          assert_response :unauthorized
        end
      end
    end
  end
end