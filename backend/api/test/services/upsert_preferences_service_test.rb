# frozen_string_literal: true

require "test_helper"

class UpsertPreferencesServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:alice)
    @attrs = {
      sleep_together_importance: 3,
      temperature_preference: "cool",
      movement_preference: "moderate",
      rhythm_importance: 4,
      self_chronotype: "night"
    }
  end

  test "upsert creates new preference profile" do
    @user.preference_profile.destroy
    result = UpsertPreferencesService.call(current_user: @user, attrs: @attrs)
    assert_pattern { result => Success(preference_profile) }
    assert_equal @user, preference_profile.user
    assert_equal 3, preference_profile.sleep_together_importance
    assert_equal "cool", preference_profile.temperature_preference
  end

  test "upsert updates existing preference profile" do
    result = UpsertPreferencesService.call(current_user: @user, attrs: @attrs)
    assert_pattern { result => Success(preference_profile) }
    assert_equal @user, preference_profile.user
    assert_equal 3, preference_profile.sleep_together_importance
  end

  test "upsert with partial attributes" do
    partial_attrs = { sleep_together_importance: 2, rhythm_importance: 5 }
    result = UpsertPreferencesService.call(current_user: @user, attrs: partial_attrs)
    assert_pattern { result => Success(preference_profile) }
    assert_equal 2, preference_profile.sleep_together_importance
    assert_equal 5, preference_profile.rhythm_importance
    assert_nil preference_profile.temperature_preference
  end

  test "upsert with invalid attributes" do
    invalid_attrs = { sleep_together_importance: 6 }
    result = UpsertPreferencesService.call(current_user: @user, attrs: invalid_attrs)
    assert_pattern { result => Failure[:validation_failed, _] }
  end
end
