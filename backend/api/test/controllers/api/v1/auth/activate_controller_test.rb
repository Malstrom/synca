# frozen_string_literal: true

require "test_helper"

class Api::V1::Auth::ActivateControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:guest_user)
    @user.generate_magic_link_token
    @valid_params = {
      token: @user.magic_link_token,
      profile: { display_name: "New Display Name" }
    }
  end

  test "should activate user with valid token and display name" do
    post api_v1_auth_activate_url, params: @valid_params, as: :json
    assert_response :success

    @user.reload
    assert_equal "active", @user.account_type
    assert_equal "New Display Name", @user.profile.display_name
    assert_nil @user.magic_link_token
  end

  test "should return 404 with invalid token" do
    post api_v1_auth_activate_url, params: { token: "invalid_token", profile: { display_name: "Test" } }, as: :json
    assert_response :not_found
  end

  test "should return 422 with expired token" do
    @user.update!(magic_link_sent_at: 73.hours.ago)
    post api_v1_auth_activate_url, params: @valid_params, as: :json
    assert_response :unprocessable_entity
    assert_equal "token_expired", JSON.parse(response.body)["error"]["code"]
  end

  test "should return 422 with already used token" do
    @user.update!(magic_link_token: nil)
    post api_v1_auth_activate_url, params: @valid_params, as: :json
    assert_response :unprocessable_entity
    assert_equal "token_already_used", JSON.parse(response.body)["error"]["code"]
  end

  test "should return 422 with already active account" do
    @user.update!(account_type: :active)
    post api_v1_auth_activate_url, params: @valid_params, as: :json
    assert_response :unprocessable_entity
    assert_equal "account_already_active", JSON.parse(response.body)["error"]["code"]
  end

  test "should return 422 with invalid params" do
    post api_v1_auth_activate_url, params: { token: "", profile: { display_name: "" } }, as: :json
    assert_response :unprocessable_entity
  end
end
