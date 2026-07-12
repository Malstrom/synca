# frozen_string_literal: true

require "test_helper"

class Api::V1::Auth::ResendMagicLinkControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:guest)
  end

  test "resend magic link for existing user" do
    post api_v1_auth_resend_magic_link_url, params: { email: @user.email }

    assert_response :success
    assert_equal I18n.t("services.magic_link.resend_success"), response.parsed_body["message"]
  end

  test "resend magic link for non-existing user" do
    post api_v1_auth_resend_magic_link_url, params: { email: "nonexistent@example.com" }

    assert_response :success
    assert_equal I18n.t("services.magic_link.resend_success"), response.parsed_body["message"]
  end

  test "rate limited resend" do
    @user.update!(magic_link_sent_at: 1.minute.ago)

    post api_v1_auth_resend_magic_link_url, params: { email: @user.email }

    assert_response :too_many_requests
    assert_equal I18n.t("services.magic_link.rate_limited"), response.parsed_body["error"]
  end
end
