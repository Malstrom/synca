# frozen_string_literal: true

require "test_helper"

class UpsertPreferencesContractTest < ActiveSupport::TestCase
  include Dry::Monads[:result]

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
    assert_includes result.errors.to_h[:preferences][:sleep_together_importance], :included_in?
  end

  test "invalid temperature_preference" do
    result = @contract.call(preferences: { temperature_preference: "invalid" })

    assert_pattern { result => Failure }
    assert_includes result.errors.to_h[:preferences][:temperature_preference], :included_in?
  end

  test "invalid movement_preference" do
    result = @contract.call(preferences: { movement_preference: "invalid" })

    assert_pattern { result => Failure }
    assert_includes result.errors.to_h[:preferences][:movement_preference], :included_in?
  end

  test "invalid rhythm_importance" do
    result = @contract.call(preferences: { rhythm_importance: 0 })

    assert_pattern { result => Failure }
    assert_includes result.errors.to_h[:preferences][:rhythm_importance], :included_in?
  end

  test "invalid self_chronotype" do
    result = @contract.call(preferences: { self_chronotype: "invalid" })

    assert_pattern { result => Failure }
    assert_includes result.errors.to_h[:preferences][:self_chronotype], :included_in?
  end

  test "partial preferences" do
    result = @contract.call(preferences: { sleep_together_importance: 2 })

    assert_pattern { result => Success }
  end
end
