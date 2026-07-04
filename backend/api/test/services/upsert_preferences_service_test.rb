# frozen_string_literal: true

require "test_helper"

class UpsertPreferencesServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:alice)
    @service = UpsertPreferencesService.new
  end

  test "upsert create" do
    @user.preference_profile.destroy
    result = @service.call(user: @user, params: {
      preferences: {
        sleep_together_importance: 3,
        temperature_preference: "cool"
      }
    })
    assert result.success?
    assert_equal 3, result.value!.sleep_together_importance
    assert_equal "cool", result.value!.temperature_preference
  end

  test "upsert update" do
    result = @service.call(user: @user, params: {
      preferences: {
        movement_preference: "moderate",
        rhythm_importance: 4
      }
    })
    assert result.success?
    assert_equal "moderate", result.value!.movement_preference
    assert_equal 4, result.value!.rhythm_importance
  end

  test "partial update" do
    result = @service.call(user: @user, params: {
      preferences: {
        self_chronotype: "night"
      }
    })
    assert result.success?
    assert_equal "night", result.value!.self_chronotype
    assert_nil result.value!.sleep_together_importance
  end

  test "validation failure" do
    result = @service.call(user: @user, params: {
      preferences: {
        sleep_together_importance: 6
      }
    })
    assert_not result.success?
    assert_equal :validation_failed, result.failure.first
  end
end
