# frozen_string_literal: true

require 'test_helper'

class PreferenceProfileTest < ActiveSupport::TestCase
  setup do
    @user = users(:alice)
    @preference_profile = @user.preference_profile
  end

  test 'valid preference profile' do
    assert @preference_profile.valid?
  end

  test 'invalid sleep_together_importance' do
    @preference_profile.sleep_together_importance = 6
    assert_not @preference_profile.valid?
    assert_includes @preference_profile.errors[:sleep_together_importance], 'must be between 1 and 5'
  end

  test 'valid temperature_preference' do
    PreferenceProfile.temperature_preferences.keys.each do |pref|
      @preference_profile.temperature_preference = pref
      assert @preference_profile.valid?
    end
  end

  test 'invalid temperature_preference' do
    @preference_profile.temperature_preference = 'invalid'
    assert_not @preference_profile.valid?
    assert_includes @preference_profile.errors[:temperature_preference], 'is not included in the list'
  end

  test 'valid movement_preference' do
    PreferenceProfile.movement_preferences.keys.each do |pref|
      @preference_profile.movement_preference = pref
      assert @preference_profile.valid?
    end
  end

  test 'invalid movement_preference' do
    @preference_profile.movement_preference = 'invalid'
    assert_not @preference_profile.valid?
    assert_includes @preference_profile.errors[:movement_preference], 'is not included in the list'
  end

  test 'invalid rhythm_importance' do
    @preference_profile.rhythm_importance = 6
    assert_not @preference_profile.valid?
    assert_includes @preference_profile.errors[:rhythm_importance], 'must be between 1 and 5'
  end

  test 'valid self_chronotype' do
    PreferenceProfile.self_chronotypes.keys.each do |pref|
      @preference_profile.self_chronotype = pref
      assert @preference_profile.valid?
    end
  end

  test 'invalid self_chronotype' do
    @preference_profile.self_chronotype = 'invalid'
    assert_not @preference_profile.valid?
    assert_includes @preference_profile.errors[:self_chronotype], 'is not included in the list'
  end

  test 'nil fields' do
    @preference_profile.sleep_together_importance = nil
    @preference_profile.temperature_preference = nil
    @preference_profile.movement_preference = nil
    @preference_profile.rhythm_importance = nil
    @preference_profile.self_chronotype = nil
    assert @preference_profile.valid?
  end
end
