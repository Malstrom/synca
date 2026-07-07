# frozen_string_literal: true

require "test_helper"

class UpsertPreferencesContractTest < ActiveSupport::TestCase
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

    result = UpsertPreferencesContract.new.call(params)

    assert result.success?
  end

  test "invalid sleep_together_importance" do
    params = {
      preferences: {
        sleep_together_importance: 6
      }
    }

    result = UpsertPreferencesContract.new.call(params)

    assert result.failure?
    assert_equal "must be included in 1..5", result.errors.to_h[:preferences][:sleep_together_importance].first
  end

  test "invalid temperature_preference" do
    params = {
      preferences: {
        temperature_preference: "invalid"
      }
    }

    result = UpsertPreferencesContract.new.call(params)

    assert result.failure?
    assert_equal "must be one of: cool, warm, no_preference", result.errors.to_h[:preferences][:temperature_preference].first
  end

  test "invalid movement_preference" do
    params = {
      preferences: {
        movement_preference: "invalid"
      }
    }

    result = UpsertPreferencesContract.new.call(params)

    assert result.failure?
    assert_equal "must be one of: very_little, moderate, a_lot, as_much_as_possible", result.errors.to_h[:preferences][:movement_preference].first
  end

  test "invalid rhythm_importance" do
    params = {
      preferences: {
        rhythm_importance: 6
      }
    }

    result = UpsertPreferencesContract.new.call(params)

    assert result.failure?
    assert_equal "must be included in 1..5", result.errors.to_h[:preferences][:rhythm_importance].first
  end

  test "invalid self_chronotype" do
    params = {
      preferences: {
        self_chronotype: "invalid"
      }
    }

    result = UpsertPreferencesContract.new.call(params)

    assert result.failure?
    assert_equal "must be one of: morning, night, depends", result.errors.to_h[:preferences][:self_chronotype].first
  end
end