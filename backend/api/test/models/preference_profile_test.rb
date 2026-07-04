# frozen_string_literal: true

require "test_helper"

class PreferenceProfileTest < ActiveSupport::TestCase
  setup do
    @user = users(:alice)
    @preference_profile = @user.build_preference_profile
  end

  test "validates sleep_together_importance range" do
    @preference_profile.sleep_together_importance = 6
    assert_not @preference_profile.valid?
    assert_includes @preference_profile.errors[:sleep_together_importance], "must be in 1..5"

    @preference_profile.sleep_together_importance = 1
    assert @preference_profile.valid?
  end

  test "validates rhythm_importance range" do
    @preference_profile.rhythm_importance = 0
    assert_not @preference_profile.valid?
    assert_includes @preference_profile.errors[:rhythm_importance], "must be in 1..5"

    @preference_profile.rhythm_importance = 5
    assert @preference_profile.valid?
  end

  test "allows nil values for optional fields" do
    assert @preference_profile.valid?
    assert_nil @preference_profile.sleep_together_importance
    assert_nil @preference_profile.temperature_preference
    assert_nil @preference_profile.movement_preference
    assert_nil @preference_profile.rhythm_importance
    assert_nil @preference_profile.self_chronotype
  end

  test "enum values are correct" do
    assert_equal %w[cool warm no_preference], PreferenceProfile.temperature_preferences.keys
    assert_equal %w[very_little moderate a_lot as_much_as_possible], PreferenceProfile.movement_preferences.keys
    assert_equal %w[morning night depends], PreferenceProfile.self_chronotypes.keys
  end
end
