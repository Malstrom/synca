# frozen_string_literal: true

require 'test_helper'

class Api::V1::Signals::PreferencesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:alice)
    @headers = { 'Authorization' => "Bearer #{@user.jwt}" }
  end

  test 'should create preferences' do
    post api_v1_signals_preferences_path, params: {
      preferences: {
        sleep_together_importance: 4,
        temperature_preference: 'cool',
        movement_preference: 'moderate',
        rhythm_importance: 3,
        self_chronotype: 'night'
      }
    }, headers: @headers

    assert_response :success
    response_body = JSON.parse(@response.body)
    assert_equal 4, response_body['preferences']['sleep_together_importance']
    assert_equal 'cool', response_body['preferences']['temperature_preference']
    assert_equal 'moderate', response_body['preferences']['movement_preference']
    assert_equal 3, response_body['preferences']['rhythm_importance']
    assert_equal 'night', response_body['preferences']['self_chronotype']
  end

  test 'should return 401 without token' do
    post api_v1_signals_preferences_path, params: {
      preferences: {
        sleep_together_importance: 4
      }
    }

    assert_response :unauthorized
  end

  test 'should return 422 with invalid params' do
    post api_v1_signals_preferences_path, params: {
      preferences: {
        sleep_together_importance: 6
      }
    }, headers: @headers

    assert_response :unprocessable_entity
    response_body = JSON.parse(@response.body)
    assert_equal 'validation_failed', response_body['error']['code']
  end
end
