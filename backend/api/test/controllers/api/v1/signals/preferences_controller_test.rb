# frozen_string_literal: true

require "test_helper"

class Api::V1::Signals::PreferencesControllerTest < ApiTestCase
  setup do
    @user = users(:alice)
    @headers = auth_headers(@user)
  end

  test "successful update" do
    post api_v1_signals_preferences_path,
         params: {
           preferences: {
             sleep_together_importance: 4,
             temperature_preference: "cool",
             movement_preference: "moderate",
             rhythm_importance: 3,
             self_chronotype: "night"
           }
         },
         headers: @headers,
         as: :json

    assert_response :success
    response_body = JSON.parse(response.body)

    assert_equal 4, response_body.dig("preferences", "sleep_together_importance")
    assert_equal "cool", response_body.dig("preferences", "temperature_preference")
    assert_equal "moderate", response_body.dig("preferences", "movement_preference")
    assert_equal 3, response_body.dig("preferences", "rhythm_importance")
    assert_equal "night", response_body.dig("preferences", "self_chronotype")
  end

  test "partial update" do
    post api_v1_signals_preferences_path,
         params: { preferences: { rhythm_importance: 2 } },
         headers: @headers,
         as: :json

    assert_response :success
    response_body = JSON.parse(response.body)

    assert_equal 2, response_body.dig("preferences", "rhythm_importance")
    assert_nil response_body.dig("preferences", "sleep_together_importance")
  end

  test "validation failure" do
    post api_v1_signals_preferences_path,
         params: { preferences: { sleep_together_importance: 6 } },
         headers: @headers,
         as: :json

    assert_response :unprocessable_entity
    response_body = JSON.parse(response.body)

    assert_equal "validation_failed", response_body.dig("error", "code")
    assert_includes response_body.dig("error", "message"), "Sleep together importance must be between 1 and 5"
  end

  test "unauthorized" do
    post api_v1_signals_preferences_path,
         params: { preferences: { rhythm_importance: 3 } },
         as: :json

    assert_response :unauthorized
  end
end
