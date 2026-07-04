# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    module Signals
      class PreferencesControllerTest < ActionDispatch::IntegrationTest
        setup do
          @user = users(:alice)
          @headers = { 'Authorization' => "Bearer #{JwtService.encode(user_id: @user.id)}" }
          @valid_params = {
            preferences: {
              sleep_together_importance: 4,
              temperature_preference: 'cool',
              movement_preference: 'moderate',
              rhythm_importance: 3,
              self_chronotype: 'night'
            }
          }
        end

        test '200 success' do
          post api_v1_signals_preferences_path, headers: @headers, params: @valid_params
          assert_response :success
          assert_equal @valid_params[:preferences][:sleep_together_importance],
                       response.parsed_body['preferences']['sleep_together_importance']
        end

        test '401 unauthorized' do
          post api_v1_signals_preferences_path, params: @valid_params
          assert_response :unauthorized
        end

        test '422 validation failed' do
          post api_v1_signals_preferences_path, headers: @headers,
                                                params: { preferences: { sleep_together_importance: 6 } }
          assert_response :unprocessable_entity
          assert_equal 'validation_failed', response.parsed_body['error']['code']
        end
      end
    end
  end
end
