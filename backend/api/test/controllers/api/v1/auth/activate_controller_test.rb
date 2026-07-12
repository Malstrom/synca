# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    module Auth
      class ActivateControllerTest < ActionDispatch::IntegrationTest
        setup do
          @user = users(:guest_user)
          @user.update!(magic_link_token: "valid_token", magic_link_sent_at: Time.current)
          @profile = @user.profile
        end

        test "activate with valid token and display_name" do
          post api_v1_auth_activate_path, params: {
            token: "valid_token",
            profile: { display_name: "New Display Name" }
          }

          assert_response :success
          response_data = JSON.parse(response.body)
          assert_equal "active", @user.reload.account_type
          assert_nil @user.reload.magic_link_token
          assert_equal "New Display Name", @profile.reload.display_name
          assert response_data.key?("access_token")
          assert response_data.key?("refresh_token")
          assert_equal "Bearer", response_data["token_type"]
          assert_equal "active", response_data["account_type"]
        end

        test "activate with expired token" do
          @user.update!(magic_link_sent_at: 73.hours.ago)

          post api_v1_auth_activate_path, params: {
            token: "valid_token",
            profile: { display_name: "New Display Name" }
          }

          assert_response :unprocessable_entity
          assert_equal I18n.t("contracts.errors.token.invalid"), JSON.parse(response.body)["errors"].first
        end

        test "activate with already used token" do
          @user.update!(magic_link_token: nil)

          post api_v1_auth_activate_path, params: {
            token: "valid_token",
            profile: { display_name: "New Display Name" }
          }

          assert_response :unprocessable_entity
          assert_equal I18n.t("contracts.errors.token.invalid"), JSON.parse(response.body)["errors"].first
        end

        test "activate with already active account" do
          @user.update!(account_type: :active)

          post api_v1_auth_activate_path, params: {
            token: "valid_token",
            profile: { display_name: "New Display Name" }
          }

          assert_response :unprocessable_entity
          assert_equal I18n.t("contracts.errors.token.invalid"), JSON.parse(response.body)["errors"].first
        end
      end
    end
  end
end
