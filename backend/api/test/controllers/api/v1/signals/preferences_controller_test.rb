# frozen_string_literal: true

require "test_helper"

class Api::V1::Signals::PreferencesControllerTest < ApiTestCase
  setup do
    @user = users(:alice)
    @headers = auth_headers(@user)
  end

  test "successful update" do
    post api_v1_signals_preferences_path,
         params: { preferences: { sleep_together_importance: 4 } },
         headers: @headers,
         as: :json

    assert_response :success
    assert_equal 4, json_response[:preferences][:sleep_together_importance]
  end

  test "partial update" do
    post api_v1_signals_preferences_path,
         params: { preferences: { temperature_preference: "cool" } },
         headers: @headers,
         as: :json

    assert_response :success
    assert_equal "cool", json_response[:preferences][:temperature_preference]
  end

  test "validation failure" do
    post api_v1_signals_preferences_path,
         params: { preferences: { rhythm_importance: 6 } },
         headers: @headers,
         as: :json

    assert_response :unprocessable_entity
    assert_equal "validation_failed", json_response[:error][:code]
  end

  test "unauthorized" do
    post api_v1_signals_preferences_path,
         params: { preferences: { movement_preference: "moderate" } },
         as: :json

    assert_response :unauthorized
  end

  test "guest user can update" do
    guest_user = users(:guest_user)
    headers = auth_headers(guest_user)

    post api_v1_signals_preferences_path,
         params: { preferences: { self_chronotype: "night" } },
         headers: headers,
         as: :json

    assert_response :success
    assert_equal "night", json_response[:preferences][:self_chronotype]
  end
end
