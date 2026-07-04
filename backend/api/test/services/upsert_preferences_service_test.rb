# frozen_string_literal: true

require "test_helper"

class UpsertPreferencesServiceTest < ActiveSupport::TestCase
  test "creates preference_profile when user has none" do
    user = users(:alice)
    user.preference_profile.destroy! if user.preference_profile

    attrs = {
      sleep_together_importance: 3,
      temperature_preference: "cool"
    }

    result = UpsertPreferencesService.call(current_user: user, attrs: attrs)

    assert result.success?
    assert_equal 3, user.preference_profile.sleep_together_importance
    assert_equal "cool", user.preference_profile.temperature_preference
  end

  test "updates existing preference_profile on second call" do
    user = users(:alice)
    initial_count = PreferenceProfile.count

    attrs = {
      sleep_together_importance: 4,
      rhythm_importance: 5
    }

    result = UpsertPreferencesService.call(current_user: user, attrs: attrs)

    assert result.success?
    assert_equal initial_count, PreferenceProfile.count
    assert_equal 4, user.preference_profile.sleep_together_importance
    assert_equal 5, user.preference_profile.rhythm_importance
  end

  test "partial update leaves untouched fields unchanged" do
    user = users(:alice)
    user.preference_profile.update!(
      sleep_together_importance: 2,
      rhythm_importance: 3,
      temperature_preference: "warm"
    )

    attrs = {
      rhythm_importance: 4
    }

    result = UpsertPreferencesService.call(current_user: user, attrs: attrs)

    assert result.success?
    assert_equal 2, user.preference_profile.sleep_together_importance
    assert_equal 4, user.preference_profile.rhythm_importance
    assert_equal "warm", user.preference_profile.temperature_preference
  end

  test "returns failure when record is invalid" do
    user = users(:alice)

    attrs = {
      sleep_together_importance: 6
    }

    result = UpsertPreferencesService.call(current_user: user, attrs: attrs)

    assert result.failure?
    assert_equal :validation_failed, result.failure[0]
  end
end
