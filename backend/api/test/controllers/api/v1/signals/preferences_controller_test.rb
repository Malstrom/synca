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
    assert_equal "cool", response.parsed_body["preferences"]["temperature_preference"]
  end

  test "partial update" do
    post api_v1_signals_preferences_path,
         params: { preferences: { rhythm_importance: 2 } },
         headers: @headers,
         as: :json
    assert_response :success
    assert_equal 2, response.parsed_body["preferences"]["rhythm_importance"]
  end

  test "guest user" do
    post api_v1_signals_preferences_path,
         params: { preferences: { self_chronotype: "morning" } },
         headers: auth_headers(users(:guest)),
         as: :json
    assert_response :success
    assert_equal "morning", response.parsed_body["preferences"]["self_chronotype"]
  end

  test "invalid sleep_together_importance" do
    post api_v1_signals_preferences_path,
         params: { preferences: { sleep_together_importance: 6 } },
         headers: @headers,
         as: :json
    assert_response :unprocessable_entity
    assert_equal "validation_failed", response.parsed_body["error"]["code"]
  end

  test "invalid temperature_preference" do
    post api_v1_signals_preferences_path,
         params: { preferences: { temperature_preference: "invalid" } },
         headers: @headers,
         as: :json
    assert_response :unprocessable_entity
    assert_equal "validation_failed", response.parsed_body["error"]["code"]
  end

  test "unauthenticated" do
    post api_v1_signals_preferences_path,
         params: { preferences: { rhythm_importance: 3 } },
         as: :json
    assert_response :unauthorized
  end
end
