# frozen_string_literal: true

require "test_helper"

class UpsertPreferencesServiceTest < ActiveSupport::TestCase
  include Dry::Monads[:result]

  def setup
    @user = users(:alice)
    @service = UpsertPreferencesService.new
  end

  test "upsert create" do
    PreferenceProfile.find_by(user: @user).destroy!

    attrs = {
      sleep_together_importance: 3,
      temperature_preference: "cool",
      movement_preference: "moderate",
      rhythm_importance: 4,
      self_chronotype: "night"
    }

    result = @service.call(current_user: @user, attrs: attrs)
    assert_pattern { result => Success }

    profile = result.value!
    assert_equal @user, profile.user
    assert_equal 3, profile.sleep_together_importance
    assert_equal "cool", profile.temperature_preference
    assert_equal "moderate", profile.movement_preference
    assert_equal 4, profile.rhythm_importance
    assert_equal "night", profile.self_chronotype
  end

  test "upsert update" do
    profile = PreferenceProfile.find_by(user: @user)
    profile.update!(
      sleep_together_importance: 1,
      temperature_preference: "warm",
      movement_preference: "very_little",
      rhythm_importance: 2,
      self_chronotype: "morning"
    )

    attrs = {
      sleep_together_importance: 3,
      temperature_preference: "cool",
      movement_preference: "moderate",
      rhythm_importance: 4,
      self_chronotype: "night"
    }

    result = @service.call(current_user: @user, attrs: attrs)
    assert_pattern { result => Success }

    profile.reload
    assert_equal 3, profile.sleep_together_importance
    assert_equal "cool", profile.temperature_preference
    assert_equal "moderate", profile.movement_preference
    assert_equal 4, profile.rhythm_importance
    assert_equal "night", profile.self_chronotype
  end

  test "partial update" do
    profile = PreferenceProfile.find_by(user: @user)
    profile.update!(
      sleep_together_importance: 1,
      temperature_preference: "warm",
      movement_preference: "very_little",
      rhythm_importance: 2,
      self_chronotype: "morning"
    )

    attrs = {
      sleep_together_importance: 3
    }

    result = @service.call(current_user: @user, attrs: attrs)
    assert_pattern { result => Success }

    profile.reload
    assert_equal 3, profile.sleep_together_importance
    assert_equal "warm", profile.temperature_preference
    assert_equal "very_little", profile.movement_preference
    assert_equal 2, profile.rhythm_importance
    assert_equal "morning", profile.self_chronotype
  end
end
