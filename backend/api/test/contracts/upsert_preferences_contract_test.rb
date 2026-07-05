# frozen_string_literal: true

require "test_helper"

class UpsertPreferencesContractTest < ActiveSupport::TestCase
  setup do
    @contract = UpsertPreferencesContract.new
  end

  test "valid params" do
    params = {
      preferences: {
        sleep_together_importance: 4,
        temperature_preference: "cool",
        movement_preference: "moderate",
        rhythm_importance: 3,
        self_chronotype: "night"
      }
    }
    result = @contract.call(params)
    assert result.success?
  end

  test "invalid sleep_together_importance" do
    params = {
      preferences: {
        sleep_together_importance: 6
      }
    }
    result = @contract.call(params)
    assert_not result.success?
    assert_includes result.errors.to_h[:preferences][:sleep_together_importance], "must be between 1 and 5"
  end

  test "invalid temperature_preference" do
    params = {
      preferences: {
        temperature_preference: "invalid"
      }
    }
    result = @contract.call(params)
    assert_not result.success?
    assert_includes result.errors.to_h[:preferences][:temperature_preference], "must be one of: #{PreferenceProfile.temperature_preferences.keys.join(', ')}"
  end

  test "invalid movement_preference" do
    params = {
      preferences: {
        movement_preference: "invalid"
      }
    }
    result = @contract.call(params)
    assert_not result.success?
    assert_includes result.errors.to_h[:preferences][:movement_preference], "must be one of: #{PreferenceProfile.movement_preferences.keys.join(', ')}"
  end

  test "invalid rhythm_importance" do
    params = {
      preferences: {
        rhythm_importance: 6
      }
    }
    result = @contract.call(params)
    assert_not result.success?
    assert_includes result.errors.to_h[:preferences][:rhythm_importance], "must be between 1 and 5"
  end

  test "invalid self_chronotype" do
    params = {
      preferences: {
        self_chronotype: "invalid"
      }
    }
    result = @contract.call(params)
    assert_not result.success?
    assert_includes result.errors.to_h[:preferences][:self_chronotype], "must be one of: #{PreferenceProfile.self_chronotypes.keys.join(', ')}"
  end
end
