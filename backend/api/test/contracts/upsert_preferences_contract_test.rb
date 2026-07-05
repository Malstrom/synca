# frozen_string_literal: true

require "test_helper"

class UpsertPreferencesContractTest < ActiveSupport::TestCase
  test "valid params" do
    result = UpsertPreferencesContract.new.call(
      preferences: {
        sleep_together_importance: 4,
        temperature_preference: "cool",
        movement_preference: "moderate",
        rhythm_importance: 3,
        self_chronotype: "night"
      }
    )

    assert result.success?
  end

  test "invalid sleep_together_importance" do
    result = UpsertPreferencesContract.new.call(
      preferences: { sleep_together_importance: 6 }
    )

    assert result.failure?
    assert_includes result.errors.to_h[:preferences][:sleep_together_importance], "must be one of: 1 - 5"
  end

  test "invalid temperature_preference" do
    result = UpsertPreferencesContract.new.call(
      preferences: { temperature_preference: "invalid" }
    )

    assert result.failure?
    assert_includes result.errors.to_h[:preferences][:temperature_preference], "must be one of: cool, warm, no_preference"
  end

  test "invalid movement_preference" do
    result = UpsertPreferencesContract.new.call(
      preferences: { movement_preference: "invalid" }
    )

    assert result.failure?
    assert_includes result.errors.to_h[:preferences][:movement_preference], "must be one of: very_little, moderate, a_lot, as_much_as_possible"
  end

  test "invalid rhythm_importance" do
    result = UpsertPreferencesContract.new.call(
      preferences: { rhythm_importance: 0 }
    )

    assert result.failure?
    assert_includes result.errors.to_h[:preferences][:rhythm_importance], "must be one of: 1 - 5"
  end

  test "invalid self_chronotype" do
    result = UpsertPreferencesContract.new.call(
      preferences: { self_chronotype: "invalid" }
    )

    assert result.failure?
    assert_includes result.errors.to_h[:preferences][:self_chronotype], "must be one of: morning, night, depends"
  end
end
