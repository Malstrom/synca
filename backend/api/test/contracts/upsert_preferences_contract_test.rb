# frozen_string_literal: true

require "test_helper"

class UpsertPreferencesContractTest < ActiveSupport::TestCase
  setup do
    @contract = UpsertPreferencesContract.new
  end

  test "valid preferences" do
    result = @contract.call(preferences: {
      sleep_together_importance: 3,
      temperature_preference: "cool",
      movement_preference: "moderate",
      rhythm_importance: 4,
      self_chronotype: "night"
    })
    assert_pattern { result => Success }
  end

  test "invalid sleep_together_importance" do
    result = @contract.call(preferences: { sleep_together_importance: 6 })
    assert_pattern { result => Failure }
    assert_includes result.errors.to_h[:preferences][:sleep_together_importance], :error
  end

  test "invalid temperature_preference" do
    result = @contract.call(preferences: { temperature_preference: "invalid" })
    assert_pattern { result => Failure }
    assert_includes result.errors.to_h[:preferences][:temperature_preference], :error
  end

  test "invalid movement_preference" do
    result = @contract.call(preferences: { movement_preference: "invalid" })
    assert_pattern { result => Failure }
    assert_includes result.errors.to_h[:preferences][:movement_preference], :error
  end

  test "invalid rhythm_importance" do
    result = @contract.call(preferences: { rhythm_importance: 6 })
    assert_pattern { result => Failure }
    assert_includes result.errors.to_h[:preferences][:rhythm_importance], :error
  end

  test "invalid self_chronotype" do
    result = @contract.call(preferences: { self_chronotype: "invalid" })
    assert_pattern { result => Failure }
    assert_includes result.errors.to_h[:preferences][:self_chronotype], :error
  end

  test "nil fields are allowed" do
    result = @contract.call(preferences: {
      sleep_together_importance: nil,
      temperature_preference: nil,
      movement_preference: nil,
      rhythm_importance: nil,
      self_chronotype: nil
    })
    assert_pattern { result => Success }
  end
end
