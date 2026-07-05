# frozen_string_literal: true

require "test_helper"

class PreferenceProfileTest < ActiveSupport::TestCase
  test "enum values" do
    assert_equal %w[cool warm no_preference], PreferenceProfile.temperature_preferences.keys
    assert_equal %w[very_little moderate a_lot as_much_as_possible], PreferenceProfile.movement_preferences.keys
    assert_equal %w[morning night depends], PreferenceProfile.self_chronotypes.keys
  end

  test "validations" do
    profile = PreferenceProfile.new

    profile.sleep_together_importance = 3
    assert profile.valid?

    profile.sleep_together_importance = 6
    assert_not profile.valid?

    profile.rhythm_importance = 4
    assert profile.valid?

    profile.rhythm_importance = 0
    assert_not profile.valid?
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
