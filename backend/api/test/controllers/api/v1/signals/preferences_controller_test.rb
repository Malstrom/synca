# frozen_string_literal: true

require "test_helper"

class Api::V1::Signals::PreferencesControllerTest < ApiTestCase
  test "POST preferences with all fields returns 200 and saves record" do
    user = users(:alice)
    auth_headers = auth_headers_for(user)

    post api_v1_signals_preferences_path,
         headers: auth_headers,
         params: {
           preferences: {
             sleep_together_importance: 3,
             temperature_preference: "warm",
             movement_preference: "moderate",
             rhythm_importance: 4,
             self_chronotype: "morning"
           }
         }

    assert_response :success
    assert_equal 3, user.reload.preference_profile.sleep_together_importance
    assert_equal "warm", user.preference_profile.temperature_preference
  end

  test "POST preferences with partial payload returns 200" do
    user = users(:alice)
    auth_headers = auth_headers_for(user)

    post api_v1_signals_preferences_path,
         headers: auth_headers,
         params: {
           preferences: {
             sleep_together_importance: 2,
             rhythm_importance: 5
           }
         }

    assert_response :success
    assert_equal 2, user.reload.preference_profile.sleep_together_importance
    assert_nil user.preference_profile.temperature_preference
  end

  test "POST preferences is idempotent" do
    user = users(:alice)
    auth_headers = auth_headers_for(user)
    original_count = PreferenceProfile.count

    post api_v1_signals_preferences_path,
         headers: auth_headers,
         params: { preferences: { sleep_together_importance: 3 } }

    assert_response :success

    post api_v1_signals_preferences_path,
         headers: auth_headers,
         params: { preferences: { rhythm_importance: 4 } }

    assert_response :success
    assert_equal original_count, PreferenceProfile.count
  end

  test "POST preferences returns 401 without authorization header" do
    post api_v1_signals_preferences_path,
         params: { preferences: { sleep_together_importance: 3 } }

    assert_response :unauthorized
  end

  test "POST preferences returns 422 when sleep_together_importance is out of range" do
    user = users(:alice)
    auth_headers = auth_headers_for(user)

    post api_v1_signals_preferences_path,
         headers: auth_headers,
         params: { preferences: { sleep_together_importance: 6 } }

    assert_response :unprocessable_entity
  end

  test "POST preferences returns 422 when temperature_preference is invalid" do
    user = users(:alice)
    auth_headers = auth_headers_for(user)

    post api_v1_signals_preferences_path,
         headers: auth_headers,
         params: { preferences: { temperature_preference: "unknown" } }

    assert_response :unprocessable_entity
  end

  test "guest user can POST preferences" do
    user = users(:guest_user)
    auth_headers = auth_headers_for(user)

    post api_v1_signals_preferences_path,
         headers: auth_headers,
         params: { preferences: { sleep_together_importance: 3 } }

    assert_response :success
    assert_equal 3, user.reload.preference_profile.sleep_together_importance
  end
end
