# frozen_string_literal: true

require "test_helper"

class Api::V1::Signals::PreferencesControllerTest < ApiTestCase
  setup do
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

  test "successful update" do
    post_json "/api/v1/signals/preferences", @valid_params, @headers
    assert_response :success
    assert_equal @valid_params[:preferences][:sleep_together_importance], response.parsed_body["preferences"]["sleep_together_importance"]
    assert_equal @valid_params[:preferences][:temperature_preference], response.parsed_body["preferences"]["temperature_preference"]
    assert_equal @valid_params[:preferences][:movement_preference], response.parsed_body["preferences"]["movement_preference"]
    assert_equal @valid_params[:preferences][:rhythm_importance], response.parsed_body["preferences"]["rhythm_importance"]
    assert_equal @valid_params[:preferences][:self_chronotype], response.parsed_body["preferences"]["self_chronotype"]
  end

  test "unauthorized" do
    post_json "/api/v1/signals/preferences", @valid_params
    assert_response :unauthorized
  end

  test "invalid params" do
    invalid_params = { preferences: { sleep_together_importance: 6 } }
    post_json "/api/v1/signals/preferences", invalid_params, @headers
    assert_response :unprocessable_entity
    assert_equal "validation_failed", response.parsed_body["error"]["code"]
  end

  test "guest user can update preferences" do
    guest = users(:guest)
    guest_headers = auth_headers(guest)
    post_json "/api/v1/signals/preferences", @valid_params, guest_headers
    assert_response :success
  end
end
