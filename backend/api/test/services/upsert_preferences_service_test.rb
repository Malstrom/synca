# frozen_string_literal: true

require "test_helper"

class UpsertPreferencesServiceTest < ActiveSupport::TestCase
  test "success — first save" do
    user = users(:bob)

    result = UpsertPreferencesService.call(
      current_user: user,
      params: {
        "preferences" => {
          "sleep_together_importance" => 4,
          "temperature_preference"   => "cool",
          "movement_preference"      => "moderate",
          "rhythm_importance"        => 3,
          "self_chronotype"          => "night"
        }
      }
    )

    assert result.success?
    assert_equal 4,          result.value!.sleep_together_importance
    assert_equal "cool",     result.value!.temperature_preference
    assert_equal "moderate", result.value!.movement_preference
    assert_equal 3,          result.value!.rhythm_importance
    assert_equal "night",    result.value!.self_chronotype
  end

  test "partial update preserves existing fields" do
    user = users(:alice)

    result = UpsertPreferencesService.call(
      current_user: user,
      params: { "preferences" => { "sleep_together_importance" => 2 } }
    )

    assert result.success?
    assert_equal 2,      result.value!.sleep_together_importance
    assert_equal "cool", result.value!.temperature_preference
  end

  test "contract invalid — unknown preference key" do
    user = users(:alice)

    result = UpsertPreferencesService.call(
      current_user: user,
      params: { "preferences" => { "sleep_together_importance" => 99 } }
    )

    assert result.failure?
    assert_equal :contract_invalid, result.failure.first
  end
end
