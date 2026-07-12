# frozen_string_literal: true

require "test_helper"

class Api::V1::Auth::MagicLinksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:guest_user)
  end

  test "resend magic link to existing guest user" do
    post api_v1_auth_resend_magic_link_path, params: { email: @user.email }

    assert_response :success
    assert_equal "If your email is registered, a new link has been sent.", response.parsed_body["message"]
  end

  test "resend magic link to non-existing user" do
    post api_v1_auth_resend_magic_link_path, params: { email: "nonexistent@example.com" }

    assert_response :success
    assert_equal "If your email is registered, a new link has been sent.", response.parsed_body["message"]
  end

  test "resend magic link too soon" do
    @user.update!(magic_link_sent_at: Time.current)

    post api_v1_auth_resend_magic_link_path, params: { email: @user.email }

    assert_response :too_many_requests
    assert_equal "Too many requests", response.parsed_body["error"]
  end
end
