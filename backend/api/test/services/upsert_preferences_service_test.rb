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

    assert result.success?
    assert_equal 3, user.reload.preference_profile.sleep_together_importance
  end

  test "updates existing preference_profile on second call" do
    user = users(:alice)
    original_count = PreferenceProfile.count

    result = UpsertPreferencesService.call(
      current_user: user,
      attrs: { rhythm_importance: 4 }
    )

    assert result.success?
    assert_equal original_count, PreferenceProfile.count
    assert_equal 4, user.reload.preference_profile.rhythm_importance
  end

  test "partial update leaves untouched fields unchanged" do
    user = users(:alice)
    original_prefs = user.preference_profile.attributes.symbolize_keys

    result = UpsertPreferencesService.call(
      current_user: user,
      attrs: { sleep_together_importance: 2 }
    )

    assert result.success?
    updated_prefs = user.reload.preference_profile.attributes.symbolize_keys

    assert_equal 2, updated_prefs[:sleep_together_importance]
    assert_equal original_prefs[:rhythm_importance], updated_prefs[:rhythm_importance]
    assert_equal original_prefs[:temperature_preference], updated_prefs[:temperature_preference]
    assert_equal original_prefs[:movement_preference], updated_prefs[:movement_preference]
    assert_equal original_prefs[:self_chronotype], updated_prefs[:self_chronotype]
  end

  test "returns failure when record is invalid" do
    user = users(:alice)

    result = UpsertPreferencesService.call(
      current_user: user,
      attrs: { sleep_together_importance: 6 }
    )

    assert result.failure?
    assert_equal :validation_failed, result.failure.first
  end
end
