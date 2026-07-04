# frozen_string_literal: true

require 'test_helper'

class PreferenceProfileTest < ActiveSupport::TestCase
  setup do
    @user = users(:alice)
    @preference_profile = @user.preference_profile
  end

  test 'enum values' do
    assert_equal :cool, @preference_profile.temperature_preference = 'cool'
    assert_equal :warm, @preference_profile.temperature_preference = 'warm'
    assert_equal :no_preference, @preference_profile.temperature_preference = 'no_preference'

    assert_equal :very_little, @preference_profile.movement_preference = 'very_little'
    assert_equal :moderate, @preference_profile.movement_preference = 'moderate'
    assert_equal :a_lot, @preference_profile.movement_preference = 'a_lot'
    assert_equal :as_much_as_possible, @preference_profile.movement_preference = 'as_much_as_possible'

    assert_equal :morning, @preference_profile.self_chronotype = 'morning'
    assert_equal :night, @preference_profile.self_chronotype = 'night'
    assert_equal :depends, @preference_profile.self_chronotype = 'depends'
  end

  test 'validations' do
    assert @preference_profile.update(sleep_together_importance: 1)
    assert @preference_profile.update(sleep_together_importance: 5)
    assert_not @preference_profile.update(sleep_together_importance: 0)
    assert_not @preference_profile.update(sleep_together_importance: 6)

    assert @preference_profile.update(rhythm_importance: 1)
    assert @preference_profile.update(rhythm_importance: 5)
    assert_not @preference_profile.update(rhythm_importance: 0)
    assert_not @preference_profile.update(rhythm_importance: 6)
  end

  test 'nil fields' do
    assert @preference_profile.update(sleep_together_importance: nil)
    assert @preference_profile.update(temperature_preference: nil)
    assert @preference_profile.update(movement_preference: nil)
    assert @preference_profile.update(rhythm_importance: nil)
    assert @preference_profile.update(self_chronotype: nil)
  end
end
