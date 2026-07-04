# frozen_string_literal: true

require 'test_helper'

class PreferenceProfileTest < ActiveSupport::TestCase
  setup do
    @user = users(:alice)
    @preference_profile = @user.preference_profile
  end

  test 'enum values' do
    assert_equal :cool, @preference_profile.temperature_preference
    assert_equal :moderate, @preference_profile.movement_preference
    assert_equal :night, @preference_profile.self_chronotype
  end

  test 'validations' do
    @preference_profile.sleep_together_importance = 6
    assert_not @preference_profile.valid?

    @preference_profile.rhythm_importance = 0
    assert_not @preference_profile.valid?

    @preference_profile.sleep_together_importance = 3
    @preference_profile.rhythm_importance = 4
    assert @preference_profile.valid?
  end

  test 'nil fields' do
    @preference_profile.temperature_preference = nil
    @preference_profile.movement_preference = nil
    @preference_profile.self_chronotype = nil
    assert @preference_profile.valid?
  end
end
