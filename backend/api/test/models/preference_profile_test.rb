# frozen_string_literal: true

require 'test_helper'

class PreferenceProfileTest < ActiveSupport::TestCase
  test 'enums are defined correctly' do
    assert_equal %w[cool warm no_preference], PreferenceProfile.temperature_preferences.keys
    assert_equal %w[very_little moderate a_lot as_much_as_possible], PreferenceProfile.movement_preferences.keys
    assert_equal %w[morning night depends], PreferenceProfile.self_chronotypes.keys
  end

  test 'validates sleep_together_importance range' do
    profile = PreferenceProfile.new(sleep_together_importance: 6)
    assert_not profile.valid?
    assert_includes profile.errors[:sleep_together_importance], 'must be between 1 and 5'

    profile.sleep_together_importance = 3
    assert profile.valid?
  end

  test 'validates rhythm_importance range' do
    profile = PreferenceProfile.new(rhythm_importance: 0)
    assert_not profile.valid?
    assert_includes profile.errors[:rhythm_importance], 'must be between 1 and 5'

    profile.rhythm_importance = 4
    assert profile.valid?
  end

  test 'allows nil values for all fields' do
    profile = PreferenceProfile.new
    assert profile.valid?
  end
end
