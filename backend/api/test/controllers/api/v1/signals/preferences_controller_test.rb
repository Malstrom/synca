# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    module Signals
      class PreferencesControllerTest < ActionDispatch::IntegrationTest
        include Dry::Monads[:result]

        def setup
          @user = users(:alice)
          @headers = auth_headers(@user)
        end

        test "success" do
          post api_v1_signals_preferences_path,
               params: {
                 preferences: {
                   sleep_together_importance: 3,
                   temperature_preference: "cool",
                   movement_preference: "moderate",
                   rhythm_importance: 4,
                   self_chronotype: "night"
                 }
               },
               headers: @headers

          assert_response :success
          assert_equal "application/json", response.content_type

          json = JSON.parse(response.body)
          assert_equal 3, json["preferences"]["sleep_together_importance"]
          assert_equal "cool", json["preferences"]["temperature_preference"]
          assert_equal "moderate", json["preferences"]["movement_preference"]
          assert_equal 4, json["preferences"]["rhythm_importance"]
          assert_equal "night", json["preferences"]["self_chronotype"]
        end

        test "unauthorized" do
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
               params: {
                 preferences: {
                   sleep_together_importance: 6
                 }
               },
               headers: @headers

          assert_response :unprocessable_entity
          assert_equal "application/json", response.content_type

          json = JSON.parse(response.body)
          assert_equal "validation_failed", json["error"]["code"]
        end
      end
    end
  end
end
