# frozen_string_literal: true

require "test_helper"

class UpsertPreferencesContractTest < ActiveSupport::TestCase
  def test_valid_all_fields
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

  def test_valid_partial_fields
    result = UpsertPreferencesContract.new.call(
      preferences: {
        sleep_together_importance: 2,
        temperature_preference: "warm"
      }
    )

    assert result.success?
  end

  def test_valid_empty_preferences
    result = UpsertPreferencesContract.new.call(preferences: {})

    assert result.success?
  end

  def test_invalid_sleep_together_importance_too_high
    result = UpsertPreferencesContract.new.call(
      preferences: { sleep_together_importance: 6 }
    )

    assert result.failure?
    assert result.errors[:preferences][:sleep_together_importance].present?
  end

  def test_invalid_sleep_together_importance_too_low
    result = UpsertPreferencesContract.new.call(
      preferences: { sleep_together_importance: 0 }
    )

    assert result.failure?
    assert result.errors[:preferences][:sleep_together_importance].present?
  end

  def test_invalid_temperature_preference
    result = UpsertPreferencesContract.new.call(
      preferences: { temperature_preference: "invalid" }
    )

    assert result.failure?
    assert result.errors[:preferences][:temperature_preference].present?
  end

  def test_valid_temperature_preference_cool
    result = UpsertPreferencesContract.new.call(
      preferences: { temperature_preference: "cool" }
    )

    assert result.success?
  end

  def test_valid_temperature_preference_warm
    result = UpsertPreferencesContract.new.call(
      preferences: { temperature_preference: "warm" }
    )

    assert result.success?
  end

  def test_valid_temperature_preference_no_preference
    result = UpsertPreferencesContract.new.call(
      preferences: { temperature_preference: "no_preference" }
    )

    assert result.success?
  end

  def test_invalid_movement_preference
    result = UpsertPreferencesContract.new.call(
      preferences: { movement_preference: "extreme" }
    )

    assert result.failure?
    assert result.errors[:preferences][:movement_preference].present?
  end

  def test_valid_movement_preference_very_little
    result = UpsertPreferencesContract.new.call(
      preferences: { movement_preference: "very_little" }
    )

    assert result.success?
  end

  def test_valid_movement_preference_as_much_as_possible
    result = UpsertPreferencesContract.new.call(
      preferences: { movement_preference: "as_much_as_possible" }
    )

    assert result.success?
  end

  def test_invalid_rhythm_importance_too_high
    result = UpsertPreferencesContract.new.call(
      preferences: { rhythm_importance: 10 }
    )

    assert result.failure?
    assert result.errors[:preferences][:rhythm_importance].present?
  end

  def test_invalid_self_chronotype
    result = UpsertPreferencesContract.new.call(
      preferences: { self_chronotype: "lazy" }
    )

    assert result.failure?
    assert result.errors[:preferences][:self_chronotype].present?
  end

  def test_valid_self_chronotype_morning
    result = UpsertPreferencesContract.new.call(
      preferences: { self_chronotype: "morning" }
    )

    assert result.success?
  end

  def test_valid_self_chronotype_depends
    result = UpsertPreferencesContract.new.call(
      preferences: { self_chronotype: "depends" }
    )

    assert result.success?
  end
end
