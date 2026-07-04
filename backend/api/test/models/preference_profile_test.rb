# frozen_string_literal: true

require 'test_helper'

class PreferenceProfileTest < ActiveSupport::TestCase
  setup do
    @user = users(:alice)
    @preference_profile = @user.preference_profile || @user.build_preference_profile
  end

  test 'validates sleep_together_importance range' do
    @preference_profile.sleep_together_importance = 6
    assert_not @preference_profile.valid?
    assert_includes @preference_profile.errors[:sleep_together_importance], 'must be between 1 and 5'

    @preference_profile.sleep_together_importance = 1
    assert @preference_profile.valid?
  end

  test 'validates rhythm_importance range' do
    @preference_profile.rhythm_importance = 0
    assert_not @preference_profile.valid?
    assert_includes @preference_profile.errors[:rhythm_importance], 'must be between 1 and 5'

    @preference_profile.rhythm_importance = 5
    assert @preference_profile.valid?
  end

  test 'allows nil values for optional fields' do
    @preference_profile.sleep_together_importance = nil
    @preference_profile.temperature_preference = nil
    @preference_profile.movement_preference = nil
    @preference_profile.rhythm_importance = nil
    @preference_profile.self_chronotype = nil

    assert @preference_profile.valid?
  end

  test 'enum values are correctly mapped' do
    @preference_profile.temperature_preference = :cool
    assert_equal 'cool', @preference_profile.temperature_preference

    @preference_profile.movement_preference = :moderate
    assert_equal 'moderate', @preference_profile.movement_preference

    @preference_profile.self_chronotype = :morning
    assert_equal 'morning', @preference_profile.self_chronotype
  end
end
