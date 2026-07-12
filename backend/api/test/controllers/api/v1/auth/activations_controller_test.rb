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
            magic_link_sent_at: Time.current,
            account_type: :guest
          )
          @profile_attrs = { display_name: "New Display Name" }
        end

        test "should activate account with valid token" do
          post api_v1_auth_activate_path, params: {
            token: "valid_token",
            profile: @profile_attrs
          }

          assert_response :success
          response_data = JSON.parse(response.body)
          assert_not_nil response_data["access_token"]
          assert_not_nil response_data["refresh_token"]
          assert_equal "Bearer", response_data["token_type"]
          assert_equal "active", response_data["account_type"]

          @user.reload
          assert_equal "active", @user.account_type
          assert_nil @user.magic_link_token
          assert_nil @user.magic_link_sent_at
          assert_equal @profile_attrs[:display_name], @user.profile.display_name
        end

        test "should return 404 for invalid token" do
          post api_v1_auth_activate_path, params: {
            token: "invalid_token",
            profile: @profile_attrs
          }

          assert_response :not_found
          assert_equal "Token not found", JSON.parse(response.body)["error"]
        end

        test "should return 422 for already active account" do
          @user.update!(account_type: :active)

          post api_v1_auth_activate_path, params: {
            token: "valid_token",
            profile: @profile_attrs
          }

          assert_response :unprocessable_entity
          assert_equal "Account already active", JSON.parse(response.body)["error"]
        end

        test "should return 422 for expired token" do
          @user.update!(magic_link_sent_at: 73.hours.ago)

          post api_v1_auth_activate_path, params: {
            token: "valid_token",
            profile: @profile_attrs
          }

          assert_response :unprocessable_entity
          assert_equal "Token expired", JSON.parse(response.body)["error"]
        end

        test "should return 422 for already used token" do
          @user.update!(magic_link_token: nil)

          post api_v1_auth_activate_path, params: {
            token: "valid_token",
            profile: @profile_attrs
          }

          assert_response :unprocessable_entity
          assert_equal "Token already used", JSON.parse(response.body)["error"]
        end
      end
    end
  end
end