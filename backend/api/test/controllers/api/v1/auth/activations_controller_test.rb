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
          post api_v1_auth_activate_url,
               params: {
                 token: "valid_token",
                 profile: { display_name: "New Display Name" }
               },
               as: :json

          assert_response :success
          response_body = JSON.parse(response.body)
          assert_equal "active", response_body["account_type"]
          assert_not_nil response_body["access_token"]
          assert_not_nil response_body["refresh_token"]
        end

        test "activate with expired token" do
          @user.update!(magic_link_sent_at: 73.hours.ago)

          post api_v1_auth_activate_url,
               params: {
                 token: "valid_token",
                 profile: { display_name: "New Display Name" }
               },
               as: :json

          assert_response :unprocessable_entity
          assert_equal I18n.t("activations.token_expired"), JSON.parse(response.body)["error"]
        end

        test "activate with already used token" do
          @user.update!(magic_link_token: nil)

          post api_v1_auth_activate_url,
               params: {
                 token: "valid_token",
                 profile: { display_name: "New Display Name" }
               },
               as: :json

          assert_response :unprocessable_entity
          assert_equal I18n.t("activations.token_already_used"), JSON.parse(response.body)["error"]
        end

        test "activate with already active account" do
          @user.update!(account_type: :active)

          post api_v1_auth_activate_url,
               params: {
                 token: "valid_token",
                 profile: { display_name: "New Display Name" }
               },
               as: :json

          assert_response :unprocessable_entity
          assert_equal I18n.t("activations.account_already_active"), JSON.parse(response.body)["error"]
        end

        test "activate with invalid token" do
          post api_v1_auth_activate_url,
               params: {
                 token: "invalid_token",
                 profile: { display_name: "New Display Name" }
               },
               as: :json

          assert_response :not_found
          assert_equal I18n.t("activations.token_not_found"), JSON.parse(response.body)["error"]
        end
      end
    end
  end
end
