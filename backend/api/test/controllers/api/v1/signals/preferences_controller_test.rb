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

  test "should create preferences" do
    post_json "/api/v1/signals/preferences", @valid_params, @headers
    assert_response :success
    assert_equal @valid_params[:preferences][:sleep_together_importance], response.parsed_body["preferences"]["sleep_together_importance"]
    assert_equal @valid_params[:preferences][:temperature_preference], response.parsed_body["preferences"]["temperature_preference"]
    assert_equal @valid_params[:preferences][:movement_preference], response.parsed_body["preferences"]["movement_preference"]
    assert_equal @valid_params[:preferences][:rhythm_importance], response.parsed_body["preferences"]["rhythm_importance"]
    assert_equal @valid_params[:preferences][:self_chronotype], response.parsed_body["preferences"]["self_chronotype"]
  end

  test "should return 401 without token" do
    post_json "/api/v1/signals/preferences", @valid_params
    assert_response :unauthorized
  end

  test "should return 422 with invalid params" do
    post_json "/api/v1/signals/preferences", { preferences: { sleep_together_importance: 6 } }, @headers
    assert_response :unprocessable_entity
    assert_equal "validation_failed", response.parsed_body["error"]["code"]
  end

  test "should allow guest users" do
    guest = users(:guest_user)
    headers = auth_headers(guest)
    post_json "/api/v1/signals/preferences", @valid_params, headers
    assert_response :success
  end

  test "should allow partial updates" do
    @user.create_preference_profile(sleep_together_importance: 1, rhythm_importance: 2)
    post_json "/api/v1/signals/preferences", { preferences: { sleep_together_importance: 3 } }, @headers
    assert_response :success
    assert_equal 3, response.parsed_body["preferences"]["sleep_together_importance"]
    assert_equal 2, response.parsed_body["preferences"]["rhythm_importance"]
  end
end
