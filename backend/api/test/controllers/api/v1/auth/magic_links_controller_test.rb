# frozen_string_literal: true

require "test_helper"

class Api::V1::Auth::MagicLinksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @guest_user = users(:guest_user)
    @active_user = users(:active_user)
    @unregistered_email = "unregistered@example.com"
  end

  test "resend magic link to guest user" do
    post api_v1_auth_resend_magic_link_url, params: { email: @guest_user.email }

    assert_response :success
    assert_equal I18n.t("services.magic_link.resend_success"), JSON.parse(response.body)["message"]

    @guest_user.reload
    assert_not_nil @guest_user.magic_link_token
    assert_not_nil @guest_user.magic_link_sent_at
  end

  test "resend magic link to active user" do
    post api_v1_auth_resend_magic_link_url, params: { email: @active_user.email }

    assert_response :success
    assert_equal I18n.t("services.magic_link.resend_success"), JSON.parse(response.body)["message"]

    @active_user.reload
    assert_nil @active_user.magic_link_token
    assert_nil @active_user.magic_link_sent_at
  end

  test "resend magic link to unregistered email" do
    post api_v1_auth_resend_magic_link_url, params: { email: @unregistered_email }

    assert_response :success
    assert_equal I18n.t("services.magic_link.resend_success"), JSON.parse(response.body)["message"]
  end

  test "rate limited resend" do
    # First request
    post api_v1_auth_resend_magic_link_url, params: { email: @guest_user.email }
    assert_response :success

    # Second request within 5 minutes
    post api_v1_auth_resend_magic_link_url, params: { email: @guest_user.email }
    assert_response :too_many_requests
    assert_equal I18n.t("services.magic_link.rate_limited"), JSON.parse(response.body)["error"]
  end
end