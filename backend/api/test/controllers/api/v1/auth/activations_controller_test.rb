# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    module Auth
      class ActivationsControllerTest < ActionDispatch::IntegrationTest
        setup do
          @user = users(:guest_user)
          @token = SecureRandom.urlsafe_base64(32)
          @user.update!(magic_link_token: @token, magic_link_sent_at: Time.current)
        end

        test "POST /api/v1/auth/activate with valid token and display_name" do
          post api_v1_auth_activate_path, params: {
            token: @token,
            profile: { display_name: "Luca" }
          }

          assert_response :success
          response_data = JSON.parse(response.body)
          assert_equal "active", @user.reload.account_type
          assert_nil @user.reload.magic_link_token
          assert_equal "Luca", @user.profile.display_name
          assert_not_nil response_data["access_token"]
          assert_not_nil response_data["refresh_token"]
          assert_equal "Bearer", response_data["token_type"]
          assert_equal "active", response_data["account_type"]
        end

        test "POST /api/v1/auth/activate with expired token" do
          @user.update!(magic_link_sent_at: 73.hours.ago)

          post api_v1_auth_activate_path, params: {
            token: @token,
            profile: { display_name: "Luca" }
          }

          assert_response :unprocessable_entity
          response_data = JSON.parse(response.body)
          assert_equal "token_expired", response_data["errors"].first["code"]
          assert_equal I18n.t("controllers.activations.token_expired"), response_data["errors"].first["message"]
        end

        test "POST /api/v1/auth/activate with already used token" do
          @user.update!(magic_link_token: nil)

          post api_v1_auth_activate_path, params: {
            token: @token,
            profile: { display_name: "Luca" }
          }

          assert_response :unprocessable_entity
          response_data = JSON.parse(response.body)
          assert_equal "token_already_used", response_data["errors"].first["code"]
          assert_equal I18n.t("controllers.activations.token_already_used"), response_data["errors"].first["message"]
        end

        test "POST /api/v1/auth/activate with already active account" do
          @user.update!(account_type: "active")

          post api_v1_auth_activate_path, params: {
            token: @token,
            profile: { display_name: "Luca" }
          }

          assert_response :unprocessable_entity
          response_data = JSON.parse(response.body)
          assert_equal "account_already_active", response_data["errors"].first["code"]
          assert_equal I18n.t("controllers.activations.account_already_active"), response_data["errors"].first["message"]
        end

        test "POST /api/v1/auth/activate with invalid token" do
          post api_v1_auth_activate_path, params: {
            token: "invalid_token",
            profile: { display_name: "Luca" }
          }

          assert_response :not_found
          response_data = JSON.parse(response.body)
          assert_equal "token_not_found", response_data["errors"].first["code"]
          assert_equal I18n.t("controllers.activations.token_not_found"), response_data["errors"].first["message"]
        end
      end
    end
  end
end