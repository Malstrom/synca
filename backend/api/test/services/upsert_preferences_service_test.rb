# frozen_string_literal: true

require 'test_helper'

class UpsertPreferencesServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:alice)
    @service = UpsertPreferencesService.new(@user)
  end

  test 'upsert create' do
    @user.preference_profile.destroy
    params = {
      preferences: {
        sleep_together_importance: 4,
        temperature_preference: 'cool'
      }
    }
    result = @service.call(params)
    assert result.success?
    assert_equal 4, result.value!.sleep_together_importance
    assert_equal 'cool', result.value!.temperature_preference
  end

  test 'upsert update' do
    params = {
      preferences: {
        sleep_together_importance: 5,
        temperature_preference: 'warm'
      }
    }
    result = @service.call(params)
    assert result.success?
    assert_equal 5, result.value!.sleep_together_importance
    assert_equal 'warm', result.value!.temperature_preference
  end

  test 'partial update' do
    params = { preferences: { rhythm_importance: 3 } }
    result = @service.call(params)
    assert result.success?
    assert_equal 3, result.value!.rhythm_importance
    assert_nil result.value!.movement_preference
  end

  test 'validation failure' do
    params = { preferences: { sleep_together_importance: 6 } }
    result = @service.call(params)
    assert_not result.success?
    assert_equal :validation_failed, result.failure.first
  end
end
