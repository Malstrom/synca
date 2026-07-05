# frozen_string_literal: true

require "test_helper"

class PreferenceProfileTest < ActiveSupport::TestCase
  setup do
    @user = users(:alice)
    @preference_profile = @user.preference_profile
  end

  test "valid preference profile" do
    assert @preference_profile.valid?
  end

  test "valid temperature preference values" do
    assert_includes PreferenceProfile.temperature_preferences.keys, "cool"
    assert_includes PreferenceProfile.temperature_preferences.keys, "warm"
    assert_includes PreferenceProfile.temperature_preferences.keys, "no_preference"
  end

  test "valid movement preference values" do
    assert_includes PreferenceProfile.movement_preferences.keys, "very_little"
    assert_includes PreferenceProfile.movement_preferences.keys, "moderate"
    assert_includes PreferenceProfile.movement_preferences.keys, "a_lot"
    assert_includes PreferenceProfile.movement_preferences.keys, "as_much_as_possible"
  end

  test "valid self chronotype values" do
    assert_includes PreferenceProfile.self_chronotypes.keys, "morning"
    assert_includes PreferenceProfile.self_chronotypes.keys, "night"
    assert_includes PreferenceProfile.self_chronotypes.keys, "depends"
  end

  test "sleep_together_importance must be between 1 and 5" do
    @preference_profile.sleep_together_importance = 0
    assert_not @preference_profile.valid?

    @preference_profile.sleep_together_importance = 6
    assert_not @preference_profile.valid?

    @preference_profile.sleep_together_importance = 3
    assert @preference_profile.valid?
  end

  test "rhythm_importance must be between 1 and 5" do
    @preference_profile.rhythm_importance = 0
    assert_not @preference_profile.valid?

    @preference_profile.rhythm_importance = 6
    assert_not @preference_profile.valid?

    @preference_profile.rhythm_importance = 3
    assert @preference_profile.valid?
  end

  test "nil fields are allowed" do
    @preference_profile.sleep_together_importance = nil
    @preference_profile.temperature_preference = nil
    @preference_profile.movement_preference = nil
    @preference_profile.rhythm_importance = nil
    @preference_profile.self_chronotype = nil
    assert @preference_profile.valid?
  end
end
