# frozen_string_literal: true

require "test_helper"

class Api::V1::Auth::MagicLinksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:guest_user)
  end

  test "resend magic link for guest user" do
    post api_v1_auth_resend_magic_link_path, params: { email: @user.email }

    assert_response :success
    assert_equal I18n.t('magic_link.resent'), json_response["message"]
  end

  test "rate limit resend attempts" do
    @user.update!(magic_link_sent_at: 2.minutes.ago)

    post api_v1_auth_resend_magic_link_path, params: { email: @user.email }

    assert_response :too_many_requests
    assert_equal "rate_limited", json_response["code"]
  end

  test "always return success for non-existent email" do
    post api_v1_auth_resend_magic_link_path, params: { email: "nonexistent@example.com" }

    assert_response :success
    assert_equal I18n.t('magic_link.resent'), json_response["message"]
  end
end