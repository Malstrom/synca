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

  def parsed_preferences
    json[:preferences]
  end

  # --- happy path ---

  test "POST /api/v1/signals/preferences returns 200 with preferences payload" do
    post_json "/api/v1/signals/preferences",
      params: @valid_params,
      headers: @headers

    assert_response :ok
    payload = parsed_preferences
    assert_equal 3, payload[:sleep_together_importance]
    assert_equal "cool", payload[:temperature_preference]
    assert_equal "moderate", payload[:movement_preference]
    assert_equal 4, payload[:rhythm_importance]
    assert_equal "night", payload[:self_chronotype]
  end

  test "POST /api/v1/signals/preferences creates record when user has none" do
    @user.preference_profile.destroy

    post_json "/api/v1/signals/preferences",
      params: @valid_params,
      headers: @headers

    assert_response :ok
    payload = parsed_preferences
    assert_equal 3, payload[:sleep_together_importance]
    assert_equal "cool", payload[:temperature_preference]
  end

  test "POST /api/v1/signals/preferences persists updated values in db" do
    post_json "/api/v1/signals/preferences",
      params: { preferences: @valid_params[:preferences].merge(sleep_together_importance: 2) },
      headers: @headers

    assert_response :ok
    assert_equal 2, @user.preference_profile.reload.sleep_together_importance
  end

  test "POST /api/v1/signals/preferences with partial attributes returns 200" do
    partial_params = { preferences: { sleep_together_importance: 2, rhythm_importance: 5 } }

    post_json "/api/v1/signals/preferences",
      params: partial_params,
      headers: @headers

    assert_response :ok
    payload = parsed_preferences
    assert_equal 2, payload[:sleep_together_importance]
    assert_equal 5, payload[:rhythm_importance]
    assert_nil payload[:temperature_preference]
  end

  # --- contract validation errors (caught before service) ---

  test "POST /api/v1/signals/preferences with invalid sleep_together_importance returns 422" do
    post_json "/api/v1/signals/preferences",
      params: { preferences: @valid_params[:preferences].merge(sleep_together_importance: 6) },
      headers: @headers

    assert_response :unprocessable_entity
    assert_equal "validation_failed", json.dig(:error, :code)
  end

  test "POST /api/v1/signals/preferences with invalid temperature_preference returns 422" do
    post_json "/api/v1/signals/preferences",
      params: { preferences: @valid_params[:preferences].merge(temperature_preference: "invalid") },
      headers: @headers

    assert_response :unprocessable_entity
    assert_equal "validation_failed", json.dig(:error, :code)
  end

  # --- service validation errors (model-level, caught after contract) ---

  test "POST /api/v1/signals/preferences with invalid rhythm_importance returns 422" do
    post_json "/api/v1/signals/preferences",
      params: { preferences: @valid_params[:preferences].merge(rhythm_importance: 6) },
      headers: @headers

    assert_response :unprocessable_entity
    assert_equal "validation_failed", json.dig(:error, :code)
  end

  # --- auth ---

  test "POST /api/v1/signals/preferences without token returns 401" do
    post_json "/api/v1/signals/preferences", params: @valid_params
    assert_response :unauthorized
  end

  # --- guest auth ---

  test "POST /api/v1/signals/preferences with guest token returns 200" do
    guest_user = users(:guest)
    guest_headers = auth_headers(guest_user)

    post_json "/api/v1/signals/preferences",
      params: @valid_params,
      headers: guest_headers

    assert_response :ok
  end
end
