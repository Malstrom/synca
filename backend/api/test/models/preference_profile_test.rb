# frozen_string_literal: true

require "test_helper"

class PreferenceProfileTest < ActiveSupport::TestCase
  test "enum values" do
    assert_equal({ "cool" => 0, "warm" => 1, "no_preference" => 2 }, PreferenceProfile.temperature_preferences)
    assert_equal({ "very_little" => 0, "moderate" => 1, "a_lot" => 2, "as_much_as_possible" => 3 }, PreferenceProfile.movement_preferences)
    assert_equal({ "morning" => 0, "night" => 1, "depends" => 2 }, PreferenceProfile.self_chronotypes)
  end

  test "validations" do
    profile = PreferenceProfile.new

    profile.sleep_together_importance = 6
    assert_not profile.valid?
    assert_includes profile.errors[:sleep_together_importance], "must be between 1 and 5"

    profile.sleep_together_importance = 3
    assert profile.valid?

    profile.rhythm_importance = 0
    assert_not profile.valid?
    assert_includes profile.errors[:rhythm_importance], "must be between 1 and 5"

    profile.rhythm_importance = 4
    assert profile.valid?
  end

  test "nil fields" do
    profile = PreferenceProfile.new
    assert_nil profile.sleep_together_importance
    assert_nil profile.temperature_preference
    assert_nil profile.movement_preference
    assert_nil profile.rhythm_importance
    assert_nil profile.self_chronotype
  end
end
