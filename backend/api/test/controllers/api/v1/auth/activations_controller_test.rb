# frozen_string_literal: true

require "test_helper"

class Api::V1::Auth::ActivationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:guest_user)
    @token = MagicLinkService.call(user: @user).value!
  end

  test "activate with valid token and display_name" do
    post api_v1_auth_activate_path, params: {
      token: @token,
      profile: { display_name: "Luca" }
    }

    assert_response :success
    assert_equal "active", @user.reload.account_type
    assert_nil @user.magic_link_token
    assert_equal "Luca", @user.profile.display_name
    assert_not_nil response.parsed_body["access_token"]
    assert_not_nil response.parsed_body["refresh_token"]
  end

  test "activate with expired token" do
    @user.update!(magic_link_sent_at: 73.hours.ago)

    post api_v1_auth_activate_path, params: {
      token: @token,
      profile: { display_name: "Luca" }
    }

    assert_response :unprocessable_entity
    assert_equal I18n.t("controllers.activations.token_expired"), response.parsed_body["error"]
  end

  test "activate with already used token" do
    @user.update!(magic_link_token: nil)

    post api_v1_auth_activate_path, params: {
      token: @token,
      profile: { display_name: "Luca" }
    }

    assert_response :unprocessable_entity
    assert_equal I18n.t("controllers.activations.token_already_used"), response.parsed_body["error"]
  end

  test "activate with already active account" do
    @user.update!(account_type: :active)

    post api_v1_auth_activate_path, params: {
      token: @token,
      profile: { display_name: "Luca" }
    }

    assert_response :unprocessable_entity
    assert_equal I18n.t("controllers.activations.account_already_active"), response.parsed_body["error"]
  end

  test "activate with invalid token" do
    post api_v1_auth_activate_path, params: {
      token: "invalid_token",
      profile: { display_name: "Luca" }
    }

    assert_response :not_found
    assert_equal I18n.t("controllers.activations.not_found"), response.parsed_body["error"]
  end

  test "activate with missing display_name" do
    post api_v1_auth_activate_path, params: {
      token: @token,
      profile: { display_name: "" }
    }

    assert_response :unprocessable_entity
    assert_equal I18n.t("contracts.errors.profile.display_name.filled"), response.parsed_body["error"]["profile.display_name"]
  end
end
