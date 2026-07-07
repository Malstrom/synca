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
    assert_includes result.errors.to_h.dig(:preferences, :sleep_together_importance),
      I18n.t("contracts.errors.sleep_together_importance.inclusion")
  end

  test "invalid temperature_preference" do
    result = UpsertPreferencesContract.new.call(
      preferences: { temperature_preference: "invalid" }
    )

    assert result.failure?
    assert_includes result.errors.to_h.dig(:preferences, :temperature_preference),
      I18n.t("contracts.errors.temperature_preference.inclusion")
  end

  test "invalid movement_preference" do
    result = UpsertPreferencesContract.new.call(
      preferences: { movement_preference: "invalid" }
    )

    assert result.failure?
    assert_includes result.errors.to_h.dig(:preferences, :movement_preference),
      I18n.t("contracts.errors.movement_preference.inclusion")
  end

  test "invalid rhythm_importance" do
    result = UpsertPreferencesContract.new.call(
      preferences: { rhythm_importance: 6 }
    )

    assert result.failure?
    assert_includes result.errors.to_h.dig(:preferences, :rhythm_importance),
      I18n.t("contracts.errors.rhythm_importance.inclusion")
  end

  test "invalid self_chronotype" do
    result = UpsertPreferencesContract.new.call(
      preferences: { self_chronotype: "invalid" }
    )

    assert result.failure?
    assert_includes result.errors.to_h.dig(:preferences, :self_chronotype),
      I18n.t("contracts.errors.self_chronotype.inclusion")
  end
end
