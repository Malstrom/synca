# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    module Auth
      class MagicLinksControllerTest < ActionDispatch::IntegrationTest
        setup do
          @user = users(:guest_user)
          @user.update!(account_type: :guest)
        end

        test "should send magic link for registered email" do
          assert_enqueued_emails 1 do
            post api_v1_auth_resend_magic_link_path, params: { email: @user.email }
          end

          assert_response :success
          assert_equal "If your email is registered, a new link has been sent.", JSON.parse(response.body)["message"]
        end

        test "should not send magic link for unregistered email" do
          assert_no_enqueued_emails do
            post api_v1_auth_resend_magic_link_path, params: { email: "nonexistent@example.com" }
          end

          assert_response :success
          assert_equal "If your email is registered, a new link has been sent.", JSON.parse(response.body)["message"]
        end

        test "should return 429 for too many requests" do
          @user.update!(magic_link_sent_at: Time.current)

          post api_v1_auth_resend_magic_link_path, params: { email: @user.email }

          assert_response :too_many_requests
          assert_equal "Too many requests", JSON.parse(response.body)["error"]
        end
      end
    end
  end
end
