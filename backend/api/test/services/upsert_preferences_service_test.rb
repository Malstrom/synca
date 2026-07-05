# frozen_string_literal: true

require "test_helper"

# UpsertPreferencesService receives already-validated attrs from UpsertPreferencesContract.
# Failure scenarios (invalid enum values, out-of-range numerics) are tested in
# upsert_preferences_contract_test.rb and preferences_controller_test.rb.
class UpsertPreferencesServiceTest < ActiveSupport::TestCase
  include Dry::Monads[:result]

  setup do
    @user = users(:alice)
  end

  def valid_attrs
    {
      sleep_together_importance: 3,
      temperature_preference: "cool",
      movement_preference: "moderate",
      rhythm_importance: 4,
      self_chronotype: "night"
    }
  end

  test "returns Success with the preference_profile record on valid attrs" do
    result = UpsertPreferencesService.call(current_user: @user, attrs: valid_attrs)
    assert result.success?, "expected Success, got #{result.inspect}"
  end

  test "Success wraps the persisted PreferenceProfile" do
    result = UpsertPreferencesService.call(current_user: @user, attrs: valid_attrs)
    assert result.success?, "expected Success, got #{result.inspect}"

    preference_profile = result.value!
    assert_instance_of PreferenceProfile, preference_profile
    assert preference_profile.persisted?
  end

  test "updates an existing preference_profile" do
    result = UpsertPreferencesService.call(
      current_user: @user,
      attrs: valid_attrs.merge(temperature_preference: "warm")
    )

    assert result.success?, "expected Success, got #{result.inspect}"
    assert_equal "warm", result.value!.reload.temperature_preference
  end

  test "creates preference_profile when user has none" do
    user_without_prefs = users(:charlie)

    result = UpsertPreferencesService.call(current_user: user_without_prefs, attrs: valid_attrs)
    assert result.success?, "expected Success, got #{result.inspect}"
    assert result.value!.persisted?
  end

  test "partial update only updates specified fields" do
    initial_attrs = valid_attrs
    result = UpsertPreferencesService.call(current_user: @user, attrs: initial_attrs)
    assert result.success?

    partial_attrs = { sleep_together_importance: 5 }
    result = UpsertPreferencesService.call(current_user: @user, attrs: partial_attrs)
    assert result.success?

    updated_profile = result.value!.reload
    assert_equal 5, updated_profile.sleep_together_importance
    assert_equal "cool", updated_profile.temperature_preference
    assert_equal "moderate", updated_profile.movement_preference
    assert_equal 4, updated_profile.rhythm_importance
    assert_equal "night", updated_profile.self_chronotype
  end
end
