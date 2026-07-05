# frozen_string_literal: true

require "test_helper"

class PreferenceProfileTest < ActiveSupport::TestCase
  setup do
    @user = users(:alice)
    @preference_profile = @user.preference_profile || @user.build_preference_profile
  end

  test "validates sleep_together_importance range" do
    @preference_profile.sleep_together_importance = 6
    assert_not @preference_profile.valid?
    assert_includes @preference_profile.errors[:sleep_together_importance], "must be between 1 and 5"

    @preference_profile.sleep_together_importance = 3
    assert @preference_profile.valid?
  end

  test "validates rhythm_importance range" do
    @preference_profile.rhythm_importance = 0
    assert_not @preference_profile.valid?
    assert_includes @preference_profile.errors[:rhythm_importance], "must be between 1 and 5"

    @preference_profile.rhythm_importance = 4
    assert @preference_profile.valid?
  end

  test "temperature_preference enum values" do
    assert_equal %w[cool warm no_preference], PreferenceProfile.temperature_preferences.keys
  end

  test "movement_preference enum values" do
    assert_equal %w[very_little moderate a_lot as_much_as_possible], PreferenceProfile.movement_preferences.keys
  end

  test "self_chronotype enum values" do
    assert_equal %w[morning night depends], PreferenceProfile.self_chronotypes.keys
  end

  test "allows nil values for all fields" do
    @preference_profile.sleep_together_importance = nil
    @preference_profile.temperature_preference = nil
    @preference_profile.movement_preference = nil
    @preference_profile.rhythm_importance = nil
    @preference_profile.self_chronotype = nil
    assert @preference_profile.valid?
  end
end
