# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    module Auth
      class ActivationsControllerTest < ActionDispatch::IntegrationTest
        setup do
          @user = users(:guest)
          @user.generate_magic_link_token!
          @active_user = users(:active)
        end

        test "activate with valid token" do
          post api_v1_auth_activate_path,
               params: { token: @user.magic_link_token, profile: { display_name: "New Name" } },
               as: :json

          assert_response :success
          response_data = response.parsed_body
          assert_equal "Bearer", response_data["token_type"]
          assert_equal "active", response_data["account_type"]
          assert_not_nil response_data["access_token"]
          assert_not_nil response_data["refresh_token"]
        end

        test "activate with invalid token" do
          post api_v1_auth_activate_path,
               params: { token: "invalid", profile: { display_name: "New Name" } },
               as: :json

          assert_response :not_found
          assert_equal I18n.t("services.magic_link.token_not_found"), response.parsed_body["error"]
        end

        test "activate with expired token" do
          @user.update!(magic_link_sent_at: MagicLinkService::TOKEN_TTL.ago - 1.hour)
          post api_v1_auth_activate_path,
               params: { token: @user.magic_link_token, profile: { display_name: "New Name" } },
               as: :json

          assert_response :unprocessable_entity
          assert_equal I18n.t("services.magic_link.token_expired"), response.parsed_body["error"]
        end

        test "activate with already active account" do
          post api_v1_auth_activate_path,
               params: { token: @active_user.magic_link_token, profile: { display_name: "New Name" } },
               as: :json

          assert_response :unprocessable_entity
          assert_equal I18n.t("services.magic_link.account_already_active"), response.parsed_body["error"]
        end
      end
    end
  end
end