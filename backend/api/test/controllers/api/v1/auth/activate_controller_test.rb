# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    module Auth
      class ActivateControllerTest < ActionDispatch::IntegrationTest
        setup do
          @user = users(:guest_user)
          @user.update!(
            magic_link_token: "valid_token",
            magic_link_sent_at: Time.current
          )
        end

        test "activate with valid token and display_name" do
          post api_v1_auth_activate_path, params: {
            token: "valid_token",
            profile: { display_name: "New Display Name" }
          }

          assert_response :success
          assert_equal "active", @user.reload.account_type
          assert_nil @user.magic_link_token
          assert_nil @user.magic_link_sent_at
          assert_equal "New Display Name", @user.profile.display_name
        end

        test "activate with expired token" do
          @user.update!(magic_link_sent_at: 73.hours.ago)

          post api_v1_auth_activate_path, params: {
            token: "valid_token",
            profile: { display_name: "New Display Name" }
          }

          assert_response :unprocessable_entity
          assert_equal "guest", @user.reload.account_type
        end

        test "activate with already used token" do
          @user.update!(magic_link_token: nil, magic_link_sent_at: nil)

          post api_v1_auth_activate_path, params: {
            token: "valid_token",
            profile: { display_name: "New Display Name" }
          }

          assert_response :unprocessable_entity
        end

        test "activate with already active account" do
          @user.update!(account_type: :active)

          post api_v1_auth_activate_path, params: {
            token: "valid_token",
            profile: { display_name: "New Display Name" }
          }

          assert_response :unprocessable_entity
        end

        test "activate with invalid token" do
          post api_v1_auth_activate_path, params: {
            token: "invalid_token",
            profile: { display_name: "New Display Name" }
          }

          assert_response :not_found
        end
      end
    end
  end
end