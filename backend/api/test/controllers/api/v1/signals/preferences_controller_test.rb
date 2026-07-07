# frozen_string_literal: true

require "test_helper"

class Api::V1::Signals::PreferencesControllerTest < ActionDispatch::IntegrationTest
  test "success" do
    user = users(:alice)
    params = {
      preferences: {
        sleep_together_importance: 4,
        temperature_preference: "cool",
        movement_preference: "moderate",
        rhythm_importance: 3,
        self_chronotype: "night"
      }
    }

    post api_v1_signals_preferences_path, headers: auth_headers(user), params: params

    assert_response :success
    assert_equal params[:preferences][:sleep_together_importance], response.parsed_body["preferences"]["sleep_together_importance"]
    assert_equal params[:preferences][:temperature_preference], response.parsed_body["preferences"]["temperature_preference"]
    assert_equal params[:preferences][:movement_preference], response.parsed_body["preferences"]["movement_preference"]
    assert_equal params[:preferences][:rhythm_importance], response.parsed_body["preferences"]["rhythm_importance"]
    assert_equal params[:preferences][:self_chronotype], response.parsed_body["preferences"]["self_chronotype"]
  end

  test "validation failed" do
    user = users(:alice)
    params = {
      preferences: {
        sleep_together_importance: 6
      }
    }

    post api_v1_signals_preferences_path, headers: auth_headers(user), params: params

    assert_response :unprocessable_entity
    assert_equal "validation_failed", response.parsed_body["error"]["code"]
  end

  test "unauthorized" do
    params = {
      preferences: {
        sleep_together_importance: 4
      }
    }

    post api_v1_signals_preferences_path, params: params

    assert_response :unauthorized
  end
end
