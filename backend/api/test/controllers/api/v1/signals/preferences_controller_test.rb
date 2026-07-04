# frozen_string_literal: true

require "test_helper"

class Api::V1::Signals::PreferencesControllerTest < ApiTestCase
  test "POST preferences with all fields returns 200 and saves record" do
    alice = users(:alice)
    post api_v1_signals_preferences_path,
         params: {
           preferences: {
             sleep_together_importance: 3,
             temperature_preference: "warm",
             movement_preference: "moderate",
             rhythm_importance: 4,
             self_chronotype: "morning"
           }
         },
         headers: { Authorization: "Bearer #{alice.jwt}" }

    assert_response :success
    assert_equal 3, alice.reload.preference_profile.sleep_together_importance
    assert_equal "warm", alice.preference_profile.temperature_preference
    assert_equal "moderate", alice.preference_profile.movement_preference
    assert_equal 4, alice.preference_profile.rhythm_importance
    assert_equal "morning", alice.preference_profile.self_chronotype
  end

  test "POST preferences with partial payload returns 200" do
    alice = users(:alice)
    post api_v1_signals_preferences_path,
         params: {
           preferences: {
             sleep_together_importance: 2,
             rhythm_importance: 5
           }
         },
         headers: { Authorization: "Bearer #{alice.jwt}" }

    assert_response :success
    assert_equal 2, alice.reload.preference_profile.sleep_together_importance
    assert_equal 5, alice.preference_profile.rhythm_importance
    assert_nil alice.preference_profile.temperature_preference
  end

  test "POST preferences is idempotent" do
    alice = users(:alice)
    original_count = PreferenceProfile.count

    post api_v1_signals_preferences_path,
         params: { preferences: { sleep_together_importance: 3 } },
         headers: { Authorization: "Bearer #{alice.jwt}" }

    post api_v1_signals_preferences_path,
         params: { preferences: { sleep_together_importance: 4 } },
         headers: { Authorization: "Bearer #{alice.jwt}" }

    assert_equal original_count, PreferenceProfile.count
    assert_equal 4, alice.reload.preference_profile.sleep_together_importance
  end

  test "POST preferences returns 401 without authorization header" do
    post api_v1_signals_preferences_path,
         params: { preferences: { sleep_together_importance: 3 } }

    assert_response :unauthorized
  end

  test "POST preferences returns 422 when sleep_together_importance is out of range" do
    alice = users(:alice)
    post api_v1_signals_preferences_path,
         params: { preferences: { sleep_together_importance: 6 } },
         headers: { Authorization: "Bearer #{alice.jwt}" }

    assert_response :unprocessable_entity
  end

  test "POST preferences returns 422 when temperature_preference is invalid" do
    alice = users(:alice)
    post api_v1_signals_preferences_path,
         params: { preferences: { temperature_preference: "invalid" } },
         headers: { Authorization: "Bearer #{alice.jwt}" }

    assert_response :unprocessable_entity
  end

  test "guest user can POST preferences" do
    guest = users(:guest_user)
    post api_v1_signals_preferences_path,
         params: { preferences: { sleep_together_importance: 3 } },
         headers: { Authorization: "Bearer #{guest.jwt}" }

    assert_response :success
    assert_equal 3, guest.reload.preference_profile.sleep_together_importance
  end
end
