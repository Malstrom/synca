# frozen_string_literal: true

require "test_helper"

class UpsertPreferencesServiceTest < ActiveSupport::TestCase
  def setup
    @user = users(:alice)
    @attrs = {
      sleep_together_importance: 3,
      temperature_preference: "cool",
      movement_preference: "moderate",
      rhythm_importance: 4,
      self_chronotype: "night"
    }
  end

  test "upserts preferences" do
    result = UpsertPreferencesService.call(current_user: @user, attrs: @attrs)

    assert_pattern { result => Success(preference_profile) }
    assert_equal 3, preference_profile.sleep_together_importance
    assert_equal "cool", preference_profile.temperature_preference
    assert_equal "moderate", preference_profile.movement_preference
    assert_equal 4, preference_profile.rhythm_importance
    assert_equal "night", preference_profile.self_chronotype
  end

  test "partial upsert" do
    result = UpsertPreferencesService.call(
      current_user: @user,
      attrs: { sleep_together_importance: 3 }
    )

    assert_pattern { result => Success(preference_profile) }
    assert_equal 3, preference_profile.sleep_together_importance
    assert_nil preference_profile.temperature_preference
    assert_nil preference_profile.movement_preference
    assert_nil preference_profile.rhythm_importance
    assert_nil preference_profile.self_chronotype
  end

  test "validation failed" do
    result = UpsertPreferencesService.call(
      current_user: @user,
      attrs: { sleep_together_importance: 6 }
    )

    assert_pattern { result => Failure[:validation_failed, _] }
  end
end