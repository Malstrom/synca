# frozen_string_literal: true

require "test_helper"

class UpsertPreferencesServiceTest < ActiveSupport::TestCase
  include Dry::Monads[:result]

  setup do
    @user = users(:alice)
  end

  test "upsert create" do
    PreferenceProfile.where(user: @user).delete_all

    result = UpsertPreferencesService.call(
      current_user: @user,
      attrs: {
        sleep_together_importance: 3,
        temperature_preference: "warm",
        movement_preference: "a_lot",
        rhythm_importance: 4,
        self_chronotype: "depends"
      }
    )

    assert_pattern { result => Success }
    profile = result.value!

    assert_equal 3, profile.sleep_together_importance
    assert_equal :warm, profile.temperature_preference
    assert_equal :a_lot, profile.movement_preference
    assert_equal 4, profile.rhythm_importance
    assert_equal :depends, profile.self_chronotype
  end

  test "upsert update" do
    profile = preference_profiles(:alice_prefs)
    original_temperature = profile.temperature_preference

    result = UpsertPreferencesService.call(
      current_user: @user,
      attrs: { temperature_preference: "cool" }
    )

    assert_pattern { result => Success }
    profile.reload

    assert_equal :cool, profile.temperature_preference
    assert_equal original_temperature, profile.temperature_preference_was
  end

  test "partial update" do
    profile = preference_profiles(:alice_prefs)
    original_sleep_importance = profile.sleep_together_importance

    result = UpsertPreferencesService.call(
      current_user: @user,
      attrs: { rhythm_importance: 2 }
    )

    assert_pattern { result => Success }
    profile.reload

    assert_equal 2, profile.rhythm_importance
    assert_equal original_sleep_importance, profile.sleep_together_importance
  end

  test "validation failure" do
    result = UpsertPreferencesService.call(
      current_user: @user,
      attrs: { sleep_together_importance: 6 }
    )

    assert_pattern { result => Failure }
    assert_equal :validation_failed, result.failure.first
    assert_includes result.failure.last, "Sleep together importance must be between 1 and 5"
  end
end
