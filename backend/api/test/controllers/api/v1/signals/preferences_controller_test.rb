# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    module Signals
      class PreferencesControllerTest < ActionDispatch::IntegrationTest
        def setup
          @user = users(:alice)
          @headers = auth_headers(@user)
          @valid_params = {
            preferences: {
              sleep_together_importance: 3,
              temperature_preference: "cool",
              movement_preference: "moderate",
              rhythm_importance: 4,
              self_chronotype: "night"
            }
          }
        end

        test "successful upsert" do
          post api_v1_signals_preferences_path, params: @valid_params, headers: @headers

          assert_response :success
          response_body = JSON.parse(response.body)
          assert_equal @valid_params[:preferences][:sleep_together_importance], response_body["preferences"]["sleep_together_importance"]
          assert_equal @valid_params[:preferences][:temperature_preference], response_body["preferences"]["temperature_preference"]
          assert_equal @valid_params[:preferences][:movement_preference], response_body["preferences"]["movement_preference"]
          assert_equal @valid_params[:preferences][:rhythm_importance], response_body["preferences"]["rhythm_importance"]
          assert_equal @valid_params[:preferences][:self_chronotype], response_body["preferences"]["self_chronotype"]
        end

        test "validation failure" do
          post api_v1_signals_preferences_path, params: { preferences: { sleep_together_importance: 6 } }, headers: @headers

          assert_response :unprocessable_entity
          response_body = JSON.parse(response.body)
          assert_equal "validation_failed", response_body["error"]["code"]
          assert_equal "Sleep together importance must be included in 1..5", response_body["error"]["message"]
        end

        test "unauthorized" do
          post api_v1_signals_preferences_path, params: @valid_params

          assert_response :unauthorized
        end

        test "contract rejection" do
          post api_v1_signals_preferences_path, params: { preferences: { temperature_preference: "invalid" } }, headers: @headers

          assert_response :unprocessable_entity
          response_body = JSON.parse(response.body)
          assert_equal "validation_failed", response_body["error"]["code"]
          assert_equal "Temperature preference must be one of: cool, warm, no_preference", response_body["error"]["message"]
        end

        test "guest user" do
          guest_headers = auth_headers(users(:guest))
          post api_v1_signals_preferences_path, params: @valid_params, headers: guest_headers

          assert_response :success
        end
      end
    end
  end
end
