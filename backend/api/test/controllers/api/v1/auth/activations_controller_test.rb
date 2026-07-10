# frozen_string_literal: true

require "test_helper"

class Api::V1::Auth::ActivationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:guest_user)
    @token = MagicLinkService.call(user: @user).value!
  end

  test "activate guest account with valid token" do
    post api_v1_auth_activate_path, params: {
      token: @token,
      profile: { display_name: "Test User" }
    }

    assert_response :success
    assert_equal "active", @user.reload.account_type
    assert_equal "Test User", @user.profile.reload.display_name
    assert_not_nil json_response["activation"]["access_token"]
    assert_not_nil json_response["activation"]["refresh_token"]
  end

  test "reject already used token" do
    @user.update!(magic_link_token: nil)

    post api_v1_auth_activate_path, params: {
      token: @token,
      profile: { display_name: "Test User" }
    }

    assert_response :unprocessable_entity
    assert_equal "token_already_used", json_response["code"]
  end

  test "reject expired token" do
    expired_token = JwtService.encode(
      { user_id: @user.id, purpose: "activation" },
      exp: 1.second
    )
    travel_to 2.seconds.from_now do
      post api_v1_auth_activate_path, params: {
        token: expired_token,
        profile: { display_name: "Test User" }
      }
    end

    assert_response :unprocessable_entity
    assert_equal "token_expired", json_response["code"]
  end

  test "reject already active account" do
    @user.update!(account_type: "active")

    post api_v1_auth_activate_path, params: {
      token: @token,
      profile: { display_name: "Test User" }
    }

    assert_response :unprocessable_entity
    assert_equal "account_already_active", json_response["code"]
  end
end
