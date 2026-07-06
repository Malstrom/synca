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
    assert_equal 4, response.parsed_body["preferences"]["sleep_together_importance"]
    assert_equal "cool", response.parsed_body["preferences"]["temperature_preference"]
    assert_equal "moderate", response.parsed_body["preferences"]["movement_preference"]
    assert_equal 3, response.parsed_body["preferences"]["rhythm_importance"]
    assert_equal "night", response.parsed_body["preferences"]["self_chronotype"]
  end

  test "partial update" do
    post api_v1_signals_preferences_path,
         params: { preferences: { rhythm_importance: 4 } },
         headers: @headers,
         as: :json
    assert_response :success
    assert_equal 4, response.parsed_body["preferences"]["rhythm_importance"]
  end

  test "guest user" do
    guest_headers = auth_headers(users(:guest))
    post api_v1_signals_preferences_path,
         params: { preferences: { rhythm_importance: 4 } },
         headers: guest_headers,
         as: :json
    assert_response :success
  end

  test "invalid input" do
    post api_v1_signals_preferences_path,
         params: { preferences: { sleep_together_importance: 6 } },
         headers: @headers,
         as: :json
    assert_response :unprocessable_entity
    assert_equal "validation_failed", response.parsed_body["error"]["code"]
  end

  test "unauthorized" do
    post api_v1_signals_preferences_path,
         params: { preferences: { rhythm_importance: 4 } },
         as: :json
    assert_response :unauthorized
  end
end
