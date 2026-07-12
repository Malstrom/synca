# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    module Auth
      class ActivationsControllerTest < ActionDispatch::IntegrationTest
        setup do
          @user = users(:guest_user)
          @user.update!(
            magic_link_token: SecureRandom.urlsafe_base64(32),
            magic_link_sent_at: Time.current
          )
        end

        test "activate with valid token and display_name" do
          post api_v1_auth_activate_url,
               params: { token: @user.magic_link_token, profile: { display_name: "New Name" } },
               as: :json

          assert_response :success
          response_data = response.parsed_body
          assert_equal "Bearer", response_data["token_type"]
          assert_equal "active", response_data["account_type"]
          assert_not_nil response_data["access_token"]
          assert_not_nil response_data["refresh_token"]

          @user.reload
          assert_nil @user.magic_link_token
          assert_equal "New Name", @user.profile.display_name
        end

        test "activate with expired token" do
          @user.update!(magic_link_sent_at: MagicLinkService::TOKEN_TTL.ago - 1.hour)

          post api_v1_auth_activate_url,
               params: { token: @user.magic_link_token, profile: { display_name: "New Name" } },
               as: :json

          assert_response :unprocessable_entity
          assert_equal I18n.t("magic_link.token_expired"), response.parsed_body["error"]
        end

        test "activate with already used token" do
          @user.update!(magic_link_token: nil)

          post api_v1_auth_activate_url,
               params: { token: @user.magic_link_token, profile: { display_name: "New Name" } },
               as: :json

          assert_response :unprocessable_entity
          assert_equal I18n.t("magic_link.token_already_used"), response.parsed_body["error"]
        end

        test "activate with already active account" do
          @user.update!(account_type: :active)

          post api_v1_auth_activate_url,
               params: { token: @user.magic_link_token, profile: { display_name: "New Name" } },
               as: :json

          assert_response :unprocessable_entity
          assert_equal I18n.t("magic_link.account_already_active"), response.parsed_body["error"]
        end

        test "activate with invalid token" do
          post api_v1_auth_activate_url,
               params: { token: "invalid_token", profile: { display_name: "New Name" } },
               as: :json

          assert_response :not_found
          assert_equal I18n.t("magic_link.token_not_found"), response.parsed_body["error"]
        end
      end
    end
  end
end
