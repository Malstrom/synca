# frozen_string_literal: true

require "test_helper"

class Api::V1::Signals::PreferencesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:alice)
    @token = generate_jwt_token(@user)
  end

  def test_create_with_all_fields
    post "/api/v1/signals/preferences",
         params: {
           preferences: {
             sleep_together_importance: 4,
             temperature_preference: "cool",
             movement_preference: "moderate",
             rhythm_importance: 3,
             self_chronotype: "night"
           }
         },
         headers: { "Authorization" => "Bearer #{@token}" }

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 4, json["preferences"]["sleep_together_importance"]
    assert_equal "cool", json["preferences"]["temperature_preference"]
    assert_equal "moderate", json["preferences"]["movement_preference"]
  end

  def test_create_with_partial_fields
    post "/api/v1/signals/preferences",
         params: {
           preferences: {
             sleep_together_importance: 2,
             temperature_preference: "warm"
           }
         },
         headers: { "Authorization" => "Bearer #{@token}" }

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 2, json["preferences"]["sleep_together_importance"]
    assert_equal "warm", json["preferences"]["temperature_preference"]
  end

  def test_upsert_no_duplicate_records
    initial_count = @user.preference_profile.nil? ? 0 : 1

    post "/api/v1/signals/preferences",
         params: {
           preferences: { sleep_together_importance: 5 }
         },
         headers: { "Authorization" => "Bearer #{@token}" }

    assert_response :ok

    post "/api/v1/signals/preferences",
         params: {
           preferences: { temperature_preference: "cool" }
         },
         headers: { "Authorization" => "Bearer #{@token}" }

    assert_response :ok
    final_count = @user.preference_profiles.count
    assert_equal initial_count, final_count
  end

  def test_create_without_authorization
    post "/api/v1/signals/preferences",
         params: {
           preferences: { sleep_together_importance: 4 }
         }

    assert_response :unauthorized
  end

  def test_invalid_sleep_together_importance
    post "/api/v1/signals/preferences",
         params: {
           preferences: { sleep_together_importance: 6 }
         },
         headers: { "Authorization" => "Bearer #{@token}" }

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_equal "validation_failed", json["error"]["code"]
  end

  def test_invalid_temperature_preference
    post "/api/v1/signals/preferences",
         params: {
           preferences: { temperature_preference: "invalid" }
         },
         headers: { "Authorization" => "Bearer #{@token}" }

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_equal "validation_failed", json["error"]["code"]
  end

  def test_guest_user_can_create_preferences
    guest_user = users(:guest_user)
    guest_token = generate_jwt_token(guest_user)

    post "/api/v1/signals/preferences",
         params: {
           preferences: {
             sleep_together_importance: 3,
             temperature_preference: "warm"
           }
         },
         headers: { "Authorization" => "Bearer #{guest_token}" }

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 3, json["preferences"]["sleep_together_importance"]
  end
end
