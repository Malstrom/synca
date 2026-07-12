# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    module Auth
      class ResendMagicLinkControllerTest < ActionDispatch::IntegrationTest
        setup do
          @user = users(:guest_user)
        end

        test "resend magic link with valid email" do
          post api_v1_auth_resend_magic_link_path, params: { email: @user.email }

          assert_response :success
          assert_equal I18n.t("resend_magic_link.success"), JSON.parse(response.body)["message"]
        end

        test "resend magic link with non-existent email" do
          post api_v1_auth_resend_magic_link_path, params: { email: "nonexistent@example.com" }

          assert_response :success
          assert_equal I18n.t("resend_magic_link.success"), JSON.parse(response.body)["message"]
        end

        test "resend magic link with rate limited" do
          @user.update!(magic_link_sent_at: Time.current)

          post api_v1_auth_resend_magic_link_path, params: { email: @user.email }

          assert_response :too_many_requests
        end
      end
    end
  end
end
