# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    module Auth
      class MagicLinksControllerTest < ActionDispatch::IntegrationTest
        setup do
          @user = users(:guest_user)
        end

        test "POST /api/v1/auth/resend_magic_link with valid email" do
          post api_v1_auth_resend_magic_link_path, params: { email: @user.email }

          assert_response :success
          response_data = JSON.parse(response.body)
          assert_equal I18n.t("controllers.magic_links.resent"), response_data["message"]
        end

        test "POST /api/v1/auth/resend_magic_link with rate limited email" do
          @user.update!(magic_link_sent_at: Time.current)

          post api_v1_auth_resend_magic_link_path, params: { email: @user.email }

          assert_response :too_many_requests
          response_data = JSON.parse(response.body)
          assert_equal "rate_limited", response_data["errors"].first["code"]
          assert_equal I18n.t("services.resend_magic_link.rate_limited"), response_data["errors"].first["message"]
        end

        test "POST /api/v1/auth/resend_magic_link with non-existent email" do
          post api_v1_auth_resend_magic_link_path, params: { email: "nonexistent@example.com" }

          assert_response :success
          response_data = JSON.parse(response.body)
          assert_equal I18n.t("controllers.magic_links.resent"), response_data["message"]
        end
      end
    end
  end
end
