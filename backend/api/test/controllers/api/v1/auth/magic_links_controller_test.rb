# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    module Auth
      class MagicLinksControllerTest < ActionDispatch::IntegrationTest
        setup do
          @user = users(:guest_user)
        end

        test "should send magic link for registered email" do
          post api_v1_auth_resend_magic_link_url,
               params: { email: @user.email },
               as: :json

          assert_response :success
          assert_equal "If your email is registered, a new link has been sent.", json_response["message"]
          assert_not_nil @user.reload.magic_link_token
          assert_not_nil @user.magic_link_sent_at
        end

        test "should not reveal if email is registered" do
          post api_v1_auth_resend_magic_link_url,
               params: { email: "nonexistent@example.com" },
               as: :json

          assert_response :success
          assert_equal "If your email is registered, a new link has been sent.", json_response["message"]
        end

        test "should return 429 for too many requests" do
          @user.update!(magic_link_sent_at: Time.current)

          post api_v1_auth_resend_magic_link_url,
               params: { email: @user.email },
               as: :json

          assert_response :too_many_requests
          assert_equal "Too many requests", json_response["error"]
        end
      end
    end
  end
end
