# frozen_string_literal: true

require "test_helper"

class Api::V1::Signals::PreferencesControllerTest < ApiTestCase
  setup do
    @user = users(:alice)
    @headers = auth_headers(@user)
    @valid_params = {
      preferences: {
        sleep_together_importance: 4,
        temperature_preference: "cool",
        movement_preference: "moderate",
        rhythm_importance: 3,
        self_chronotype: "night"
      }
    }
  end

  test "successful update" do
    post_json "/api/v1/signals/preferences", @valid_params, @headers
    assert_response :success
    assert_equal @valid_params[:preferences][:sleep_together_importance], response.parsed_body.dig("preferences", "sleep_together_importance")
  end

  test "unauthorized" do
    post_json "/api/v1/signals/preferences", @valid_params
    assert_response :unauthorized
  end

  test "invalid params" do
    post_json "/api/v1/signals/preferences", { preferences: { sleep_together_importance: 6 } }, @headers
    assert_response :unprocessable_entity
    assert_equal "validation_failed", response.parsed_body.dig("error", "code")
  end

  test "partial update" do
    partial_params = { preferences: { sleep_together_importance: 5 } }
    post_json "/api/v1/signals/preferences", partial_params, @headers
    assert_response :success
    assert_equal 5, response.parsed_body.dig("preferences", "sleep_together_importance")
  end

  test "guest user" do
    guest = users(:guest_user)
    post_json "/api/v1/signals/preferences", @valid_params, auth_headers(guest)
    assert_response :success
  end
end
