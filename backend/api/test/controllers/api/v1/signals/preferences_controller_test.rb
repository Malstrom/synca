# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    module Signals
      class PreferencesControllerTest < ApiTestCase
        setup do
          @user = users(:alice)
          @headers = auth_headers(@user)
        end

        test "success" do
          post api_v1_signals_preferences_path,
               headers: @headers,
               params: {
                 preferences: {
                   sleep_together_importance: 3,
                   temperature_preference: "cool"
                 }
               }

          assert_response :success
          assert_equal 3, response.parsed_body["preferences"]["sleep_together_importance"]
          assert_equal "cool", response.parsed_body["preferences"]["temperature_preference"]
        end

        test "unauthenticated" do
          post api_v1_signals_preferences_path,
               params: {
                 preferences: {
                   sleep_together_importance: 3
                 }
               }

          assert_response :unauthorized
        end

        test "validation failed" do
          post api_v1_signals_preferences_path,
               headers: @headers,
               params: {
                 preferences: {
                   rhythm_importance: 6
                 }
               }

          assert_response :unprocessable_entity
          assert_equal "validation_failed", response.parsed_body["error"]["code"]
        end

        test "guest user" do
          guest = users(:guest_user)
          guest_headers = auth_headers(guest)

          post api_v1_signals_preferences_path,
               headers: guest_headers,
               params: {
                 preferences: {
                   movement_preference: "moderate"
                 }
               }

          assert_response :success
          assert_equal "moderate", response.parsed_body["preferences"]["movement_preference"]
        end
      end
    end
  end
end
