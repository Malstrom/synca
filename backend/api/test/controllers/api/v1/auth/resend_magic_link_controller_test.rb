# frozen_string_literal: true

require "test_helper"

class Api::V1::Auth::ResendMagicLinkControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:guest_user)
  end

  test "resend magic link to existing user" do
    post api_v1_auth_resend_magic_link_path, params: { email: @user.email }

    assert_response :success
    assert_equal I18n.t("resend_magic_link.success"), response.parsed_body["data"]["message"]
  end

  test "resend magic link to non-existing user" do
    post api_v1_auth_resend_magic_link_path, params: { email: "nonexistent@example.com" }

    assert_response :success
    assert_equal I18n.t("resend_magic_link.success"), response.parsed_body["data"]["message"]
  end

  test "resend magic link too soon" do
    @user.update!(magic_link_sent_at: 4.minutes.ago)

    post api_v1_auth_resend_magic_link_path, params: { email: @user.email }

    assert_response :too_many_requests
    assert_equal I18n.t("errors.rate_limited"), response.parsed_body["error"]
  end

  test "resend magic link with invalid email" do
    post api_v1_auth_resend_magic_link_path, params: { email: "invalid_email" }

    assert_response :unprocessable_entity
    assert_equal I18n.t("contracts.errors.email.invalid"), response.parsed_body["errors"].first["detail"]
  end

  test "resend magic link with blank email" do
    post api_v1_auth_resend_magic_link_path, params: { email: "" }

    assert_response :unprocessable_entity
    assert_equal I18n.t("contracts.errors.email.blank"), response.parsed_body["errors"].first["detail"]
  end
end