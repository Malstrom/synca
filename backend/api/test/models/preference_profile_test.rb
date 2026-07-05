# frozen_string_literal: true

require 'test_helper'

class PreferenceProfileTest < ActiveSupport::TestCase
  test 'enum values' do
    profile = PreferenceProfile.new

    assert_equal %w[cool warm no_preference], PreferenceProfile.temperature_preferences.keys
    assert_equal %w[very_little moderate a_lot as_much_as_possible], PreferenceProfile.movement_preferences.keys
    assert_equal %w[morning night depends], PreferenceProfile.self_chronotypes.keys

    profile.temperature_preference = :cool
    assert_equal :cool, profile.temperature_preference

    profile.movement_preference = :moderate
    assert_equal :moderate, profile.movement_preference

    profile.self_chronotype = :night
    assert_equal :night, profile.self_chronotype
  end

  test 'validations' do
    profile = PreferenceProfile.new

    profile.sleep_together_importance = 3
    assert profile.valid?

    profile.sleep_together_importance = 6
    assert_not profile.valid?
    assert_includes profile.errors[:sleep_together_importance], 'must be between 1 and 5'

    profile.rhythm_importance = 4
    assert profile.valid?

    profile.rhythm_importance = 0
    assert_not profile.valid?
    assert_includes profile.errors[:rhythm_importance], 'must be between 1 and 5'
  end

  test 'nil fields' do
    profile = PreferenceProfile.new

    assert_nil profile.sleep_together_importance
    assert_nil profile.temperature_preference
    assert_nil profile.movement_preference
    assert_nil profile.rhythm_importance
    assert_nil profile.self_chronotype

    assert profile.valid?
  end
end
