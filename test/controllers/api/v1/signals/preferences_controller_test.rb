# frozen_string_literal: true

require "test_helper"

class Api::V1::Signals::PreferencesControllerTest < ApiTestCase
  test "POST preferences with all fields returns 200 and saves record" do
    alice = users(:alice)
    alice.preference_profile.destroy!

    post api_v1_signals_preferences_path,
         headers: alice_headers,
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
    assert_equal 3, alice.reload.preference_profile.sleep_together_importance
    assert_equal "warm", alice.preference_profile.temperature_preference
    assert_equal "moderate", alice.preference_profile.movement_preference
    assert_equal 4, alice.preference_profile.rhythm_importance
    assert_equal "morning", alice.preference_profile.self_chronotype
  end

  test "POST preferences with partial payload returns 200" do
    alice = users(:alice)

    post api_v1_signals_preferences_path,
         headers: alice_headers,
         params: {
           preferences: {
             sleep_together_importance: 2,
             rhythm_importance: 5
           }
         }

    assert_response :success
    profile = alice.reload.preference_profile
    assert_equal 2, profile.sleep_together_importance
    assert_equal 5, profile.rhythm_importance
    assert_nil profile.temperature_preference
  end

  test "POST preferences is idempotent" do
    alice = users(:alice)
    original_count = PreferenceProfile.count

    post api_v1_signals_preferences_path,
         headers: alice_headers,
         params: { preferences: { sleep_together_importance: 3 } }

    assert_response :success
    assert_equal original_count, PreferenceProfile.count

    post api_v1_signals_preferences_path,
         headers: alice_headers,
         params: { preferences: { sleep_together_importance: 4 } }

    assert_response :success
    assert_equal original_count, PreferenceProfile.count
    assert_equal 4, alice.reload.preference_profile.sleep_together_importance
  end

  test "POST preferences returns 401 without authorization header" do
    post api_v1_signals_preferences_path,
         params: { preferences: { sleep_together_importance: 3 } }

    assert_response :unauthorized
  end

  test "POST preferences returns 422 when sleep_together_importance is out of range" do
    post api_v1_signals_preferences_path,
         headers: alice_headers,
         params: { preferences: { sleep_together_importance: 6 } }

    assert_response :unprocessable_entity
  end

  test "POST preferences returns 422 when temperature_preference is invalid" do
    post api_v1_signals_preferences_path,
         headers: alice_headers,
         params: { preferences: { temperature_preference: "unknown" } }

    assert_response :unprocessable_entity
  end

  test "guest user can POST preferences" do
    guest = users(:guest_user)

    post api_v1_signals_preferences_path,
         headers: guest_headers,
         params: { preferences: { sleep_together_importance: 3 } }

    assert_response :success
    assert_equal 3, guest.reload.preference_profile.sleep_together_importance
  end
end
