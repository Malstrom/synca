# frozen_string_literal: true

require "test_helper"

class Api::V1::Auth::ActivationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:guest_user)
    @user.update!(
      magic_link_token: "valid_token",
      magic_link_sent_at: Time.current
    )
  end

  test "activate with valid token and display_name" do
    post api_v1_auth_activate_path, params: {
      token: "valid_token",
      profile: { display_name: "New Display Name" }
    }

    assert_response :success
    response_data = JSON.parse(response.body)

    assert_equal "Bearer", response_data["token_type"]
    assert_equal "active", response_data["account_type"]
    assert_not_nil response_data["access_token"]
    assert_not_nil response_data["refresh_token"]

    @user.reload
    assert_equal "New Display Name", @user.profile.display_name
    assert_nil @user.magic_link_token
  end

  test "activate with expired token" do
    @user.update!(magic_link_sent_at: MagicLinkService::TOKEN_TTL.ago - 1.hour)

    post api_v1_auth_activate_path, params: {
      token: "valid_token",
      profile: { display_name: "New Display Name" }
    }

    assert_response :unprocessable_entity
    assert_equal I18n.t("errors.token_expired"), JSON.parse(response.body)["message"]
  end

  test "activate with already used token" do
    @user.update!(account_type: :active)

    post api_v1_auth_activate_path, params: {
      token: "valid_token",
      profile: { display_name: "New Display Name" }
    }

    assert_response :unprocessable_entity
    assert_equal I18n.t("errors.token_already_used"), JSON.parse(response.body)["message"]
  end

  test "activate with invalid token" do
    post api_v1_auth_activate_path, params: {
      token: "invalid_token",
      profile: { display_name: "New Display Name" }
    }

    assert_response :not_found
    assert_equal I18n.t("errors.token_not_found"), JSON.parse(response.body)["message"]
  end

  test "activate with already active account" do
    @user.update!(account_type: :active)

    post api_v1_auth_activate_path, params: {
      token: "valid_token",
      profile: { display_name: "New Display Name" }
    }

    assert_response :unprocessable_entity
    assert_equal I18n.t("errors.account_already_active"), JSON.parse(response.body)["message"]
  end
end