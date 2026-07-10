# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    module Auth
      class ActivationsControllerTest < ActionDispatch::IntegrationTest
        setup do
          @user = users(:guest_user)
          @token = "valid_token"
          @user.update!(magic_link_token: @token, magic_link_sent_at: Time.current)
        end

        test "activate account with valid token" do
          post api_v1_auth_activate_path, params: {
            token: @token,
            profile: { display_name: "Luca" }
          }, headers: { "Authorization" => "Bearer #{JwtService.access_token(@user)}" }

          assert_response :success
          response_data = JSON.parse(response.body)
          assert_equal "active", @user.reload.account_type
          assert_equal "Luca", @user.profile.display_name
          assert_not_nil response_data["access_token"]
          assert_not_nil response_data["refresh_token"]
        end

        test "activate with expired token" do
          @user.update!(magic_link_sent_at: 73.hours.ago)

          post api_v1_auth_activate_path, params: {
            token: @token,
            profile: { display_name: "Luca" }
          }, headers: { "Authorization" => "Bearer #{JwtService.access_token(@user)}" }

          assert_response :unprocessable_entity
          assert_equal I18n.t("errors.token_expired"), JSON.parse(response.body)["error"]
        end

        test "activate with already used token" do
          @user.update!(magic_link_token: nil)

          post api_v1_auth_activate_path, params: {
            token: @token,
            profile: { display_name: "Luca" }
          }, headers: { "Authorization" => "Bearer #{JwtService.access_token(@user)}" }

          assert_response :unprocessable_entity
          assert_equal I18n.t("errors.token_already_used"), JSON.parse(response.body)["error"]
        end

        test "activate already active account" do
          @user.update!(account_type: "active")

          post api_v1_auth_activate_path, params: {
            token: @token,
            profile: { display_name: "Luca" }
          }, headers: { "Authorization" => "Bearer #{JwtService.access_token(@user)}" }

          assert_response :unprocessable_entity
          assert_equal I18n.t("errors.account_already_active"), JSON.parse(response.body)["error"]
        end
      end
    end
  end
end