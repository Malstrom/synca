# frozen_string_literal: true

require "test_helper"

class Api::V1::Auth::ResendMagicLinkControllerTest < ActionDispatch::IntegrationTest
  setup do
    @guest_user = users(:guest_user)
    @active_user = users(:active_user)
  end

  test "resend magic link to guest user" do
    post api_v1_auth_resend_magic_link_path, params: { email: @guest_user.email }

    assert_response :success
    assert_equal I18n.t("resend_magic_link.success"), JSON.parse(response.body)["message"]

    @guest_user.reload
    assert_not_nil @guest_user.magic_link_token
    assert_not_nil @guest_user.magic_link_sent_at
  end

  test "resend magic link to active user" do
    post api_v1_auth_resend_magic_link_path, params: { email: @active_user.email }

    assert_response :success
    assert_equal I18n.t("resend_magic_link.success"), JSON.parse(response.body)["message"]

    @active_user.reload
    assert_nil @active_user.magic_link_token
  end

  test "resend magic link to non-existent email" do
    post api_v1_auth_resend_magic_link_path, params: { email: "nonexistent@example.com" }

    assert_response :success
    assert_equal I18n.t("resend_magic_link.success"), JSON.parse(response.body)["message"]
  end

  test "rate limited resend" do
    @guest_user.update!(magic_link_sent_at: Time.current)

    post api_v1_auth_resend_magic_link_path, params: { email: @guest_user.email }

    assert_response :too_many_requests
    assert_equal I18n.t("resend_magic_link.rate_limited"), JSON.parse(response.body)["message"]
  end
end