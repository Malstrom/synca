# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    module Signals
      class SummaryControllerTest < ActionDispatch::IntegrationTest
        setup do
          @user = users(:alice)
          @signal = signals(:alice_signal)
          @headers = { "Authorization" => "Bearer #{JwtService.encode(user_id: @user.id)}" }
        end

        test "GET /api/v1/signals/me/summary with signals" do
          get api_v1_signals_summary_path, headers: @headers

          assert_response :success
          assert_equal "Early bird", response.parsed_body["summary"]["chronotype_label"]
          assert_equal "21:00–23:00", response.parsed_body["summary"]["peak_energy_window"]
          assert_equal "high", response.parsed_body["summary"]["routine_stability_tier"]
          assert_equal "medium", response.parsed_body["summary"]["activity_tier"]
          assert_equal 437, response.parsed_body["summary"]["avg_sleep_duration_minutes"]
          assert_nil response.parsed_body["summary"]["self_report_alignment"]
        end

        test "GET /api/v1/signals/me/summary with preference profile" do
          @user.preference_profile.update!(self_chronotype: "morning")

          get api_v1_signals_summary_path, headers: @headers

          assert_response :success
          assert_equal false, response.parsed_body["summary"]["self_report_alignment"]["aligned"]
          assert_equal "You declared morning but your data shows early_bird.", response.parsed_body["summary"]["self_report_alignment"]["note"]
        end

        test "GET /api/v1/signals/me/summary without signals" do
          @signal.destroy

          get api_v1_signals_summary_path, headers: @headers

          assert_response :not_found
          assert_equal "no_signals", response.parsed_body["code"]
          assert_equal "No health data found. Connect Apple Health to see your profile.", response.parsed_body["message"]
        end

        test "GET /api/v1/signals/me/summary without auth" do
          get api_v1_signals_summary_path

          assert_response :unauthorized
        end
      end
    end
  end
end