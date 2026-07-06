# frozen_string_literal: true

require "test_helper"

class UpsertPreferencesContractTest < ActiveSupport::TestCase
  def setup
    @contract = UpsertPreferencesContract.new
  end

  def test_valid_params
    result = @contract.call(preferences: {
      sleep_together_importance: 3,
      temperature_preference: "cool",
      movement_preference: "moderate",
      rhythm_importance: 4,
      self_chronotype: "night"
    })

    assert result.success?
  end

  def test_missing_preferences
    result = @contract.call({})

    assert result.failure?
    assert_equal "is missing", result.errors.to_h[:preferences].first.text
  end

  def test_invalid_sleep_together_importance
    result = @contract.call(preferences: { sleep_together_importance: 6 })

    assert result.failure?
    assert_equal "must be between 1 and 5", result.errors.to_h[:preferences][:sleep_together_importance].first.text
  end

  def test_invalid_temperature_preference
    result = @contract.call(preferences: { temperature_preference: "invalid" })

    assert result.failure?
    assert_equal "must be cool, warm or no_preference", result.errors.to_h[:preferences][:temperature_preference].first.text
  end

  def test_invalid_movement_preference
    result = @contract.call(preferences: { movement_preference: "invalid" })

    assert result.failure?
    assert_equal "must be very_little, moderate, a_lot or as_much_as_possible", result.errors.to_h[:preferences][:movement_preference].first.text
  end

  def test_invalid_rhythm_importance
    result = @contract.call(preferences: { rhythm_importance: 6 })

    assert result.failure?
    assert_equal "must be between 1 and 5", result.errors.to_h[:preferences][:rhythm_importance].first.text
  end

  def test_invalid_self_chronotype
    result = @contract.call(preferences: { self_chronotype: "invalid" })

    assert result.failure?
    assert_equal "must be morning, night or depends", result.errors.to_h[:preferences][:self_chronotype].first.text
  end
end
