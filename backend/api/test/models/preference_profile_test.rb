# frozen_string_literal: true

require "test_helper"

class PreferenceProfileTest < ActiveSupport::TestCase
  setup do
    @user = users(:alice)
    @preference_profile = @user.preference_profile || @user.create_preference_profile
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
    assert @preference_profile.update(
      sleep_together_importance: nil,
      temperature_preference: nil,
      movement_preference: nil,
      rhythm_importance: nil,
      self_chronotype: nil
    )
  end

  test "enum values are correctly mapped" do
    @preference_profile.update(
      temperature_preference: :cool,
      movement_preference: :moderate,
      self_chronotype: :morning
    )

    assert_equal "cool", @preference_profile.temperature_preference
    assert_equal "moderate", @preference_profile.movement_preference
    assert_equal "morning", @preference_profile.self_chronotype
  end
end
