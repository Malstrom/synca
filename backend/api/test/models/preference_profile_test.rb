# frozen_string_literal: true

require 'test_helper'

class PreferenceProfileTest < ActiveSupport::TestCase
  test 'valid temperature_preference values' do
    assert_equal %w[cool warm no_preference], PreferenceProfile.temperature_preferences.keys
  end

  test 'valid movement_preference values' do
    assert_equal %w[very_little moderate a_lot as_much_as_possible], PreferenceProfile.movement_preferences.keys
  end

  test 'valid self_chronotype values' do
    assert_equal %w[morning night depends], PreferenceProfile.self_chronotypes.keys
  end

  test 'sleep_together_importance validation' do
    profile = preference_profiles(:alice_prefs)
    profile.sleep_together_importance = 6
    assert_not profile.valid?
    assert_includes profile.errors[:sleep_together_importance], 'must be between 1 and 5'

    profile.sleep_together_importance = 3
    assert profile.valid?
  end

  test 'rhythm_importance validation' do
    profile = preference_profiles(:alice_prefs)
    profile.rhythm_importance = 0
    assert_not profile.valid?
    assert_includes profile.errors[:rhythm_importance], 'must be between 1 and 5'

    profile.rhythm_importance = 4
    assert profile.valid?
  end

  test 'nil fields are allowed' do
    profile = preference_profiles(:alice_prefs)
    profile.sleep_together_importance = nil
    profile.temperature_preference = nil
    profile.movement_preference = nil
    profile.rhythm_importance = nil
    profile.self_chronotype = nil
    assert profile.valid?
  end
end
