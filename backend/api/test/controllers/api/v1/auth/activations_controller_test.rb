# frozen_string_literal: true

require "test_helper"

class Api::V1::Auth::ActivationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:guest_user)
    @user.generate_magic_link_token!
    @display_name = "New Display Name"
  end

  test "activate with valid token and display_name" do
    post api_v1_auth_activate_url, params: {
      token: @user.magic_link_token,
      profile: { display_name: @display_name }
    }

    assert_response :success
    response_data = JSON.parse(response.body)

    assert_not_nil response_data["access_token"]
    assert_not_nil response_data["refresh_token"]
    assert_equal "Bearer", response_data["token_type"]
    assert_equal "active", response_data["account_type"]

    @user.reload
    assert_equal "active", @user.account_type
    assert_nil @user.magic_link_token
    assert_nil @user.magic_link_sent_at
    assert_equal @display_name, @user.profile.display_name
  end

  test "activate with expired token" do
    @user.update!(magic_link_sent_at: 73.hours.ago)

    post api_v1_auth_activate_url, params: {
      token: @user.magic_link_token,
      profile: { display_name: @display_name }
    }

    assert_response :unprocessable_entity
    assert_equal I18n.t("controllers.auth.activations.token_expired"), JSON.parse(response.body)["error"]
  end

  test "activate with already active account" do
    @user.update!(account_type: :active)

    post api_v1_auth_activate_url, params: {
      token: @user.magic_link_token,
      profile: { display_name: @display_name }
    }

    assert_response :unprocessable_entity
    assert_equal I18n.t("controllers.auth.activations.account_already_active"), JSON.parse(response.body)["error"]
  end

  test "activate with invalid token" do
    post api_v1_auth_activate_url, params: {
      token: "invalid_token",
      profile: { display_name: @display_name }
    }

    assert_response :not_found
    assert_equal I18n.t("controllers.auth.activations.token_not_found"), JSON.parse(response.body)["error"]
  end
end
