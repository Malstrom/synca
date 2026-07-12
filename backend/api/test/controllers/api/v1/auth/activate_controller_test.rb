# frozen_string_literal: true

require "test_helper"

class Api::V1::Auth::ActivateControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:guest)
    @user.generate_magic_link_token!
    @display_name = "Test User"
  end

  test "activate with valid token and display name" do
    post api_v1_auth_activate_url, params: {
      token: @user.magic_link_token,
      profile: { display_name: @display_name }
    }

    assert_response :success
    assert_equal "active", @user.reload.account_type
    assert_nil @user.magic_link_token
    assert_equal @display_name, @user.profile.display_name
    assert_not_nil response.parsed_body["access_token"]
  end

  test "activate with expired token" do
    @user.update!(magic_link_sent_at: 73.hours.ago)

    post api_v1_auth_activate_url, params: {
      token: @user.magic_link_token,
      profile: { display_name: @display_name }
    }

    assert_response :unprocessable_entity
    assert_equal I18n.t("services.magic_link.token_expired"), response.parsed_body["error"]
  end

  test "activate with already used token" do
    @user.update!(magic_link_token: nil)

    post api_v1_auth_activate_url, params: {
      token: @user.magic_link_token,
      profile: { display_name: @display_name }
    }

    assert_response :unprocessable_entity
    assert_equal I18n.t("services.magic_link.token_already_used"), response.parsed_body["error"]
  end

  test "activate with already active account" do
    @user.update!(account_type: :active)

    post api_v1_auth_activate_url, params: {
      token: @user.magic_link_token,
      profile: { display_name: @display_name }
    }

    assert_response :unprocessable_entity
    assert_equal I18n.t("services.magic_link.account_already_active"), response.parsed_body["error"]
  end
end