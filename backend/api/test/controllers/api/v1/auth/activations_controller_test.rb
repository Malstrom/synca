# frozen_string_literal: true

require "test_helper"

class Api::V1::Auth::ActivationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:guest_user)
    @token = JwtService.encode_magic_link(@user)
    @user.update!(magic_link_token: @token)
  end

  test "POST /api/v1/auth/activate with valid token and display_name" do
    post api_v1_auth_activate_path, params: {
      token: @token,
      profile: { display_name: "Luca" }
    }

    assert_response :success
    assert_equal "active", @user.reload.account_type
    assert_equal "Luca", @user.profile.display_name
    assert_not_nil response.parsed_body["access_token"]
    assert_not_nil response.parsed_body["refresh_token"]
  end

  test "POST /api/v1/auth/activate with already used token" do
    @user.update!(magic_link_token: nil)

    post api_v1_auth_activate_path, params: {
      token: @token,
      profile: { display_name: "Luca" }
    }

    assert_response :unprocessable_entity
    assert_equal "token_already_used", response.parsed_body.dig("error", "code")
  end

  test "POST /api/v1/auth/activate with expired token" do
    expired_token = JwtService.encode_magic_link(@user, exp: 1.hour.ago)

    post api_v1_auth_activate_path, params: {
      token: expired_token,
      profile: { display_name: "Luca" }
    }

    assert_response :unprocessable_entity
    assert_equal "invalid_token", response.parsed_body.dig("error", "code")
  end

  test "POST /api/v1/auth/resend_magic_link" do
    post api_v1_auth_resend_magic_link_path, params: { email: @user.email }

    assert_response :success
    assert_equal I18n.t("auth.magic_link.resent"), response.parsed_body["message"]
  end

  test "POST /api/v1/auth/resend_magic_link with rate limit" do
    @user.update!(magic_link_sent_at: 1.minute.ago)

    post api_v1_auth_resend_magic_link_path, params: { email: @user.email }

    assert_response :too_many_requests
    assert_equal "rate_limit_exceeded", response.parsed_body.dig("error", "code")
  end
end

---