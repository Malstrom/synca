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

  test "activate with valid token" do
    post api_v1_auth_activate_path, params: {
      token: "valid_token",
      profile: { display_name: "New Display Name" }
    }

    assert_response :success
    assert_equal "active", @user.reload.account_type
    assert_nil @user.magic_link_token
    assert_nil @user.magic_link_sent_at
    assert_equal "New Display Name", @user.profile.display_name
    assert_not_nil response.parsed_body["access_token"]
    assert_not_nil response.parsed_body["refresh_token"]
  end

  test "activate with invalid token" do
    post api_v1_auth_activate_path, params: {
      token: "invalid_token",
      profile: { display_name: "New Display Name" }
    }

    assert_response :not_found
  end

  test "activate with expired token" do
    @user.update!(magic_link_sent_at: 73.hours.ago)

    post api_v1_auth_activate_path, params: {
      token: "valid_token",
      profile: { display_name: "New Display Name" }
    }

    assert_response :unprocessable_entity
    assert_equal "Token expired", response.parsed_body["error"]
  end

  test "activate already active account" do
    @user.update!(account_type: :active)

    post api_v1_auth_activate_path, params: {
      token: "valid_token",
      profile: { display_name: "New Display Name" }
    }

    assert_response :unprocessable_entity
    assert_equal "Account already active", response.parsed_body["error"]
  end

  test "activate with already used token" do
    @user.update!(magic_link_token: nil)

    post api_v1_auth_activate_path, params: {
      token: "valid_token",
      profile: { display_name: "New Display Name" }
    }

    assert_response :unprocessable_entity
    assert_equal "Token already used", response.parsed_body["error"]
  end
end
