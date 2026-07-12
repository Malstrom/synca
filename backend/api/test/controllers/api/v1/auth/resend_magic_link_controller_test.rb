# frozen_string_literal: true

require "test_helper"

class Api::V1::Auth::ResendMagicLinkControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:guest_user)
    @valid_params = { email: @user.email }
  end

  test "should resend magic link with valid email" do
    post api_v1_auth_resend_magic_link_path, params: @valid_params, as: :json
    assert_response :success
    assert_equal I18n.t("resend_magic_link.success"), response.parsed_body["message"]
  end

  test "should return success even with non-existent email" do
    post api_v1_auth_resend_magic_link_path, params: { email: "nonexistent@example.com" }, as: :json
    assert_response :success
    assert_equal I18n.t("resend_magic_link.success"), response.parsed_body["message"]
  end

  test "should return 429 with rate limited request" do
    @user.update!(magic_link_sent_at: 4.minutes.ago)
    post api_v1_auth_resend_magic_link_path, params: @valid_params, as: :json
    assert_response :too_many_requests
  end

  test "should return 422 with invalid email" do
    post api_v1_auth_resend_magic_link_path, params: { email: "invalid_email" }, as: :json
    assert_response :unprocessable_entity
    assert_equal I18n.t("contracts.errors.email.invalid"), response.parsed_body["error"]["errors"]["email"].first
  end
end