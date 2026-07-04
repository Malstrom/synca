# frozen_string_literal: true

require 'test_helper'

class UpsertPreferencesServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:alice)
    @attrs = {
      sleep_together_importance: 4,
      temperature_preference: 'cool',
      movement_preference: 'moderate',
      rhythm_importance: 3,
      self_chronotype: 'night'
    }
  end

  test 'upsert create' do
    assert_difference -> { PreferenceProfile.count }, +1 do
      result = UpsertPreferencesService.call(current_user: @user, attrs: @attrs)
      assert result.success?
      assert_equal @attrs[:sleep_together_importance], result.value!.sleep_together_importance
    end
  end

  test 'upsert update' do
    @user.create_preference_profile(@attrs)
    new_attrs = { sleep_together_importance: 5 }

    assert_no_difference -> { PreferenceProfile.count } do
      result = UpsertPreferencesService.call(current_user: @user, attrs: new_attrs)
      assert result.success?
      assert_equal new_attrs[:sleep_together_importance], result.value!.sleep_together_importance
    end
  end

  test 'partial update' do
    @user.create_preference_profile(@attrs)
    new_attrs = { rhythm_importance: 2 }

    result = UpsertPreferencesService.call(current_user: @user, attrs: new_attrs)
    assert result.success?
    assert_equal @attrs[:sleep_together_importance], result.value!.sleep_together_importance
    assert_equal new_attrs[:rhythm_importance], result.value!.rhythm_importance
  end

  test 'validation failed' do
    result = UpsertPreferencesService.call(current_user: @user, attrs: { sleep_together_importance: 6 })
    assert result.failure?
    assert_equal :validation_failed, result.failure.first
  end
end
