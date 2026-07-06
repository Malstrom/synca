# frozen_string_literal: true

require "test_helper"

class Api::V1::Signals::PreferencesControllerTest < ApiTestCase
  def setup
    @user = users(:alice)
    @headers = auth_headers(@user)
    @valid_params = {
      preferences: {
        sleep_together_importance: 3,
        temperature_preference: "cool",
        movement_preference: "moderate",
        rhythm_importance: 4,
        self_chronotype: "night"
      }
    }
  end

  def test_create_success
    post_json "/api/v1/signals/preferences", params: @valid_params, headers: @headers

    assert_response :success
    assert_equal "application/json", response.content_type
    assert_equal 3, json[:preferences][:sleep_together_importance]
    assert_equal "cool", json[:preferences][:temperature_preference]
    assert_equal "moderate", json[:preferences][:movement_preference]
    assert_equal 4, json[:preferences][:rhythm_importance]
    assert_equal "night", json[:preferences][:self_chronotype]
  end

  def test_create_guest_success
    guest_headers = auth_headers(users(:guest))
    post_json "/api/v1/signals/preferences", params: @valid_params, headers: guest_headers

    assert_response :success
  end

  def test_create_unauthorized
    post_json "/api/v1/signals/preferences", params: @valid_params

    assert_response :unauthorized
  end

  def test_create_contract_errors
    @valid_params[:preferences][:sleep_together_importance] = 6
    post_json "/api/v1/signals/preferences", params: @valid_params, headers: @headers

    assert_response :unprocessable_entity
    assert_equal "validation_failed", json[:error][:code]
  end

  def test_create_validation_failed
    @valid_params[:preferences][:sleep_together_importance] = 6
    post_json "/api/v1/signals/preferences", params: @valid_params, headers: @headers

    assert_response :unprocessable_entity
    assert_equal "validation_failed", json[:error][:code]
  end
end
