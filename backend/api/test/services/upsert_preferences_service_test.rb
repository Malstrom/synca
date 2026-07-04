# frozen_string_literal: true

require 'test_helper'

class UpsertPreferencesServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:alice)
    @attrs = {
      sleep_together_importance: 3,
      temperature_preference: 'cool',
      movement_preference: 'moderate',
      rhythm_importance: 4,
      self_chronotype: 'night'
    }
  end

  test 'upsert creates new preference profile' do
    @user.preference_profile.destroy if @user.preference_profile

    result = UpsertPreferencesService.call(current_user: @user, attrs: @attrs)

    assert result.success?
    assert_equal @user.preference_profile, result.value!
    assert_equal 3, @user.preference_profile.sleep_together_importance
  end

  test 'upsert updates existing preference profile' do
    existing_profile = @user.preference_profile || @user.create_preference_profile
    existing_profile.update(sleep_together_importance: 1)

    result = UpsertPreferencesService.call(current_user: @user, attrs: @attrs)

    assert result.success?
    assert_equal @user.preference_profile, result.value!
    assert_equal 3, @user.preference_profile.sleep_together_importance
  end

  test 'partial update' do
    existing_profile = @user.preference_profile || @user.create_preference_profile
    existing_profile.update(sleep_together_importance: 1, rhythm_importance: 2)

    partial_attrs = { temperature_preference: 'warm' }

    result = UpsertPreferencesService.call(current_user: @user, attrs: partial_attrs)

    assert result.success?
    assert_equal 1, @user.preference_profile.sleep_together_importance
    assert_equal 'warm', @user.preference_profile.temperature_preference
    assert_equal 2, @user.preference_profile.rhythm_importance
  end

  test 'validation failure' do
    result = UpsertPreferencesService.call(current_user: @user, attrs: { sleep_together_importance: 6 })

    assert result.failure?
    assert_equal :validation_failed, result.failure[0]
  end
end
