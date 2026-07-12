# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    module Auth
      class MagicLinksControllerTest < ActionDispatch::IntegrationTest
        setup do
          @user = users(:guest)
          @active_user = users(:active)
        end

        test "resend magic link for existing user" do
          post api_v1_auth_resend_magic_link_path, params: { email: @user.email }, as: :json

          assert_response :success
          assert_equal I18n.t("services.magic_link.resend_success"), response.parsed_body["message"]
        end

        test "resend magic link for non-existing user" do
          post api_v1_auth_resend_magic_link_path, params: { email: "nonexistent@example.com" }, as: :json

          assert_response :success
          assert_equal I18n.t("services.magic_link.resend_success"), response.parsed_body["message"]
        end

        test "resend magic link for active user" do
          post api_v1_auth_resend_magic_link_path, params: { email: @active_user.email }, as: :json

          assert_response :success
          assert_equal I18n.t("services.magic_link.resend_success"), response.parsed_body["message"]
        end

        test "resend magic link rate limited" do
          @user.update!(magic_link_sent_at: 4.minutes.ago)
          post api_v1_auth_resend_magic_link_path, params: { email: @user.email }, as: :json

          assert_response :too_many_requests
          assert_equal I18n.t("services.magic_link.rate_limited"), response.parsed_body["error"]
        end
      end
    end
  end
end