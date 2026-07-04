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

  test "valid without any declared preference field" do
    pref = preference_profiles(:alice_prefs)
    pref.sleep_together_importance = nil
    pref.rhythm_importance = nil
    pref.temperature_preference = nil
    pref.movement_preference = nil
    pref.self_chronotype = nil
    assert pref.valid?
  end

  test "invalid when sleep_together_importance is below 1" do
    pref = preference_profiles(:alice_prefs)
    pref.sleep_together_importance = 0
    assert_not pref.valid?
  end

  test "invalid when sleep_together_importance is above 5" do
    pref = preference_profiles(:alice_prefs)
    pref.sleep_together_importance = 6
    assert_not pref.valid?
  end

  test "invalid when rhythm_importance is out of range" do
    pref = preference_profiles(:alice_prefs)
    pref.rhythm_importance = 6
    assert_not pref.valid?
  end

  test "temperature_preference enum values match schema integers" do
    assert_equal 0, PreferenceProfile.temperature_preferences[:cool]
    assert_equal 1, PreferenceProfile.temperature_preferences[:warm]
    assert_equal 2, PreferenceProfile.temperature_preferences[:no_preference]
  end

  test "movement_preference enum values match schema integers" do
    assert_equal 0, PreferenceProfile.movement_preferences[:very_little]
    assert_equal 1, PreferenceProfile.movement_preferences[:moderate]
    assert_equal 2, PreferenceProfile.movement_preferences[:a_lot]
    assert_equal 3, PreferenceProfile.movement_preferences[:as_much_as_possible]
  end

  test "self_chronotype enum values match schema integers" do
    assert_equal 0, PreferenceProfile.self_chronotypes[:morning]
    assert_equal 1, PreferenceProfile.self_chronotypes[:night]
    assert_equal 2, PreferenceProfile.self_chronotypes[:depends]
  end

  test "belongs to user" do
    assert_equal users(:alice), preference_profiles(:alice_prefs).user
  end
end
