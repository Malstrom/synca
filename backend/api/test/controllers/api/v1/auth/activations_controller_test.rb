# frozen_string_literal: true

require "test_helper"

class Api::V1::Auth::ActivationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:guest_user)
    @user.generate_magic_link_token!
    @valid_token = @user.magic_link_token
    @expired_token = "expired_token"
    @used_token = "used_token"
    @active_user = users(:active_user)
    @active_user.generate_magic_link_token!
  end

  test "activate with valid token and display name" do
    post api_v1_auth_activate_url, params: {
      token: @valid_token,
      profile: { display_name: "New Display Name" }
    }

    assert_response :success
    response_data = JSON.parse(response.body)
    assert_equal "Bearer", response_data["token_type"]
    assert_equal "active", response_data["account_type"]
    assert_not_nil response_data["access_token"]
    assert_not_nil response_data["refresh_token"]

    @user.reload
    assert_nil @user.magic_link_token
    assert_equal "New Display Name", @user.profile.display_name
  end

  test "activate with expired token" do
    post api_v1_auth_activate_url, params: {
      token: @expired_token,
      profile: { display_name: "New Display Name" }
    }

    assert_response :unprocessable_entity
    assert_equal I18n.t("services.magic_link.token_expired"), JSON.parse(response.body)["error"]
  end

  test "activate with already active account" do
    post api_v1_auth_activate_url, params: {
      token: @active_user.magic_link_token,
      profile: { display_name: "New Display Name" }
    }

    assert_response :unprocessable_entity
    assert_equal I18n.t("services.magic_link.account_already_active"), JSON.parse(response.body)["error"]
  end

  test "activate with invalid token" do
    post api_v1_auth_activate_url, params: {
      token: "invalid_token",
      profile: { display_name: "New Display Name" }
    }

    assert_response :not_found
    assert_equal I18n.t("services.magic_link.token_not_found"), JSON.parse(response.body)["error"]
  end
end
