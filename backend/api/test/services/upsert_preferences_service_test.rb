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

  test 'upsert create' do
    @user.preference_profile.destroy
    result = UpsertPreferencesService.call(current_user: @user, attrs: @attrs)
    assert result.success?
    assert_equal @user.preference_profile, result.value!
  end

  test 'upsert update' do
    result = UpsertPreferencesService.call(current_user: @user, attrs: @attrs)
    assert result.success?
    assert_equal @user.preference_profile, result.value!
  end

  test 'partial update' do
    partial_attrs = { sleep_together_importance: 2 }
    result = UpsertPreferencesService.call(current_user: @user, attrs: partial_attrs)
    assert result.success?
    assert_equal 2, result.value!.sleep_together_importance
    assert_nil result.value!.temperature_preference
  end
end
