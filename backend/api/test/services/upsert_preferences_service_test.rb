# frozen_string_literal: true

require "test_helper"

class UpsertPreferencesServiceTest < ActiveSupport::TestCase
  test "creates preference_profile when user has none" do
    user = users(:charlie)
    assert_nil user.preference_profile

    result = UpsertPreferencesService.call(
      current_user: user,
      attrs: { sleep_together_importance: 3 }
    )

    assert_predicate result, :success?
    assert_equal 3, user.reload.preference_profile.sleep_together_importance
  end

  test "updates existing preference_profile on second call" do
    user = users(:alice)
    original_count = PreferenceProfile.count

    result = UpsertPreferencesService.call(
      current_user: user,
      attrs: { rhythm_importance: 4 }
    )

    assert_predicate result, :success?
    assert_equal original_count, PreferenceProfile.count
    assert_equal 4, user.reload.preference_profile.rhythm_importance
  end

  test "partial update leaves untouched fields unchanged" do
    user = users(:alice)
    original_profile = user.preference_profile
    original_profile.update!(
      sleep_together_importance: 3,
      rhythm_importance: 4,
      temperature_preference: "cool"
    )

    result = UpsertPreferencesService.call(
      current_user: user,
      attrs: { sleep_together_importance: 5 }
    )

    assert_predicate result, :success?
    updated_profile = user.reload.preference_profile
    assert_equal 5, updated_profile.sleep_together_importance
    assert_equal 4, updated_profile.rhythm_importance
    assert_equal "cool", updated_profile.temperature_preference
  end

  test "returns failure when record is invalid" do
    user = users(:alice)

    result = UpsertPreferencesService.call(
      current_user: user,
      attrs: { sleep_together_importance: 6 }
    )

    assert_predicate result, :failure?
    assert_equal :validation_failed, result.failure.first
  end
end
