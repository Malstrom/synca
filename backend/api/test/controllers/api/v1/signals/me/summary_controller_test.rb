# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    module Signals
      module Me
        class SummaryControllerTest < ApiTestCase
          setup do
            @user = users(:alice)
            @headers = auth_headers(@user)
          end

          test "successful response with health data" do
            get api_v1_signals_me_summary_path, headers: @headers, as: :json
            assert_response :success

            response_body = JSON.parse(response.body)
            assert_equal "Early bird", response_body["summary"]["chronotype_label"]
            assert_equal "21:00–23:00", response_body["summary"]["peak_energy_window"]
            assert_equal "high", response_body["summary"]["routine_stability_tier"]
            assert_equal "moderate", response_body["summary"]["activity_tier"]
            assert_equal 437, response_body["summary"]["avg_sleep_duration_minutes"]
            assert_equal false, response_body["summary"]["self_report_alignment"]["aligned"]
          end

          test "returns 404 when no health summary" do
            user_without_health = users(:bob)
            get api_v1_signals_me_summary_path, headers: auth_headers(user_without_health), as: :json
            assert_response :not_found

            response_body = JSON.parse(response.body)
            assert_equal "no_signals", response_body["code"]
            assert_equal "No health data found. Connect Apple Health to see your profile.", response_body["message"]
          end

          test "returns null peak_energy_window when times are nil" do
            health_summary = health_summaries(:alice_health)
            health_summary.update!(peak_energy_start_local: nil, peak_energy_end_local: nil)

            get api_v1_signals_me_summary_path, headers: @headers, as: :json
            assert_response :success

            response_body = JSON.parse(response.body)
            assert_nil response_body["summary"]["peak_energy_window"]
          end

          test "returns null self_report_alignment when no preference profile" do
            user_without_prefs = users(:charlie)
            get api_v1_signals_me_summary_path, headers: auth_headers(user_without_prefs), as: :json
            assert_response :success

            response_body = JSON.parse(response.body)
            assert_nil response_body["summary"]["self_report_alignment"]
          end
        end
      end
    end
  end
end
