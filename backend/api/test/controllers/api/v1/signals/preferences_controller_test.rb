# frozen_string_literal: true

require "test_helper"

class Api::V1::Signals::PreferencesControllerTest < ApiTestCase
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

    patch api_v1_signals_preferences_path, headers: auth_headers(user), params: params

    assert_response :success
    assert_equal params[:preferences][:sleep_together_importance], response.parsed_body["sleep_together_importance"]
    assert_equal params[:preferences][:temperature_preference], response.parsed_body["temperature_preference"]
    assert_equal params[:preferences][:movement_preference], response.parsed_body["movement_preference"]
    assert_equal params[:preferences][:rhythm_importance], response.parsed_body["rhythm_importance"]
    assert_equal params[:preferences][:self_chronotype], response.parsed_body["self_chronotype"]
  end

  test "partial update does not overwrite existing fields" do
    user = users(:alice)
    # alice_prefs fixture has sleep_together_importance: 4, temperature_preference: cool
    params = {
      preferences: {
        sleep_together_importance: 2
      }
    }

    patch api_v1_signals_preferences_path, headers: auth_headers(user), params: params

    assert_response :success
    assert_equal 2, response.parsed_body["sleep_together_importance"]
    # temperature_preference should not be cleared
    assert_equal "cool", response.parsed_body["temperature_preference"]
  end

  test "validation failed" do
    user = users(:alice)
    params = {
      preferences: {
        sleep_together_importance: 6
      }
    }

    patch api_v1_signals_preferences_path, headers: auth_headers(user), params: params

    assert_response :unprocessable_entity
    assert_equal "validation_failed", response.parsed_body["error"]["code"]
  end

  test "unauthorized" do
    params = {
      preferences: {
        sleep_together_importance: 4
      }
    }

    patch api_v1_signals_preferences_path, params: params

    assert_response :unauthorized
  end
end
