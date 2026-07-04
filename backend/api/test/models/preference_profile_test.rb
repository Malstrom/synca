# frozen_string_literal: true

require "test_helper"

class PreferenceProfileTest < ActiveSupport::TestCase
  setup do
    @user = users(:alice)
    @preference_profile = @user.preference_profile
  end

  test "valid preference profile" do
    @preference_profile.update(
      sleep_together_importance: 3,
      temperature_preference: :cool,
      movement_preference: :moderate,
      rhythm_importance: 4,
      self_chronotype: :night
    )
    assert @preference_profile.valid?
  end

  test "invalid sleep_together_importance" do
    @preference_profile.sleep_together_importance = 6
    assert_not @preference_profile.valid?
    assert_includes @preference_profile.errors[:sleep_together_importance], "must be in 1..5"
  end

  test "invalid rhythm_importance" do
    @preference_profile.rhythm_importance = 0
    assert_not @preference_profile.valid?
    assert_includes @preference_profile.errors[:rhythm_importance], "must be in 1..5"
  end

  test "nil fields are allowed" do
    @preference_profile.update(
      sleep_together_importance: nil,
      temperature_preference: nil,
      movement_preference: nil,
      rhythm_importance: nil,
      self_chronotype: nil
    )
    assert @preference_profile.valid?
  end
end
