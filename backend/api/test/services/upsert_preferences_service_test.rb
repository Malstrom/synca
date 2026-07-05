# frozen_string_literal: true

require 'test_helper'

class UpsertPreferencesServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:alice)
    @service = UpsertPreferencesService.new
  end

  test 'upsert create' do
    @user.preference_profile.destroy
    params = {
      preferences: {
        sleep_together_importance: 4,
        temperature_preference: 'cool',
        movement_preference: 'moderate',
        rhythm_importance: 3,
        self_chronotype: 'night'
      }
    }
    result = @service.call(user: @user, params: params)
    assert result.success?
    assert_equal @user.preference_profile, result.value!
    assert_equal 4, @user.preference_profile.sleep_together_importance
    assert_equal 'cool', @user.preference_profile.temperature_preference
    assert_equal 'moderate', @user.preference_profile.movement_preference
    assert_equal 3, @user.preference_profile.rhythm_importance
    assert_equal 'night', @user.preference_profile.self_chronotype
  end

  test 'upsert update' do
    params = {
      preferences: {
        sleep_together_importance: 4,
        temperature_preference: 'cool',
        movement_preference: 'moderate',
        rhythm_importance: 3,
        self_chronotype: 'night'
      }
    }
    result = @service.call(user: @user, params: params)
    assert result.success?
    assert_equal @user.preference_profile, result.value!
    assert_equal 4, @user.preference_profile.sleep_together_importance
    assert_equal 'cool', @user.preference_profile.temperature_preference
    assert_equal 'moderate', @user.preference_profile.movement_preference
    assert_equal 3, @user.preference_profile.rhythm_importance
    assert_equal 'night', @user.preference_profile.self_chronotype
  end

  test 'partial update' do
    params = {
      preferences: {
        sleep_together_importance: 4,
        temperature_preference: 'cool'
      }
    }
    result = @service.call(user: @user, params: params)
    assert result.success?
    assert_equal @user.preference_profile, result.value!
    assert_equal 4, @user.preference_profile.sleep_together_importance
    assert_equal 'cool', @user.preference_profile.temperature_preference
    assert_nil @user.preference_profile.movement_preference
    assert_nil @user.preference_profile.rhythm_importance
    assert_nil @user.preference_profile.self_chronotype
  end

  test 'validation failure' do
    params = {
      preferences: {
        sleep_together_importance: 6
      }
    }
    result = @service.call(user: @user, params: params)
    assert_not result.success?
    assert_equal [:validation_failed, 'Sleep together importance must be between 1 and 5'], result.failure
  end
end
