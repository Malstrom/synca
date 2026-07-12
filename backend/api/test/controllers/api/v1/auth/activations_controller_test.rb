# frozen_string_literal: true

require "test_helper"

class Api::V1::Auth::ActivationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:guest_user)
    @user.update!(
      magic_link_token: SecureRandom.urlsafe_base64(32),
      magic_link_sent_at: Time.current
    )
  end

  test "should activate guest account with valid token" do
    post api_v1_auth_activate_url,
         params: {
           token: @user.magic_link_token,
           profile: { display_name: "New User" }
         },
         as: :json

    assert_response :success
    assert_equal "active", @user.reload.account_type
    assert_nil @user.magic_link_token
    assert_nil @user.magic_link_sent_at
    assert_not_nil @user.profile
    assert_equal "New User", @user.profile.display_name
    assert_not_nil json_response["access_token"]
    assert_not_nil json_response["refresh_token"]
    assert_equal "Bearer", json_response["token_type"]
    assert_equal "active", json_response["account_type"]
  end

  test "should return 404 for invalid token" do
    post api_v1_auth_activate_url,
         params: {
           token: "invalid_token",
           profile: { display_name: "New User" }
         },
         as: :json

    assert_response :not_found
    assert_equal I18n.t("errors.token_not_found"), json_response["error"]
  end

  test "should return 422 for already active account" do
    @user.update!(account_type: :active)

    post api_v1_auth_activate_url,
         params: {
           token: @user.magic_link_token,
           profile: { display_name: "New User" }
         },
         as: :json

    assert_response :unprocessable_entity
    assert_equal I18n.t("errors.account_already_active"), json_response["error"]
  end

  test "should return 422 for expired token" do
    @user.update!(magic_link_sent_at: 73.hours.ago)

    post api_v1_auth_activate_url,
         params: {
           token: @user.magic_link_token,
           profile: { display_name: "New User" }
         },
         as: :json

    assert_response :unprocessable_entity
    assert_equal I18n.t("errors.token_expired"), json_response["error"]
  end

  test "should return 422 for already used token" do
    @user.update!(magic_link_token: nil)

    post api_v1_auth_activate_url,
         params: {
           token: "used_token",
           profile: { display_name: "New User" }
         },
         as: :json

    assert_response :unprocessable_entity
    assert_equal I18n.t("errors.token_already_used"), json_response["error"]
  end
end
