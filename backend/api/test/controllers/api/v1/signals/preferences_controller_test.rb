# frozen_string_literal: true

require "test_helper"

class Api::V1::Signals::PreferencesControllerTest < ApiTestCase
  test "POST preferences with all fields returns 200 and saves record" do
    post api_v1_signals_preferences_path,
         params: {
           preferences: {
             sleep_together_importance: 3,
             rhythm_importance: 4,
             temperature_preference: "cool",
             movement_preference: "moderate",
             self_chronotype: "morning"
           }
         },
         headers: { Authorization: "Bearer #{alice_jwt}" }

    assert_response :success
    assert_equal 3, users(:alice).preference_profile.reload.sleep_together_importance
    assert_equal "cool", users(:alice).preference_profile.temperature_preference
  end

  test "POST preferences with partial payload returns 200" do
    post api_v1_signals_preferences_path,
         params: {
           preferences: {
             sleep_together_importance: 2,
             rhythm_importance: 5
           }
         },
         headers: { Authorization: "Bearer #{alice_jwt}" }

    assert_response :success
    assert_equal 2, users(:alice).preference_profile.reload.sleep_together_importance
    assert_nil users(:alice).preference_profile.temperature_preference
  end

  test "POST preferences is idempotent" do
    original_count = PreferenceProfile.count

    post api_v1_signals_preferences_path,
         params: { preferences: { sleep_together_importance: 3 } },
         headers: { Authorization: "Bearer #{alice_jwt}" }

    post api_v1_signals_preferences_path,
         params: { preferences: { rhythm_importance: 4 } },
         headers: { Authorization: "Bearer #{alice_jwt}" }

    assert_equal original_count, PreferenceProfile.count
    assert_equal 3, users(:alice).preference_profile.reload.sleep_together_importance
    assert_equal 4, users(:alice).preference_profile.rhythm_importance
  end

  test "POST preferences returns 401 without authorization header" do
    post api_v1_signals_preferences_path,
         params: { preferences: { sleep_together_importance: 3 } }

    assert_response :unauthorized
  end

  test "POST preferences returns 422 when sleep_together_importance is out of range" do
    post api_v1_signals_preferences_path,
         params: { preferences: { sleep_together_importance: 6 } },
         headers: { Authorization: "Bearer #{alice_jwt}" }

    assert_response :unprocessable_entity
  end

  test "POST preferences returns 422 when temperature_preference is invalid" do
    post api_v1_signals_preferences_path,
         params: { preferences: { temperature_preference: "unknown" } },
         headers: { Authorization: "Bearer #{alice_jwt}" }

    assert_response :unprocessable_entity
  end

  test "guest user can POST preferences" do
    post api_v1_signals_preferences_path,
         params: { preferences: { sleep_together_importance: 3 } },
         headers: { Authorization: "Bearer #{guest_jwt}" }

    assert_response :success
  end
end
