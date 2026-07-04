# frozen_string_literal: true

require "test_helper"

class UpsertPreferencesServiceTest < ApiTestCase
  def test_upsert_create
    user = users(:alice)
    user.preference_profile.destroy

    result = UpsertPreferencesService.call(
      current_user: user,
      attrs: {
        sleep_together_importance: 4,
        temperature_preference: "cool",
        movement_preference: "moderate",
        rhythm_importance: 3,
        self_chronotype: "night"
      }
    )

    assert result.success?
    assert_equal 4, result.value!.sleep_together_importance
    assert_equal :cool, result.value!.temperature_preference
    assert_equal :moderate, result.value!.movement_preference
    assert_equal 3, result.value!.rhythm_importance
    assert_equal :night, result.value!.self_chronotype
  end

  def test_upsert_update
    profile = preference_profiles(:alice_prefs)

    result = UpsertPreferencesService.call(
      current_user: profile.user,
      attrs: {
        sleep_together_importance: 5,
        temperature_preference: "warm"
      }
    )

    assert result.success?
    assert_equal 5, result.value!.sleep_together_importance
    assert_equal :warm, result.value!.temperature_preference
    assert_equal :moderate, result.value!.movement_preference
    assert_equal 3, result.value!.rhythm_importance
    assert_equal :night, result.value!.self_chronotype
  end

  def test_partial_upsert
    profile = preference_profiles(:alice_prefs)

    result = UpsertPreferencesService.call(
      current_user: profile.user,
      attrs: {
        rhythm_importance: 2,
        self_chronotype: "morning"
      }
    )

    assert result.success?
    assert_equal 4, result.value!.sleep_together_importance
    assert_equal :cool, result.value!.temperature_preference
    assert_equal :moderate, result.value!.movement_preference
    assert_equal 2, result.value!.rhythm_importance
    assert_equal :morning, result.value!.self_chronotype
  end
end
