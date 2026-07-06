# frozen_string_literal: true

require "test_helper"

class UpsertPreferencesServiceTest < ActiveSupport::TestCase
  def setup
    @user = users(:alice)
    @attrs = {
      sleep_together_importance: 3,
      temperature_preference: "cool",
      movement_preference: "moderate",
      rhythm_importance: 4,
      self_chronotype: "night"
    }
  end

  def test_success
    result = UpsertPreferencesService.call(current_user: @user, attrs: @attrs)

    case result
    in Success[ preference_profile ]
      assert_equal @attrs[:sleep_together_importance], preference_profile.sleep_together_importance
      assert_equal @attrs[:temperature_preference], preference_profile.temperature_preference
      assert_equal @attrs[:movement_preference], preference_profile.movement_preference
      assert_equal @attrs[:rhythm_importance], preference_profile.rhythm_importance
      assert_equal @attrs[:self_chronotype], preference_profile.self_chronotype
    else
      assert false, "Expected Success, got #{result.inspect}"
    end
  end

  def test_validation_failed
    invalid_attrs = @attrs.merge(sleep_together_importance: 6)
    result = UpsertPreferencesService.call(current_user: @user, attrs: invalid_attrs)

    case result
    in Failure[ :validation_failed, message ]
      assert_equal "Sleep together importance is not included in the list", message
    else
      assert false, "Expected Failure, got #{result.inspect}"
    end
  end
end
