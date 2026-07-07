# frozen_string_literal: true

require "test_helper"

class UpsertPreferencesContractTest < ActiveSupport::TestCase
  # Shorthand for contract error messages
  def t(field, rule)
    I18n.t("contracts.errors.upsert_preferences.#{field}.#{rule}")
  end

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
    assert_includes result.errors.to_h.dig(:preferences, :sleep_together_importance),
      t(:sleep_together_importance, :inclusion)
  end

  test "invalid temperature_preference" do
    result = UpsertPreferencesContract.new.call(
      preferences: { temperature_preference: "invalid" }
    )

    assert result.failure?
    assert_includes result.errors.to_h.dig(:preferences, :temperature_preference),
      t(:temperature_preference, :inclusion)
  end

  test "invalid movement_preference" do
    result = UpsertPreferencesContract.new.call(
      preferences: { movement_preference: "invalid" }
    )

    assert result.failure?
    assert_includes result.errors.to_h.dig(:preferences, :movement_preference),
      t(:movement_preference, :inclusion)
  end

  test "invalid rhythm_importance" do
    result = UpsertPreferencesContract.new.call(
      preferences: { rhythm_importance: 6 }
    )

    assert result.failure?
    assert_includes result.errors.to_h.dig(:preferences, :rhythm_importance),
      t(:rhythm_importance, :inclusion)
  end

  test "invalid self_chronotype" do
    result = UpsertPreferencesContract.new.call(
      preferences: { self_chronotype: "invalid" }
    )

    assert result.failure?
    assert_includes result.errors.to_h.dig(:preferences, :self_chronotype),
      t(:self_chronotype, :inclusion)
  end
end
