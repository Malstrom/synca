# frozen_string_literal: true

require "test_helper"

class UpsertPreferencesServiceTest < ActiveSupport::TestCase
  include Dry::Monads[:result]

  setup do
    @user = users(:alice)
  end

  test "upsert create" do
    result = UpsertPreferencesService.call(
      current_user: @user,
      attrs: {
        sleep_together_importance: 3,
        temperature_preference: "cool"
      }
    )

    assert_pattern { result => Success }
    assert_equal 3, result.value.sleep_together_importance
    assert_equal "cool", result.value.temperature_preference
  end

  test "upsert update" do
    PreferenceProfile.create!(
      user: @user,
      sleep_together_importance: 2,
      temperature_preference: "warm"
    )

    result = UpsertPreferencesService.call(
      current_user: @user,
      attrs: {
        sleep_together_importance: 4,
        movement_preference: "a_lot"
      }
    )

    assert_pattern { result => Success }
    assert_equal 4, result.value.sleep_together_importance
    assert_equal "warm", result.value.temperature_preference # unchanged
    assert_equal "a_lot", result.value.movement_preference
  end

  test "partial update" do
    PreferenceProfile.create!(
      user: @user,
      sleep_together_importance: 2,
      temperature_preference: "warm"
    )

    result = UpsertPreferencesService.call(
      current_user: @user,
      attrs: { rhythm_importance: 5 }
    )

    assert_pattern { result => Success }
    assert_equal 2, result.value.sleep_together_importance # unchanged
    assert_equal "warm", result.value.temperature_preference # unchanged
    assert_equal 5, result.value.rhythm_importance
  end

  test "validation failed" do
    result = UpsertPreferencesService.call(
      current_user: @user,
      attrs: { rhythm_importance: 6 }
    )

    assert_pattern { result => Failure }
    assert_equal :validation_failed, result.failure.first
  end
end
