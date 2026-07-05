# frozen_string_literal: true

require "test_helper"

class UpsertPreferencesServiceTest < ActiveSupport::TestCase
  include Dry::Monads[:result]

  setup do
    @user = users(:alice)
  end

  test "upsert creates new record" do
    PreferenceProfile.destroy_all
    result = UpsertPreferencesService.call(
      current_user: @user,
      attrs: { sleep_together_importance: 3 }
    )
    assert_pattern { result => Success }
    assert_equal 3, result.value!.sleep_together_importance
  end

  test "upsert updates existing record" do
    result = UpsertPreferencesService.call(
      current_user: @user,
      attrs: { temperature_preference: "warm" }
    )
    assert_pattern { result => Success }
    assert_equal "warm", result.value!.temperature_preference
  end

  test "partial update" do
    result = UpsertPreferencesService.call(
      current_user: @user,
      attrs: { movement_preference: "a_lot" }
    )
    assert_pattern { result => Success }
    assert_equal "a_lot", result.value!.movement_preference
    assert_nil result.value!.rhythm_importance
  end

  test "validation failure" do
    result = UpsertPreferencesService.call(
      current_user: @user,
      attrs: { rhythm_importance: 6 }
    )
    assert_pattern { result => Failure }
    assert_equal :validation_failed, result.failure.first
  end
end
