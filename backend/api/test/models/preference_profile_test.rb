# frozen_string_literal: true

require 'test_helper'

class PreferenceProfileTest < ActiveSupport::TestCase
  setup do
    @user = users(:alice)
    @preference_profile = @user.preference_profile
  end

  test 'validates sleep_together_importance range' do
    @preference_profile.sleep_together_importance = 6
    assert_not @preference_profile.valid?
    assert_includes @preference_profile.errors[:sleep_together_importance], 'must be in 1..5'
  end

  test 'validates rhythm_importance range' do
    @preference_profile.rhythm_importance = 0
    assert_not @preference_profile.valid?
    assert_includes @preference_profile.errors[:rhythm_importance], 'must be in 1..5'
  end

  test 'allows nil values' do
    @preference_profile.sleep_together_importance = nil
    @preference_profile.rhythm_importance = nil
    assert @preference_profile.valid?
  end

  test 'enum values' do
    assert_equal :cool, @preference_profile.temperature_preference = 'cool'
    assert_equal :very_little, @preference_profile.movement_preference = 'very_little'
    assert_equal :morning, @preference_profile.self_chronotype = 'morning'
  end
end
