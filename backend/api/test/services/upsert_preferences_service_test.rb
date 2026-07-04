# frozen_string_literal: true

require "test_helper"

class UpsertPreferencesServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:alice)
  end

  def test_create_new_preference_profile
    # Ensure alice doesn't have a preference_profile yet
    @user.preference_profile&.destroy
    @user.reload

    attrs = { temperature_preference: "cool", sleep_together_importance: 4 }
    result = UpsertPreferencesService.call(current_user: @user, attrs:)

    assert result.success?
    assert result.value!.temperature_preference == "cool"
    assert result.value!.sleep_together_importance == 4
    assert @user.preference_profile.persisted?
  end

  def test_update_existing_preference_profile
    prefs = preference_profiles(:alice_prefs)
    attrs = { temperature_preference: "warm", rhythm_importance: 2 }

    result = UpsertPreferencesService.call(current_user: @user, attrs:)

    assert result.success?
    assert result.value!.temperature_preference == "warm"
    assert result.value!.rhythm_importance == 2
    assert result.value!.id == prefs.id
  end

  def test_partial_update
    prefs = preference_profiles(:alice_prefs)
    original_travel_style = prefs.travel_style

    attrs = { temperature_preference: "cool" }
    result = UpsertPreferencesService.call(current_user: @user, attrs:)

    assert result.success?
    assert result.value!.temperature_preference == "cool"
    assert result.value!.travel_style == original_travel_style
  end

  def test_invalid_sleep_together_importance
    attrs = { sleep_together_importance: 10 }
    result = UpsertPreferencesService.call(current_user: @user, attrs:)

    assert result.failure?
    assert result.failure.first == :validation_failed
    assert result.failure.last.include?("Sleep together importance")
  end

  def test_nil_values_allowed
    attrs = { temperature_preference: nil, movement_preference: nil }
    result = UpsertPreferencesService.call(current_user: @user, attrs:)

    assert result.success?
  end
end
