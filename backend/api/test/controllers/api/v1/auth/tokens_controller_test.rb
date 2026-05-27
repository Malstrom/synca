# frozen_string_literal: true

require "test_helper"

class Api::V1::Auth::TokensControllerTest < ApiTestCase
  setup do
    @user = users(:alice)
  end

  test "refresh with valid refresh token returns new access token" do
    token = JwtService.refresh_token(@user)
    post_json "/api/v1/auth/refresh",
      params: { auth: { refresh_token: token } }

    assert_response :ok
    assert json[:access_token].present?
    refute json.key?(:refresh_token), "should not issue a new refresh token"
  end

  test "refresh with access token (wrong type) returns 401" do
    token = JwtService.access_token(@user)
    post_json "/api/v1/auth/refresh",
      params: { auth: { refresh_token: token } }

    assert_response :unauthorized
    assert_equal "invalid_token", json.dig(:error, :code)
  end

  test "refresh with garbage token returns 401" do
    post_json "/api/v1/auth/refresh",
      params: { auth: { refresh_token: "not.a.real.token" } }

    assert_response :unauthorized
    assert_equal "invalid_token", json.dig(:error, :code)
  end

  test "refresh with missing token returns 401" do
    post_json "/api/v1/auth/refresh", params: {}

    assert_response :unauthorized
  end

  test "refresh for nonexistent user returns 401" do
    token = JwtService.refresh_token(@user)
    @user.destroy
    post_json "/api/v1/auth/refresh",
      params: { auth: { refresh_token: token } }

    assert_response :unauthorized
  end
end
