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
          assert_not_nil response.parsed_body["access_token"]
          assert_not_nil response.parsed_body["refresh_token"]
          assert_equal "Bearer", response.parsed_body["token_type"]
          assert_equal "active", response.parsed_body["account_type"]
        end

        test "activate with expired token" do
          @user.update!(magic_link_sent_at: 73.hours.ago)

          post api_v1_auth_activate_path, params: {
            token: "valid_token",
            profile: { display_name: "New Display Name" }
          }

          assert_response :unprocessable_entity
          assert_equal I18n.t("activations.token_expired"), response.parsed_body.dig("error", "message")
        end

        test "activate with already used token" do
          @user.update!(magic_link_token: nil, account_type: :active)

          post api_v1_auth_activate_path, params: {
            token: "valid_token",
            profile: { display_name: "New Display Name" }
          }

          assert_response :unprocessable_entity
          assert_equal I18n.t("activations.token_already_used"), response.parsed_body.dig("error", "message")
        end

        test "activate with already active account" do
          @user.update!(account_type: :active)

          post api_v1_auth_activate_path, params: {
            token: "valid_token",
            profile: { display_name: "New Display Name" }
          }

          assert_response :unprocessable_entity
          assert_equal I18n.t("activations.account_already_active"), response.parsed_body.dig("error", "message")
        end

        test "activate with invalid token" do
          post api_v1_auth_activate_path, params: {
            token: "invalid_token",
            profile: { display_name: "New Display Name" }
          }

          assert_response :not_found
          assert_equal I18n.t("activations.token_not_found"), response.parsed_body.dig("error", "message")
        end
      end
    end
  end
end
