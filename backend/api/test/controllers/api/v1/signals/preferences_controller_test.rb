# frozen_string_literal: true

require 'test_helper'

class Api::V1::Signals::PreferencesControllerTest < ApiTestCase
  setup do
    @user = users(:alice)
    @headers = auth_headers(@user)
  end

  test 'successful update' do
    post api_v1_signals_preferences_path, params: {
      preferences: {
        sleep_together_importance: 3,
        temperature_preference: 'cool'
      }
    }, headers: @headers

    assert_response :success
    assert_equal 3, response.parsed_body['preferences']['sleep_together_importance']
    assert_equal 'cool', response.parsed_body['preferences']['temperature_preference']
  end

  test 'unauthorized' do
    post api_v1_signals_preferences_path, params: {
      preferences: {
        sleep_together_importance: 3
      }
    }

    assert_response :unauthorized
  end

  test 'validation failed' do
    post api_v1_signals_preferences_path, params: {
      preferences: {
        sleep_together_importance: 6
      }
    }, headers: @headers

    assert_response :unprocessable_entity
    assert_equal 'validation_failed', response.parsed_body['error']['code']
  end

  test 'partial update' do
    post api_v1_signals_preferences_path, params: {
      preferences: {
        temperature_preference: 'warm'
      }
    }, headers: @headers

    assert_response :success
    assert_equal 'warm', response.parsed_body['preferences']['temperature_preference']
    assert_nil response.parsed_body['preferences']['sleep_together_importance']
  end
end
