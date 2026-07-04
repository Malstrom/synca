# frozen_string_literal: true

require "test_helper"

class UpsertPreferencesContractTest < ActiveSupport::TestCase
  test "valid with all five fields" do
    input = {
      preferences: {
        sleep_together_importance: 3,
        temperature_preference: "cool",
        movement_preference: "moderate",
        rhythm_importance: 4,
        self_chronotype: "morning"
      }
    }
    result = UpsertPreferencesContract.new.call(input)
    assert_predicate result, :success?
  end

  test "valid with partial payload" do
    input = {
      preferences: {
        sleep_together_importance: 2,
        rhythm_importance: 5
      }
    }
    result = UpsertPreferencesContract.new.call(input)
    assert_predicate result, :success?
  end

  test "valid with empty preferences hash" do
    input = { preferences: {} }
    result = UpsertPreferencesContract.new.call(input)
    assert_predicate result, :success?
  end

  test "invalid when sleep_together_importance is 0" do
    input = { preferences: { sleep_together_importance: 0 } }
    result = UpsertPreferencesContract.new.call(input)
    assert_predicate result, :failure?
    assert_includes result.errors.to_h[:preferences][:sleep_together_importance], "must be between 1 and 5"
  end

  test "invalid when sleep_together_importance is 6" do
    input = { preferences: { sleep_together_importance: 6 } }
    result = UpsertPreferencesContract.new.call(input)
    assert_predicate result, :failure?
    assert_includes result.errors.to_h[:preferences][:sleep_together_importance], "must be between 1 and 5"
  end

  test "invalid when temperature_preference is unknown string" do
    input = { preferences: { temperature_preference: "unknown" } }
    result = UpsertPreferencesContract.new.call(input)
    assert_predicate result, :failure?
    assert_includes result.errors.to_h[:preferences][:temperature_preference], "must be cool, warm, or no_preference"
  end

  test "invalid when movement_preference is unknown string" do
    input = { preferences: { movement_preference: "unknown" } }
    result = UpsertPreferencesContract.new.call(input)
    assert_predicate result, :failure?
    assert_includes result.errors.to_h[:preferences][:movement_preference], "must be very_little, moderate, a_lot, or as_much_as_possible"
  end

  test "invalid when self_chronotype is unknown string" do
    input = { preferences: { self_chronotype: "unknown" } }
    result = UpsertPreferencesContract.new.call(input)
    assert_predicate result, :failure?
    assert_includes result.errors.to_h[:preferences][:self_chronotype], "must be morning, night, or depends"
  end
end
