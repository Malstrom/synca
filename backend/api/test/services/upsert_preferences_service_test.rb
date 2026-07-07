# frozen_string_literal: true

require "test_helper"

class UpsertPreferencesServiceTest < ActiveSupport::TestCase
  test "success" do
    user = users(:alice)
    attrs = {
      sleep_together_importance: 4,
      temperature_preference: "cool",
      movement_preference: "moderate",
      rhythm_importance: 3,
      self_chronotype: "night"
    }

    result = UpsertPreferencesService.call(current_user: user, attrs: attrs)

    assert result.success?
    assert_equal attrs[:sleep_together_importance], result.value!.sleep_together_importance
    assert_equal attrs[:temperature_preference], result.value!.temperature_preference
    assert_equal attrs[:movement_preference], result.value!.movement_preference
    assert_equal attrs[:rhythm_importance], result.value!.rhythm_importance
    assert_equal attrs[:self_chronotype], result.value!.self_chronotype
  end

  test "validation failed" do
    user = users(:alice)
    attrs = {
      sleep_together_importance: 6
    }

    result = UpsertPreferencesService.call(current_user: user, attrs: attrs)

    assert result.failure?
    assert_equal :validation_failed, result.failure.first
  end
end