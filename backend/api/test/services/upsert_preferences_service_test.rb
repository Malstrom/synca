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

  test "upsert create" do
    @user.preference_profile.destroy if @user.preference_profile
    result = UpsertPreferencesService.call(current_user: @user, attrs: @attrs)
    assert result.success?
    assert_equal @attrs[:sleep_together_importance], result.value!.sleep_together_importance
    assert_equal @attrs[:temperature_preference], result.value!.temperature_preference
    assert_equal @attrs[:movement_preference], result.value!.movement_preference
    assert_equal @attrs[:rhythm_importance], result.value!.rhythm_importance
    assert_equal @attrs[:self_chronotype], result.value!.self_chronotype
  end

  test "upsert update" do
    result = UpsertPreferencesService.call(current_user: @user, attrs: @attrs)
    assert result.success?
    assert_equal @attrs[:sleep_together_importance], result.value!.sleep_together_importance
  end

  test "partial update" do
    partial_attrs = { sleep_together_importance: 2, temperature_preference: "warm" }
    result = UpsertPreferencesService.call(current_user: @user, attrs: partial_attrs)
    assert result.success?
    assert_equal partial_attrs[:sleep_together_importance], result.value!.sleep_together_importance
    assert_equal partial_attrs[:temperature_preference], result.value!.temperature_preference
    assert_nil result.value!.movement_preference
    assert_nil result.value!.rhythm_importance
    assert_nil result.value!.self_chronotype
  end

  test "validation failure" do
    result = UpsertPreferencesService.call(current_user: @user, attrs: { sleep_together_importance: 6 })
    assert result.failure?
    assert_equal :validation_failed, result.failure[0]
  end
end
