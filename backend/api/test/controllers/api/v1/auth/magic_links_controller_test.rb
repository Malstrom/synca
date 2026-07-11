# frozen_string_literal: true

require "test_helper"

class Api::V1::Auth::MagicLinksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:guest_user)
  end

  test "resend magic link" do
    post api_v1_auth_resend_magic_link_path, params: { email: @user.email }

    assert_response :success
    assert_equal I18n.t("controllers.magic_links.success"), response.parsed_body["message"]
  end

  test "resend too soon" do
    @user.update!(magic_link_sent_at: Time.current)

    post api_v1_auth_resend_magic_link_path, params: { email: @user.email }

    assert_response :too_many_requests
    assert_equal I18n.t("services.resend_magic_link.rate_limit"), response.parsed_body["error"]
  end

  test "non-existent email" do
    post api_v1_auth_resend_magic_link_path, params: { email: "nonexistent@example.com" }

    assert_response :success
    assert_equal I18n.t("controllers.magic_links.success"), response.parsed_body["message"]
  end
end
