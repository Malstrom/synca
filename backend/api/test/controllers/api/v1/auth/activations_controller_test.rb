# frozen_string_literal: true

require "test_helper"

class Api::V1::Auth::ActivationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:guest_user)
    @user.generate_magic_link_token
    @valid_token = @user.magic_link_token
    @expired_token = "expired_token"
    @used_token = "used_token"
    @active_user = users(:active_user)
    @active_user.generate_magic_link_token
    @active_token = @active_user.magic_link_token
  end

  test "activate with valid token and display_name" do
    post api_v1_auth_activate_url, params: {
      token: @valid_token,
      profile: { display_name: "New Display Name" }
    }

    assert_response :success
    response_data = response.parsed_body
    assert_not_nil response_data["access_token"]
    assert_equal "Bearer", response_data["token_type"]
    assert_equal "active", response_data["account_type"]

    @user.reload
    assert_equal "active", @user.account_type
    assert_equal "New Display Name", @user.profile.display_name
  end

  test "activate with expired token" do
    User.any_instance.stubs(:magic_link_expired?).returns(true)

    post api_v1_auth_activate_url, params: {
      token: @expired_token,
      profile: { display_name: "New Display Name" }
    }

    assert_response :unprocessable_entity
    assert_equal I18n.t("controllers.auth.activations.token_expired"), response.parsed_body["error"]
  end

  test "activate with already used token" do
    User.any_instance.stubs(:magic_link_token).returns(nil)

    post api_v1_auth_activate_url, params: {
      token: @used_token,
      profile: { display_name: "New Display Name" }
    }

    assert_response :unprocessable_entity
    assert_equal I18n.t("controllers.auth.activations.token_expired"), response.parsed_body["error"]
  end

  test "activate with already active account" do
    post api_v1_auth_activate_url, params: {
      token: @active_token,
      profile: { display_name: "New Display Name" }
    }

    assert_response :unprocessable_entity
    assert_equal I18n.t("controllers.auth.activations.account_already_active"), response.parsed_body["error"]
  end

  test "activate with invalid token" do
    post api_v1_auth_activate_url, params: {
      token: "invalid_token",
      profile: { display_name: "New Display Name" }
    }

    assert_response :not_found
    assert_equal I18n.t("controllers.auth.activations.not_found"), response.parsed_body["error"]
  end
end
