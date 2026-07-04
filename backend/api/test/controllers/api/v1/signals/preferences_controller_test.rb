# frozen_string_literal: true

require "test_helper"

class Api::V1::Signals::PreferencesControllerTest < ApiTestCase
  def test_success
    post_json "/api/v1/signals/preferences", {
      preferences: {
        sleep_together_importance: 4,
        temperature_preference: "cool",
        movement_preference: "moderate",
        rhythm_importance: 3,
        self_chronotype: "night"
      }
    }, auth_headers(users(:alice))

    assert_response :success
    assert_equal 4, response.parsed_body["preferences"]["sleep_together_importance"]
    assert_equal "cool", response.parsed_body["preferences"]["temperature_preference"]
    assert_equal "moderate", response.parsed_body["preferences"]["movement_preference"]
    assert_equal 3, response.parsed_body["preferences"]["rhythm_importance"]
    assert_equal "night", response.parsed_body["preferences"]["self_chronotype"]
  end

  def test_unauthorized
    post_json "/api/v1/signals/preferences", {
      preferences: {
        sleep_together_importance: 4
      }
    }

    assert_response :unauthorized
  end

  def test_validation_failed
    post_json "/api/v1/signals/preferences", {
      preferences: {
        sleep_together_importance: 6
      }
    }, auth_headers(users(:alice))

    assert_response :unprocessable_entity
    assert_equal "validation_failed", response.parsed_body["error"]["code"]
  end

  def test_guest_success
    post_json "/api/v1/signals/preferences", {
      preferences: {
        sleep_together_importance: 4
      }
    }, auth_headers(users(:guest))

    assert_response :success
    assert_equal 4, response.parsed_body["preferences"]["sleep_together_importance"]
  end
end
