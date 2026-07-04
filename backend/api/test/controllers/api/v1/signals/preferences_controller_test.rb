# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    module Signals
      class PreferencesControllerTest < ActionDispatch::IntegrationTest
        setup do
          @user = users(:alice)
          @headers = { 'Authorization' => "Bearer #{@user.jwt_token}" }
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

        test 'successful update' do
          post api_v1_signals_preferences_path, params: @valid_params, headers: @headers
          assert_response :success
          assert_equal @valid_params[:preferences], JSON.parse(response.body)['preferences']
        end

        test 'unauthorized' do
          post api_v1_signals_preferences_path, params: @valid_params
          assert_response :unauthorized
        end

        test 'invalid params' do
          post api_v1_signals_preferences_path,
               params: { preferences: { sleep_together_importance: 6 } },
               headers: @headers
          assert_response :unprocessable_entity
          assert_equal 'validation_failed', JSON.parse(response.body)['error']['code']
        end
      end
    end
  end
end
