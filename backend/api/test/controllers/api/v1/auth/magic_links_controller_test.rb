# frozen_string_literal: true

require "test_helper"

class Api::V1::Auth::MagicLinksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:guest_user)
  end

  test "resend magic link to existing user" do
    post api_v1_auth_resend_magic_link_url, params: { email: @user.email }

    assert_response :success
    assert_equal I18n.t("controllers.magic_links.sent"), JSON.parse(response.body)["message"]

    @user.reload
    assert_not_nil @user.magic_link_token
    assert_not_nil @user.magic_link_sent_at
  end

  test "resend magic link to non-existing user" do
    post api_v1_auth_resend_magic_link_url, params: { email: "nonexistent@example.com" }

    assert_response :success
    assert_equal I18n.t("controllers.magic_links.sent"), JSON.parse(response.body)["message"]
  end

  test "resend magic link too soon" do
    @user.update!(magic_link_sent_at: Time.current)

    post api_v1_auth_resend_magic_link_url, params: { email: @user.email }

    assert_response :too_many_requests
    assert_equal I18n.t("controllers.magic_links.rate_limited"), JSON.parse(response.body)["error"]
  end

  test "resend magic link to active user" do
    @user.update!(account_type: :active)

    post api_v1_auth_resend_magic_link_url, params: { email: @user.email }

    assert_response :success
    assert_equal I18n.t("controllers.magic_links.sent"), JSON.parse(response.body)["message"]
  end
end