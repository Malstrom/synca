# frozen_string_literal: true

require "test_helper"

class PreferenceProfileTest < ApiTestCase
  def test_enums
    profile = preference_profiles(:alice_prefs)

    assert_equal :cool, profile.temperature_preference
    assert_equal :moderate, profile.movement_preference
    assert_equal :night, profile.self_chronotype
  end

  def test_validations
    profile = preference_profiles(:alice_prefs)

    profile.sleep_together_importance = 6
    assert_not profile.valid?

    profile.sleep_together_importance = 3
    assert profile.valid?

    profile.rhythm_importance = 0
    assert_not profile.valid?

    profile.rhythm_importance = 4
    assert profile.valid?
  end

  def test_nil_fields
    profile = preference_profiles(:bob_prefs)

    assert_nil profile.sleep_together_importance
    assert_nil profile.temperature_preference
    assert_nil profile.movement_preference
    assert_nil profile.rhythm_importance
    assert_nil profile.self_chronotype
  end
end
