# frozen_string_literal: true

require "test_helper"

class PreferenceProfileTest < ActiveSupport::TestCase
  test "valid preference profile" do
    assert preference_profiles(:alice_prefs).valid?
  end

  test "valid without travel_style" do
    pref = preference_profiles(:alice_prefs)
    pref.travel_style = nil
    assert pref.valid?
  end

  test "valid without visual_embedding" do
    pref = preference_profiles(:alice_prefs)
    pref.visual_embedding = nil
    assert pref.valid?
  end

  test "belongs to user" do
    assert_equal users(:alice), preference_profiles(:alice_prefs).user
  end
end
