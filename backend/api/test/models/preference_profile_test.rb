# frozen_string_literal: true

require "test_helper"

class PreferenceProfileTest < ApiTestCase
  setup do
    @user = users(:alice)
    @preference_profile = @user.preference_profile
  end

  test "validates sleep_together_importance range" do
    @preference_profile.sleep_together_importance = 6
    assert_not @preference_profile.valid?
    assert_includes @preference_profile.errors[:sleep_together_importance], "must be between 1 and 5"
  end

  test "validates rhythm_importance range" do
    @preference_profile.rhythm_importance = 0
    assert_not @preference_profile.valid?
    assert_includes @preference_profile.errors[:rhythm_importance], "must be between 1 and 5"
  end

  test "allows nil values for optional fields" do
    @preference_profile.sleep_together_importance = nil
    @preference_profile.temperature_preference = nil
    @preference_profile.movement_preference = nil
    @preference_profile.rhythm_importance = nil
    @preference_profile.self_chronotype = nil
    assert @preference_profile.valid?
  end

  test "enum values for temperature_preference" do
    assert_equal "cool", PreferenceProfile.temperature_preferences.key(0)
    assert_equal "warm", PreferenceProfile.temperature_preferences.key(1)
    assert_equal "no_preference", PreferenceProfile.temperature_preferences.key(2)
  end

  test "enum values for movement_preference" do
    assert_equal "very_little", PreferenceProfile.movement_preferences.key(0)
    assert_equal "moderate", PreferenceProfile.movement_preferences.key(1)
    assert_equal "a_lot", PreferenceProfile.movement_preferences.key(2)
    assert_equal "as_much_as_possible", PreferenceProfile.movement_preferences.key(3)
  end

  test "enum values for self_chronotype" do
    assert_equal "morning", PreferenceProfile.self_chronotypes.key(0)
    assert_equal "night", PreferenceProfile.self_chronotypes.key(1)
    assert_equal "depends", PreferenceProfile.self_chronotypes.key(2)
  end
end
