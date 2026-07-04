# frozen_string_literal: true

require "test_helper"

class Api::V1::Signals::PreferencesControllerTest < ApiTestCase
  setup do
    @user = users(:alice)
    @headers = auth_headers(@user)
  end

  test "successful update" do
    post_json api_v1_signals_preferences_path, {
      preferences: {
        sleep_together_importance: 3,
        temperature_preference: "cool"
      }
    }, @headers

    assert_response :success
    assert_equal 3, json_response[:preferences][:sleep_together_importance]
    assert_equal "cool", json_response[:preferences][:temperature_preference]
  end

  test "unauthorized" do
    post_json api_v1_signals_preferences_path, {
      preferences: {
        movement_preference: "moderate"
      }
    }

    assert_response :unauthorized
  end

  test "validation failure" do
    post_json api_v1_signals_preferences_path, {
      preferences: {
        sleep_together_importance: 6
      }
    }, @headers

    assert_response :unprocessable_entity
    assert_equal "validation_failed", json_response[:error][:code]
  end

  test "guest user" do
    guest = users(:guest)
    headers = auth_headers(guest)

    post_json api_v1_signals_preferences_path, {
      preferences: {
        rhythm_importance: 4
      }
    }, headers

    assert_response :success
    assert_equal 4, json_response[:preferences][:rhythm_importance]
  end
end
