# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    module Signals
      class SummaryControllerTest < ApiTestCase
        setup do
          @user = users(:alice)
          @health_summary = health_summaries(:alice_summary)
          @preference_profile = preference_profiles(:alice_prefs)
        end

        test "GET /api/v1/signals/me/summary with health_summary → 200" do
          get "/api/v1/signals/me/summary", headers: auth_headers(@user)

          assert_response :success
          assert_equal "Early bird", json[:summary][:chronotype_label]
          assert_equal "08:00–10:00", json[:summary][:peak_energy_window]
          assert_equal "high", json[:summary][:routine_stability_tier]
          assert_equal "moderate", json[:summary][:activity_tier]
          assert_equal 437, json[:summary][:avg_sleep_duration_minutes]
          assert_equal false, json[:summary][:self_report_alignment][:aligned]
        end

        test "GET /api/v1/signals/me/summary without health_summary → 404" do
          @health_summary.update!(effective_to: Time.current)

          get "/api/v1/signals/me/summary", headers: auth_headers(@user)

          assert_response :not_found
          assert_equal "no_signals", json[:code]
        end

        test "GET /api/v1/signals/me/summary without auth → 401" do
          get "/api/v1/signals/me/summary"

          assert_response :unauthorized
        end
      end
    end
  end
end

---