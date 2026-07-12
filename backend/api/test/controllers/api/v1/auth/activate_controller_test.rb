# frozen_string_literal: true

require "test_helper"

class Api::V1::Auth::ActivateControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:guest_user)
    @user.update!(
      magic_link_token: "valid_token",
      magic_link_sent_at: Time.current,
      account_type: :guest
    )
  end

  test "activate with valid token and display_name" do
    post api_v1_auth_activate_path, params: {
      token: "valid_token",
      profile: { display_name: "New Display Name" }
    }

    assert_response :success
    response_data = response.parsed_body["data"]
    assert_not_nil response_data["access_token"]
    assert_not_nil response_data["refresh_token"]
    assert_equal "Bearer", response_data["token_type"]
    assert_equal "active", response_data["account_type"]

    @user.reload
    assert_equal "active", @user.account_type
    assert_equal "New Display Name", @user.profile.display_name
    assert_nil @user.magic_link_token
  end

  test "activate with expired token" do
    @user.update!(magic_link_sent_at: 73.hours.ago)

    post api_v1_auth_activate_path, params: {
      token: "valid_token",
      profile: { display_name: "New Display Name" }
    }

    assert_response :unprocessable_entity
    assert_equal I18n.t("errors.token_expired"), response.parsed_body["error"]
  end

  test "activate with already used token" do
    @user.update!(magic_link_token: nil)

    post api_v1_auth_activate_path, params: {
      token: "valid_token",
      profile: { display_name: "New Display Name" }
    }

    assert_response :unprocessable_entity
    assert_equal I18n.t("errors.token_already_used"), response.parsed_body["error"]
  end

  test "activate already active account" do
    @user.update!(account_type: :active)

    post api_v1_auth_activate_path, params: {
      token: "valid_token",
      profile: { display_name: "New Display Name" }
    }

    assert_response :unprocessable_entity
    assert_equal I18n.t("errors.account_already_active"), response.parsed_body["error"]
  end

  test "activate with invalid token" do
    post api_v1_auth_activate_path, params: {
      token: "invalid_token",
      profile: { display_name: "New Display Name" }
    }

    assert_response :not_found
    assert_equal I18n.t("errors.not_found"), response.parsed_body["error"]
  end

  test "activate with missing display_name" do
    post api_v1_auth_activate_path, params: {
      token: "valid_token",
      profile: { display_name: "" }
    }

    assert_response :unprocessable_entity
    assert_equal I18n.t("contracts.errors.display_name.blank"), response.parsed_body["errors"].first["detail"]
  end
end