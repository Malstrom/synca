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
    assert_equal I18n.t("controllers.auth.magic_links.sent"), response.parsed_body["message"]
  end

  test "resend magic link to active user" do
    post api_v1_auth_resend_magic_link_url, params: { email: @active_user.email }

    assert_response :success
    assert_equal I18n.t("controllers.auth.magic_links.sent"), response.parsed_body["message"]
  end

  test "resend magic link to unregistered email" do
    post api_v1_auth_resend_magic_link_url, params: { email: @unregistered_email }

    assert_response :success
    assert_equal I18n.t("controllers.auth.magic_links.sent"), response.parsed_body["message"]
  end

  test "rate limited resend" do
    @guest_user.update!(magic_link_sent_at: 2.minutes.ago)

    post api_v1_auth_resend_magic_link_url, params: { email: @guest_user.email }

    assert_response :success
    assert_equal I18n.t("controllers.auth.magic_links.sent"), response.parsed_body["message"]
  end
end