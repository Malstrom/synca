# frozen_string_literal: true

require 'test_helper'

class Api::V1::Signals::PreferencesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:alice)
    @headers = { 'Authorization' => "Bearer #{@user.token}" }
    @valid_params = {
      preferences: {
        sleep_together_importance: 3,
        temperature_preference: 'cool',
        movement_preference: 'moderate',
        rhythm_importance: 4,
        self_chronotype: 'night'
      }
    }
  end

  test 'should create preferences' do
    post api_v1_signals_preferences_path, headers: @headers, params: @valid_params

    assert_response :success
    response_body = JSON.parse(response.body)
    assert_equal 3, response_body['preferences']['sleep_together_importance']
    assert_equal 'cool', response_body['preferences']['temperature_preference']
  end

  test 'should return 401 without token' do
    post api_v1_signals_preferences_path, params: @valid_params

    assert_response :unauthorized
  end

  test 'should return 422 with invalid params' do
    post api_v1_signals_preferences_path, headers: @headers, params: {
      preferences: { sleep_together_importance: 6 }
    }

    assert_response :unprocessable_entity
    response_body = JSON.parse(response.body)
    assert_equal 'validation_failed', response_body['error']['code']
  end

  test 'should allow partial updates' do
    post api_v1_signals_preferences_path, headers: @headers, params: {
      preferences: { temperature_preference: 'warm' }
    }

    assert_response :success
    response_body = JSON.parse(response.body)
    assert_equal 'warm', response_body['preferences']['temperature_preference']
    assert_nil response_body['preferences']['sleep_together_importance']
  end

  test 'should work with guest user' do
    guest = users(:guest_user)
    guest_headers = { 'Authorization' => "Bearer #{guest.token}" }

    post api_v1_signals_preferences_path, headers: guest_headers, params: @valid_params

    assert_response :success
  end
end
