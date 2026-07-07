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

        def test_create_success
          post api_v1_signals_preferences_path, headers: @headers, params: @valid_params

          assert_response :success
          response_body = JSON.parse(response.body)
          assert_equal @valid_params[:preferences][:sleep_together_importance], response_body["preferences"]["sleep_together_importance"]
          assert_equal @valid_params[:preferences][:temperature_preference], response_body["preferences"]["temperature_preference"]
          assert_equal @valid_params[:preferences][:movement_preference], response_body["preferences"]["movement_preference"]
          assert_equal @valid_params[:preferences][:rhythm_importance], response_body["preferences"]["rhythm_importance"]
          assert_equal @valid_params[:preferences][:self_chronotype], response_body["preferences"]["self_chronotype"]
        end

        def test_create_guest_success
          guest = users(:guest)
          guest_headers = auth_headers(guest)
          post api_v1_signals_preferences_path, headers: guest_headers, params: @valid_params

          assert_response :success
        end

        def test_create_unauthorized
          post api_v1_signals_preferences_path, params: @valid_params

          assert_response :unauthorized
        end

        def test_create_contract_errors
          invalid_params = {
            preferences: {
              sleep_together_importance: 6
            }
          }
          post api_v1_signals_preferences_path, headers: @headers, params: invalid_params

          assert_response :unprocessable_entity
          response_body = JSON.parse(response.body)
          assert_equal "validation_failed", response_body["error"]["code"]
        end
      end
    end
  end
end
