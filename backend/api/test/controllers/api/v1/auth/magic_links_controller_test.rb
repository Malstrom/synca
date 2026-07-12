# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    module Auth
      class MagicLinksControllerTest < ActionDispatch::IntegrationTest
        setup do
          @guest_user = users(:guest_user)
          @active_user = users(:active_user)
        end

        test "resend magic link to guest user" do
          assert_enqueued_emails 1 do
            post api_v1_auth_resend_magic_link_url,
                 params: { email: @guest_user.email },
                 as: :json
          end

          assert_response :success
          assert_equal I18n.t("magic_link.resend_success"), response.parsed_body["message"]
        end

        test "resend magic link to active user" do
          assert_no_enqueued_emails do
            post api_v1_auth_resend_magic_link_url,
                 params: { email: @active_user.email },
                 as: :json
          end

          assert_response :success
          assert_equal I18n.t("magic_link.resend_success"), response.parsed_body["message"]
        end

        test "resend magic link to non-existent email" do
          assert_no_enqueued_emails do
            post api_v1_auth_resend_magic_link_url,
                 params: { email: "nonexistent@example.com" },
                 as: :json
          end

          assert_response :success
          assert_equal I18n.t("magic_link.resend_success"), response.parsed_body["message"]
        end
      end
    end
  end
end