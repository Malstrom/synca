# frozen_string_literal: true

require 'test_helper'

class UpsertPreferencesServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:alice)
    @attrs = {
      sleep_together_importance: 3,
      temperature_preference: 'warm',
      movement_preference: 'a_lot',
      rhythm_importance: 4,
      self_chronotype: 'depends'
    }
  end

  test 'upsert creates new preference profile' do
    @user.preference_profile.destroy if @user.preference_profile

    result = UpsertPreferencesService.call(current_user: @user, attrs: @attrs)

    assert_predicate result, :success?
    assert_equal @user, result.value!.user
    assert_equal 3, result.value!.sleep_together_importance
  end

  test 'upsert updates existing preference profile' do
    @user.create_preference_profile(sleep_together_importance: 1)

    result = UpsertPreferencesService.call(current_user: @user, attrs: @attrs)

    assert_predicate result, :success?
    assert_equal @user, result.value!.user
    assert_equal 3, result.value!.sleep_together_importance
  end

  test 'partial update' do
    @user.create_preference_profile(sleep_together_importance: 1)

    result = UpsertPreferencesService.call(current_user: @user, attrs: { rhythm_importance: 5 })

    assert_predicate result, :success?
    assert_equal 1, result.value!.sleep_together_importance
    assert_equal 5, result.value!.rhythm_importance
  end

  test 'validation failure' do
    result = UpsertPreferencesService.call(current_user: @user, attrs: { sleep_together_importance: 6 })

    assert_predicate result, :failure?
    assert_equal :validation_failed, result.failure.first
  end
end
