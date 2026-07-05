# frozen_string_literal: true

require "test_helper"

class PreferenceProfileTest < ActiveSupport::TestCase
  setup do
    @user = users(:alice)
    @preference_profile = @user.preference_profile || @user.build_preference_profile
  end

  test "validates sleep_together_importance range" do
    @preference_profile.sleep_together_importance = 6
    assert_not @preference_profile.valid?
    assert_includes @preference_profile.errors[:sleep_together_importance], "must be between 1 and 5"
  end

  test "validates rhythm_importance range" do
    @preference_profile.rhythm_importance = 0
    assert_not @preference_profile.valid?
    assert_includes @preference_profile.errors[:rhythm_importance], "must be between 1 and 5"
  end

  test "allows nil values for all fields" do
    assert @preference_profile.valid?
  end

  test "enum values for temperature_preference" do
    assert_equal "cool", @preference_profile.temperature_preference = :cool
    assert_equal "warm", @preference_profile.temperature_preference = :warm
    assert_equal "no_preference", @preference_profile.temperature_preference = :no_preference
  end

  test "enum values for movement_preference" do
    assert_equal "very_little", @preference_profile.movement_preference = :very_little
    assert_equal "moderate", @preference_profile.movement_preference = :moderate
    assert_equal "a_lot", @preference_profile.movement_preference = :a_lot
    assert_equal "as_much_as_possible", @preference_profile.movement_preference = :as_much_as_possible
  end

  test "enum values for self_chronotype" do
    assert_equal "morning", @preference_profile.self_chronotype = :morning
    assert_equal "night", @preference_profile.self_chronotype = :night
    assert_equal "depends", @preference_profile.self_chronotype = :depends
  end
end
