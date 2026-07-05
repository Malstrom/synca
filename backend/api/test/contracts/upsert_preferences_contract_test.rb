# frozen_string_literal: true

require "test_helper"

class UpsertPreferencesContractTest < ActiveSupport::TestCase
  include Dry::Monads[:result]

  def setup
    @contract = UpsertPreferencesContract.new
  end

  test "valid input" do
    input = {
      preferences: {
        sleep_together_importance: 3,
        temperature_preference: "cool",
        movement_preference: "moderate",
        rhythm_importance: 4,
        self_chronotype: "night"
      }
    }

    result = @contract.call(input)
    assert_pattern { result => Success }
  end

  test "invalid sleep_together_importance" do
    input = {
      preferences: {
        sleep_together_importance: 6
      }
    }

    result = @contract.call(input)
    assert_pattern { result => Failure }
    assert_includes result.errors.to_h[:preferences][:sleep_together_importance], "must be between 1 and 5"
  end

  test "invalid temperature_preference" do
    input = {
      preferences: {
        temperature_preference: "invalid"
      }
    }

    result = @contract.call(input)
    assert_pattern { result => Failure }
    assert_includes result.errors.to_h[:preferences][:temperature_preference], "must be cool, warm or no_preference"
  end

  test "invalid movement_preference" do
    input = {
      preferences: {
        movement_preference: "invalid"
      }
    }

    result = @contract.call(input)
    assert_pattern { result => Failure }
    assert_includes result.errors.to_h[:preferences][:movement_preference], "must be very_little, moderate, a_lot or as_much_as_possible"
  end

  test "invalid rhythm_importance" do
    input = {
      preferences: {
        rhythm_importance: 0
      }
    }

    result = @contract.call(input)
    assert_pattern { result => Failure }
    assert_includes result.errors.to_h[:preferences][:rhythm_importance], "must be between 1 and 5"
  end

  test "invalid self_chronotype" do
    input = {
      preferences: {
        self_chronotype: "invalid"
      }
    }

    result = @contract.call(input)
    assert_pattern { result => Failure }
    assert_includes result.errors.to_h[:preferences][:self_chronotype], "must be morning, night or depends"
  end
end
