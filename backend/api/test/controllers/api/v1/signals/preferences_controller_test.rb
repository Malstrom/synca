# frozen_string_literal: true

require 'test_helper'

class Api::V1::Signals::PreferencesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:alice)
    @headers = auth_headers(@user)
  end

  test 'successful update' do
    params = {
      preferences: {
        sleep_together_importance: 4,
        temperature_preference: 'cool'
      }
    }
    post api_v1_signals_preferences_path, headers: @headers, params: params
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 4, json['data']['attributes']['sleep_together_importance']
    assert_equal 'cool', json['data']['attributes']['temperature_preference']
  end

  test 'unauthorized' do
    post api_v1_signals_preferences_path
    assert_response :unauthorized
  end

  test 'validation failure' do
    params = { preferences: { sleep_together_importance: 6 } }
    post api_v1_signals_preferences_path, headers: @headers, params: params
    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_equal 'validation_failed', json['error']['code']
  end

  test 'guest user' do
    guest = users(:guest)
    headers = auth_headers(guest)
    params = { preferences: { rhythm_importance: 3 } }
    post api_v1_signals_preferences_path, headers: headers, params: params
    assert_response :success
  end
end
