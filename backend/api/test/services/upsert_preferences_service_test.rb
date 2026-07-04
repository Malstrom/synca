# frozen_string_literal: true

require "test_helper"

class UpsertPreferencesServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:alice)
    @attrs = {
      sleep_together_importance: 3,
      temperature_preference: "cool",
      movement_preference: "moderate",
      rhythm_importance: 4,
      self_chronotype: "night"
    }
  end

  test "upsert creates new preference profile" do
    assert_difference -> { PreferenceProfile.count }, 1 do
      result = UpsertPreferencesService.call(current_user: @user, attrs: @attrs)
      assert result.success?
      assert_equal @attrs[:sleep_together_importance], result.value!.sleep_together_importance
      assert_equal @attrs[:temperature_preference], result.value!.temperature_preference
      assert_equal @attrs[:movement_preference], result.value!.movement_preference
      assert_equal @attrs[:rhythm_importance], result.value!.rhythm_importance
      assert_equal @attrs[:self_chronotype], result.value!.self_chronotype
    end
  end

  test "upsert updates existing preference profile" do
    existing_profile = @user.create_preference_profile(sleep_together_importance: 1)
    new_attrs = { sleep_together_importance: 5 }

    assert_no_difference -> { PreferenceProfile.count } do
      result = UpsertPreferencesService.call(current_user: @user, attrs: new_attrs)
      assert result.success?
      assert_equal 5, result.value!.sleep_together_importance
    end
  end

  test "partial update" do
    existing_profile = @user.create_preference_profile(sleep_together_importance: 1, rhythm_importance: 2)
    new_attrs = { sleep_together_importance: 3 }

    result = UpsertPreferencesService.call(current_user: @user, attrs: new_attrs)
    assert result.success?
    assert_equal 3, result.value!.sleep_together_importance
    assert_equal 2, result.value!.rhythm_importance
  end

  test "validation failure" do
    result = UpsertPreferencesService.call(current_user: @user, attrs: { sleep_together_importance: 6 })
    assert result.failure?
    assert_equal :validation_failed, result.failure.first
  end
end
