# frozen_string_literal: true

require "test_helper"

class UpsertPreferencesServiceTest < ActiveSupport::TestCase
  include Dry::Monads[:result]

  setup do
    @user = users(:alice)
  end

  test "successful update" do
    result = UpsertPreferencesService.call(
      current_user: @user,
      attrs: {
        sleep_together_importance: 3,
        temperature_preference: "cool",
        movement_preference: "moderate",
        rhythm_importance: 4,
        self_chronotype: "night"
      }
    )
    assert_pattern { result => Success }
    assert_equal 3, result.value!.sleep_together_importance
    assert_equal "cool", result.value!.temperature_preference
    assert_equal "moderate", result.value!.movement_preference
    assert_equal 4, result.value!.rhythm_importance
    assert_equal "night", result.value!.self_chronotype
  end

  test "validation failed" do
    result = UpsertPreferencesService.call(
      current_user: @user,
      attrs: { sleep_together_importance: 6 }
    )
    assert_pattern { result => Failure }
    assert_equal :validation_failed, result.failure.first
  end
end
