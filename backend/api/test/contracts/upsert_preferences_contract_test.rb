# frozen_string_literal: true

require "test_helper"

class UpsertPreferencesContractTest < ApiTestCase
  def test_success
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

  def test_invalid_temperature_preference
    result = UpsertPreferencesContract.new.call(
      preferences: { temperature_preference: "invalid" }
    )

    assert result.failure?
    assert_equal "must be cool, warm or no_preference", result.errors[:preferences][:temperature_preference].first.text
  end

  def test_invalid_movement_preference
    result = UpsertPreferencesContract.new.call(
      preferences: { movement_preference: "invalid" }
    )

    assert result.failure?
    assert_equal "must be very_little, moderate, a_lot or as_much_as_possible", result.errors[:preferences][:movement_preference].first.text
  end

  def test_invalid_self_chronotype
    result = UpsertPreferencesContract.new.call(
      preferences: { self_chronotype: "invalid" }
    )

    assert result.failure?
    assert_equal "must be morning, night or depends", result.errors[:preferences][:self_chronotype].first.text
  end

  def test_invalid_sleep_together_importance
    result = UpsertPreferencesContract.new.call(
      preferences: { sleep_together_importance: 6 }
    )

    assert result.failure?
    assert_equal "must be between 1 and 5", result.errors[:preferences][:sleep_together_importance].first.text
  end

  def test_invalid_rhythm_importance
    result = UpsertPreferencesContract.new.call(
      preferences: { rhythm_importance: 0 }
    )

    assert result.failure?
    assert_equal "must be between 1 and 5", result.errors[:preferences][:rhythm_importance].first.text
  end
end
