# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    module Signals
      class PreferencesControllerTest < ApiTestCase
        setup do
          @user = users(:alice)
          @headers = auth_headers(@user)
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

        test 'success' do
          post_json '/api/v1/signals/preferences', @valid_params, @headers
          assert_response :success
          assert_equal @valid_params[:preferences], json_response[:preferences]
        end

        test 'unauthorized' do
          post_json '/api/v1/signals/preferences', @valid_params
          assert_response :unauthorized
        end

        test 'validation failed' do
          post_json '/api/v1/signals/preferences', { preferences: { sleep_together_importance: 6 } }, @headers
          assert_response :unprocessable_entity
          assert_equal 'validation_failed', json_response[:error][:code]
        end

        test 'partial update' do
          post_json '/api/v1/signals/preferences', { preferences: { rhythm_importance: 2 } }, @headers
          assert_response :success
          assert_equal 2, json_response[:preferences][:rhythm_importance]
        end
      end
    end
  end
end
