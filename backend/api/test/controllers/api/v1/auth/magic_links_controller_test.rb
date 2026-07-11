# frozen_string_literal: true

require "test_helper"

class Api::V1::Auth::MagicLinksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:guest_user)
  end

  test "resend magic link to existing user" do
    post api_v1_auth_resend_magic_link_path, params: { email: @user.email }

    assert_response :success
    assert_equal I18n.t("controllers.magic_links.success"), response.parsed_body["message"]
  end

  test "resend magic link to non-existing user" do
    post api_v1_auth_resend_magic_link_path, params: { email: "nonexistent@example.com" }

    assert_response :success
    assert_equal I18n.t("controllers.magic_links.success"), response.parsed_body["message"]
  end

  test "resend magic link too soon" do
    @user.update!(magic_link_sent_at: 4.minutes.ago)

    post api_v1_auth_resend_magic_link_path, params: { email: @user.email }

    assert_response :too_many_requests
    assert_equal I18n.t("services.resend_magic_link.rate_limit"), response.parsed_body["error"]
  end

  test "resend magic link with invalid email" do
    post api_v1_auth_resend_magic_link_path, params: { email: "" }

    assert_response :unprocessable_entity
    assert_equal I18n.t("contracts.errors.email.filled"), response.parsed_body["error"]["email"]
  end
end