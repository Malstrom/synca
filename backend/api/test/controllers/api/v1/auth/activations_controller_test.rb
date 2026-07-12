# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    module Auth
      class ActivationsControllerTest < ActionDispatch::IntegrationTest
        setup do
          @user = users(:guest_user)
          @user.update!(
            magic_link_token: "valid_token",
            magic_link_sent_at: Time.current
          )
        end

        test "should activate guest account with valid token" do
          post api_v1_auth_activate_url,
               params: {
                 token: "valid_token",
                 profile: { display_name: "New Display Name" }
               },
               as: :json

          assert_response :success
          assert_equal "active", @user.reload.account_type
          assert_nil @user.magic_link_token
          assert_nil @user.magic_link_sent_at
          assert_equal "New Display Name", @user.profile.display_name
          assert_not_nil json_response["access_token"]
          assert_not_nil json_response["refresh_token"]
          assert_equal "Bearer", json_response["token_type"]
          assert_equal "active", json_response["account_type"]
        end

        test "should return 404 for invalid token" do
          post api_v1_auth_activate_url,
               params: {
                 token: "invalid_token",
                 profile: { display_name: "New Display Name" }
               },
               as: :json

          assert_response :not_found
          assert_equal "Token not found", json_response["error"]
        end

        test "should return 422 for already active account" do
          @user.update!(account_type: :active)

          post api_v1_auth_activate_url,
               params: {
                 token: "valid_token",
                 profile: { display_name: "New Display Name" }
               },
               as: :json

          assert_response :unprocessable_entity
          assert_equal "Account already active", json_response["error"]
        end

        test "should return 422 for expired token" do
          @user.update!(magic_link_sent_at: 73.hours.ago)

          post api_v1_auth_activate_url,
               params: {
                 token: "valid_token",
                 profile: { display_name: "New Display Name" }
               },
               as: :json

          assert_response :unprocessable_entity
          assert_equal "Token expired", json_response["error"]
        end

        test "should return 422 for already used token" do
          @user.update!(magic_link_token: nil)

          post api_v1_auth_activate_url,
               params: {
                 token: "valid_token",
                 profile: { display_name: "New Display Name" }
               },
               as: :json

          assert_response :unprocessable_entity
          assert_equal "Token already used", json_response["error"]
        end
      end
    end
  end
end