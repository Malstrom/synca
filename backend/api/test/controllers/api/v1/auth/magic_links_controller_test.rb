# frozen_string_literal: true

require "test_helper"

class Api::V1::Auth::MagicLinksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:guest_user)
  end

  test "should resend magic link for guest user" do
    post api_v1_auth_resend_magic_link_url,
         params: { email: @user.email },
         as: :json

    assert_response :success
    assert_equal I18n.t("magic_link.resent"), json_response["message"]
    assert_not_nil @user.reload.magic_link_token
    assert_not_nil @user.magic_link_sent_at
  end

  test "should return 429 for rate limited resend" do
    @user.update!(magic_link_sent_at: Time.current)

    post api_v1_auth_resend_magic_link_url,
         params: { email: @user.email },
         as: :json

    assert_response :too_many_requests
    assert_equal I18n.t("errors.rate_limited"), json_response["error"]
  end

  test "should not reveal if email exists" do
    post api_v1_auth_resend_magic_link_url,
         params: { email: "nonexistent@example.com" },
         as: :json

    assert_response :success
    assert_equal I18n.t("magic_link.resent"), json_response["message"]
  end

  test "should not send magic link for active user" do
    @user.update!(account_type: :active)

    post api_v1_auth_resend_magic_link_url,
         params: { email: @user.email },
         as: :json

    assert_response :success
    assert_equal I18n.t("magic_link.resent"), json_response["message"]
    assert_nil @user.reload.magic_link_token
    assert_nil @user.magic_link_sent_at
  end
end
