# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    module Signals
      class MeControllerTest < ApiTestCase
        setup do
          @user = users(:with_health_summary)
          @headers = auth_headers(@user)
        end

        test 'GET /api/v1/signals/me/summary with health data' do
          get api_v1_signals_me_summary_path, headers: @headers

          assert_response :success
          assert_equal 'Early bird', response.parsed_body.dig('summary', 'chronotype_label')
          assert_equal '08:00–10:00', response.parsed_body.dig('summary', 'peak_energy_window')
          assert_equal 'high', response.parsed_body.dig('summary', 'routine_stability_tier')
          assert_equal 'moderate', response.parsed_body.dig('summary', 'activity_tier')
          assert_equal 450, response.parsed_body.dig('summary', 'avg_sleep_duration_minutes')
          assert_not_nil response.parsed_body.dig('summary', 'self_report_alignment')
        end

        test 'GET /api/v1/signals/me/summary without health data' do
          user = users(:without_health_summary)
          headers = auth_headers(user)

          get api_v1_signals_me_summary_path, headers: headers

          assert_response :not_found
          assert_equal 'no_signals', response.parsed_body['code']
        end

        test 'GET /api/v1/signals/me/summary without token' do
          get api_v1_signals_me_summary_path

          assert_response :unauthorized
        end
      end
    end
  end
end
